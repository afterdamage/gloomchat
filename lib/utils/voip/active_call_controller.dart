import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc_impl;
import 'package:matrix/matrix.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/utils/voip/call_sounds.dart';
import 'package:afterdamage/utils/voip/callkit_service.dart';

/// Single source of truth for one 1:1 call.
///
/// Exactly one controller exists per [CallSession]. It owns the SDK stream
/// subscriptions, the duration timer, ring/ringback sounds, wakelock and the
/// native CallKit sync — every call widget (full-screen, sidebar panel,
/// incoming card) is a dumb view on this controller. This replaces the old
/// architecture where each of three widgets subscribed to the call and played
/// its own sounds, causing double dial-tones and inconsistent state.
class ActiveCallController extends ChangeNotifier {
  final CallSession call;
  final Client client;

  String get callId => call.callId;

  CallState _state;
  DateTime? _connectedAt;
  Duration _duration = Duration.zero;
  Timer? _durationTimer;
  bool _speakerOn = false;
  bool _disposed = false;

  StreamSubscription<CallState>? _stateSub;
  StreamSubscription<CallStateChange>? _eventSub;

  ActiveCallController({required this.call, required this.client})
      : _state = call.state {
    _stateSub = call.onCallStateChanged.stream.listen(_onStateChanged);
    _eventSub = call.onCallEventChanged.stream.listen(_onCallEvent);

    if (call.type == CallType.kVideo) {
      WakelockPlus.enable().ignore();
    }
    if (_state == CallState.kConnected) {
      _onConnected(silent: true);
    }
    _syncSounds();
  }

  // ── Derived state ─────────────────────────────────────────────────────────

  CallState get state => _state;
  Duration get duration => _duration;
  bool get speakerOn => _speakerOn;

  bool get isOutgoing => call.isOutgoing;
  bool get isVideoCall => call.type == CallType.kVideo;
  bool get voiceOnly => call.type == CallType.kVoice;
  bool get isConnected => _state == CallState.kConnected;
  bool get isEnded =>
      _state == CallState.kEnded || _state == CallState.kEnding;
  bool get isIncomingRinging =>
      !call.isOutgoing &&
      !isConnected &&
      !isEnded &&
      (_state == CallState.kRinging || _state == CallState.kFledgling);
  bool get isMicrophoneMuted => call.isMicrophoneMuted;
  bool get isLocalVideoMuted => call.isLocalVideoMuted;
  bool get isScreensharingEnabled => call.screensharingEnabled;
  bool get isOnHold => call.remoteOnHold || call.localHold;

  WrappedMediaStream? get remoteStream =>
      call.remoteScreenSharingStream ?? call.remoteUserMediaStream;
  WrappedMediaStream? get localStream => call.localUserMediaStream;
  bool get hasRemoteVideo {
    final stream = remoteStream;
    return stream != null && !stream.videoMuted;
  }

  /// Display name of the remote party (the other user in a DM, otherwise the
  /// room name).
  String get displayName {
    if (call.room.isDirectChat) {
      final userId = call.room.directChatMatrixID ?? '';
      final user = call.room.unsafeGetUserFromMemoryOrFallback(userId);
      return user.displayName ?? user.id;
    }
    return call.room.getLocalizedDisplayname();
  }

  Uri? get avatarUrl {
    if (call.room.isDirectChat) {
      final userId = call.room.directChatMatrixID ?? '';
      return call.room.unsafeGetUserFromMemoryOrFallback(userId).avatarUrl;
    }
    return call.room
        .getState(EventTypes.RoomAvatar)
        ?.content
        .tryGet<Uri>('url');
  }

  String get statusLabel {
    if (isEnded) return 'Call ended';
    if (isConnected) return formatDuration(_duration);
    if (isIncomingRinging) {
      return isVideoCall ? 'Incoming video call' : 'Incoming voice call';
    }
    switch (_state) {
      case CallState.kInviteSent:
      case CallState.kRinging:
        return 'Ringing…';
      case CallState.kCreateOffer:
      case CallState.kWaitLocalMedia:
        return 'Calling…';
      case CallState.kCreateAnswer:
      case CallState.kConnecting:
        return 'Connecting…';
      default:
        return 'Setting up…';
    }
  }

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ── SDK event handling ────────────────────────────────────────────────────

  void _onStateChanged(CallState state) {
    if (_disposed) return;
    _state = state;
    if (state == CallState.kConnected && _connectedAt == null) {
      _onConnected();
    }
    if (isEnded) {
      _onEnded();
    }
    _syncSounds();
    notifyListeners();
  }

  void _onCallEvent(CallStateChange event) {
    if (_disposed) return;
    if (event == CallStateChange.kFeedsChanged) {
      call.tryRemoveStopedStreams();
    }
    notifyListeners();
  }

  void _onConnected({bool silent = false}) {
    _connectedAt = DateTime.now();
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      _duration = DateTime.now().difference(_connectedAt!);
      notifyListeners();
    });
    if (!silent && PlatformInfos.isMobile) {
      HapticFeedback.mediumImpact();
    }
    // Start the native call timer on iOS/Android.
    CallkitService.instance.setConnected(call.callId);
  }

  void _onEnded() {
    _durationTimer?.cancel();
    _durationTimer = null;
    if (PlatformInfos.isMobile) {
      HapticFeedback.heavyImpact();
    }
    if (call.type == CallType.kVideo) {
      WakelockPlus.disable().ignore();
    }
  }

  /// Sounds are driven exclusively from here (plus the SDK's
  /// playRingtone/stopRingtone delegate calls, which hit the same idempotent
  /// [CallSounds] instance).
  void _syncSounds() {
    if (isConnected || isEnded) {
      CallSounds.instance.stop();
      return;
    }
    if (isOutgoing) {
      CallSounds.instance.startRingback();
      return;
    }
    if (isIncomingRinging) {
      // Incoming ring: on iOS/Android CallKit plays the system ringtone, so
      // ringing in-app as well would double up.
      if (!CallkitService.instance.isSupported) {
        CallSounds.instance.startRingtone();
      }
    } else {
      // Answered locally, now connecting — must not keep (or resume) ringing.
      CallSounds.instance.stop();
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// On web (and desktop) an incoming call may be holding a silent placeholder
  /// stream because getUserMedia was blocked before a user gesture (see
  /// WebMediaDevicesWrapper). Answering — a real user gesture — is the moment
  /// to swap in the real microphone/camera. Without this, the call connects
  /// but the other side hears nothing.
  Future<void> _ensureRealMedia() async {
    if (PlatformInfos.isMobile) return;
    final localStream = call.localUserMediaStream;
    final audioTracks = localStream?.stream?.getAudioTracks() ?? [];
    if (audioTracks.isNotEmpty) return;

    Logs().i('[VOIP] Local stream has no audio — requesting real media');
    try {
      final realStream =
          await webrtc_impl.navigator.mediaDevices.getUserMedia(
        <String, dynamic>{
          'audio': true,
          'video': call.type == CallType.kVideo,
        },
      );
      if (realStream.getAudioTracks().isEmpty) {
        Logs().w('[VOIP] getUserMedia returned no audio tracks');
        return;
      }
      if (localStream != null) await call.removeLocalStream(localStream);
      await call.addLocalStream(
        realStream,
        SDPStreamMetadataPurpose.Usermedia,
      );
      Logs().i('[VOIP] Replaced placeholder with real media');
    } catch (e) {
      Logs().e('[VOIP] Failed to get real media: $e');
    }
  }

  Future<void> answer() async {
    await _ensureRealMedia();
    try {
      await call.answer();
    } catch (e) {
      Logs().w('[VOIP] answer failed: $e');
    }
    notifyListeners();
  }

  Future<void> reject() async {
    try {
      await call.reject();
    } catch (e) {
      Logs().w('[VOIP] reject failed: $e');
    }
    notifyListeners();
  }

  /// Reject when still ringing (incoming), hang up otherwise.
  Future<void> hangUp() async {
    try {
      if (!call.isOutgoing && !isConnected && !isEnded) {
        await call.reject();
      } else {
        await call.hangup(reason: CallErrorCode.userHangup);
      }
    } catch (e) {
      Logs().w('[VOIP] hangup failed: $e');
    }
    notifyListeners();
  }

  Future<void> toggleMicrophone() async {
    await _ensureRealMedia();
    try {
      await call.setMicrophoneMuted(!call.isMicrophoneMuted);
    } catch (e) {
      Logs().w('[VOIP] setMicrophoneMuted failed: $e');
    }
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    try {
      await call.setLocalVideoMuted(!call.isLocalVideoMuted);
    } catch (e) {
      Logs().w('[VOIP] setLocalVideoMuted failed: $e');
    }
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    try {
      await webrtc_impl.Helper.setSpeakerphoneOn(_speakerOn);
    } catch (e) {
      Logs().w('[VOIP] setSpeakerphoneOn failed: $e');
    }
    notifyListeners();
  }

  Future<void> flipCamera() async {
    final tracks = call.localUserMediaStream?.stream?.getVideoTracks() ?? [];
    if (tracks.isEmpty) return;
    try {
      await webrtc_impl.Helper.switchCamera(tracks.first);
    } catch (e) {
      Logs().w('[VOIP] switchCamera failed: $e');
    }
    notifyListeners();
  }

  Future<void> toggleScreenshare() async {
    final enabling = !call.screensharingEnabled;
    if (PlatformInfos.isAndroid) {
      // Android requires a foreground service while capturing the screen.
      try {
        if (enabling) {
          FlutterForegroundTask.init(
            androidNotificationOptions: AndroidNotificationOptions(
              channelId: 'screen_sharing',
              channelName: 'Screen sharing',
            ),
            iosNotificationOptions: const IOSNotificationOptions(),
            foregroundTaskOptions: ForegroundTaskOptions(
              eventAction: ForegroundTaskEventAction.nothing(),
            ),
          );
          await FlutterForegroundTask.startService(
            notificationTitle: 'Screen sharing',
            notificationText: 'You are sharing your screen',
          );
        } else {
          await FlutterForegroundTask.stopService();
        }
      } catch (e) {
        Logs().w('[VOIP] screenshare foreground service failed: $e');
      }
    }
    try {
      await call.setScreensharingEnabled(enabling);
    } catch (e) {
      Logs().w('[VOIP] setScreensharingEnabled failed: $e');
    }
    notifyListeners();
  }

  Future<void> toggleHold() async {
    try {
      await call.setRemoteOnHold(!call.remoteOnHold);
    } catch (e) {
      Logs().w('[VOIP] setRemoteOnHold failed: $e');
    }
    notifyListeners();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    _stateSub?.cancel();
    _eventSub?.cancel();
    _durationTimer?.cancel();
    // Deliberately NOT stopping CallSounds here: sounds stop via _syncSounds
    // when this call connects/ends, and a controller disposed at the end of
    // its post-call grace period must not silence a newer call that is
    // already ringing.
    if (call.type == CallType.kVideo) {
      WakelockPlus.disable().ignore();
    }
    super.dispose();
  }
}
