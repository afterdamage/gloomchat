import 'dart:async';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc_impl;
import 'package:matrix/matrix.dart';
import 'package:webrtc_interface/webrtc_interface.dart' hide Navigator;

import 'package:afterdamage/pages/chat_list/chat_list.dart';
import 'package:afterdamage/pages/dialer/group_call.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/utils/voip/callkit_events.dart' as ck;
import 'package:afterdamage/utils/voip/callkit_service.dart';
import 'package:afterdamage/utils/voip/web_media_fixer.dart';
import '../../utils/voip/user_media_manager.dart';
import '../widgets/matrix.dart';

/// Holds the state of an active 1:1 call for the banner UI.
class ActiveCallState {
  final String callId;
  final CallSession call;
  final Client client;

  const ActiveCallState({
    required this.callId,
    required this.call,
    required this.client,
  });
}

class VoipPlugin with WidgetsBindingObserver implements WebRTCDelegate {
  final MatrixState matrix;
  Client get client => matrix.client;
  VoipPlugin(this.matrix) {
    voip = VoIP(client, this);
    if (!kIsWeb) {
      final wb = WidgetsBinding.instance;
      wb.addObserver(this);
      didChangeAppLifecycleState(wb.lifecycleState);
      if (PlatformInfos.isMobile) {
        _listenCallkitEvents();
      }
    }
  }
  bool background = false;
  bool speakerOn = false;
  late VoIP voip;
  OverlayEntry? overlayEntry; // legacy — kept for API compatibility, not used
  StreamSubscription<ck.CallEvent?>? _callkitEventSub;
  BuildContext get context => matrix.context;

  /// Wrapper that catches getUserMedia permission errors on web so incoming
  /// calls can reach the "Ringing" state without being killed.
  late final WebMediaDevicesWrapper _webMediaDevices =
      WebMediaDevicesWrapper(webrtc_impl.navigator.mediaDevices);

  /// Expose the wrapper so call UI can check if a placeholder was used.
  WebMediaDevicesWrapper? get mediaDevicesWrapper =>
      kIsWeb ? _webMediaDevices : null;

  /// Notifier for the active 1:1 call. Delegates to [MatrixState.activeCallNotifier]
  /// so the overlay is always wired up even before [VoipPlugin] is created.
  ValueNotifier<ActiveCallState?> get activeCallNotifier =>
      matrix.activeCallNotifier;

  /// Whether the floating call panel (video pop-out) is expanded.
  ValueNotifier<bool> get callExpandedNotifier => matrix.callExpandedNotifier;

  void dispose() {
    if (!kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _callkitEventSub?.cancel();
    _callkitEventSub = null;
  }

  /// Listens to native call UI events (Accept / Decline / End) from
  /// flutter_callkit_incoming and forwards them to the active CallSession.
  void _listenCallkitEvents() {
    _callkitEventSub = ck.FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      final body = event.body;
      if (body is! Map) return;
      final callId = body['id'] as String?;
      if (callId == null) return;

      // Find the matching call session by callId.
      final call = voip.calls.values
          .where((c) => c.callId == callId)
          .firstOrNull;
      if (call == null) {
        Logs().w('[VOIP] Callkit event for unknown callId $callId, ignoring');
        return;
      }

      switch (event.event) {
        case ck.Event.actionCallAccept:
          Logs().i('[VOIP] Callkit accept => answering call $callId');
          try {
            await call.answer();
          } catch (e) {
            Logs().w('[VOIP] Callkit answer failed: $e');
          }
          break;
        case ck.Event.actionCallDecline:
          Logs().i('[VOIP] Callkit decline => rejecting call $callId');
          try {
            await call.reject();
          } catch (e) {
            Logs().w('[VOIP] Callkit reject failed: $e');
          }
          break;
        case ck.Event.actionCallEnded:
        case ck.Event.actionCallTimeout:
          Logs().i('[VOIP] Callkit ended/timeout => hanging up call $callId');
          if (!call.callHasEnded) {
            try {
              await call.hangup(reason: CallErrorCode.userHangup);
            } catch (e) {
              Logs().w('[VOIP] Callkit hangup failed: $e');
            }
          }
          break;
        default:
          Logs().i('[VOIP] Ignoring unsupported Callkit event ${event.event}');
          break;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState? state) {
    background =
        (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused);
  }

  void addCallingOverlay(String callId, CallSession call) {
    // Notify the ValueNotifier so AppNavigationShell shows the full-screen
    // CallScreen via its Stack overlay (the reliable in-tree approach).
    // NOTE: we intentionally do NOT use Overlay.of(context) here because
    // `matrix.context` sits ABOVE the Navigator/Overlay in the widget tree
    // (Matrix wraps its child GoRouter), so Overlay.of() returns null and
    // any insert attempt is silently dropped.
    activeCallNotifier.value = ActiveCallState(
      callId: callId,
      call: call,
      client: client,
    );
  }

  @override
  MediaDevices get mediaDevices =>
      kIsWeb ? _webMediaDevices : webrtc_impl.navigator.mediaDevices;

  @override
  bool get isWeb => kIsWeb;

  /// Fallback public STUN servers used when the homeserver does not provide
  /// any TURN/STUN credentials via the `/voip/turnServer` API.
  /// Without at least STUN, WebRTC cannot perform NAT traversal and calls
  /// between users on different networks will silently fail to connect.
  static const List<Map<String, dynamic>> _fallbackIceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun.nextcloud.com:443'},
  ];

  @override
  Future<RTCPeerConnection> createPeerConnection(
    Map<String, dynamic> configuration, [
    Map<String, dynamic> constraints = const {},
  ]) {
    // Ensure there are always ICE servers available for NAT traversal.
    final iceServers = configuration['iceServers'];
    if (iceServers == null || (iceServers is List && iceServers.isEmpty)) {
      Logs().w(
        '[VOIP] Homeserver provided no TURN/STUN servers — '
        'injecting fallback STUN servers for NAT traversal',
      );
      configuration = Map<String, dynamic>.from(configuration)
        ..['iceServers'] = _fallbackIceServers;
    } else if (iceServers is List) {
      // Homeserver provided TURN servers — add STUN as a fallback alongside
      // them so direct connections are attempted first.
      final hasStun = iceServers.any((s) {
        final urls = s is Map ? (s['urls'] ?? s['url']) : null;
        if (urls is String) return urls.startsWith('stun:');
        if (urls is List) return urls.any((u) => u.toString().startsWith('stun:'));
        return false;
      });
      if (!hasStun) {
        configuration = Map<String, dynamic>.from(configuration)
          ..['iceServers'] = [...iceServers, ..._fallbackIceServers];
      }
    }

    return webrtc_impl.createPeerConnection(configuration, constraints);
  }

  Future<bool> get hasCallingAccount async => false;

  @override
  Future<void> playRingtone() async {
    if (!background && !await hasCallingAccount) {
      try {
        await UserMediaManager().startRingingTone();
      } catch (_) {}
    }
  }

  @override
  Future<void> stopRingtone() async {
    if (!background && !await hasCallingAccount) {
      try {
        await UserMediaManager().stopRingingTone();
      } catch (_) {}
    }
  }

  @override
  Future<void> handleNewCall(CallSession call) async {
    // Trigger in-app overlay immediately — before any async native bridge
    // calls so the UI is queued on the very next frame, eliminating pickup delay.
    addCallingOverlay(call.callId, call);

    final callkit = CallkitService.instance;
    final callerName = call.room.getLocalizedDisplayname();
    final avatarUrl = call.room
        .getState(EventTypes.RoomAvatar)
        ?.content
        .tryGet<String>('url');
    final isVideo = call.type == CallType.kVideo;

    // Show native incoming/outgoing call screen on iOS/Android
    if (callkit.isSupported) {
      try {
        if (call.isOutgoing) {
          await callkit.showOutgoingCall(
            session: call,
            calleeName: callerName,
            avatarUrl: avatarUrl,
            isVideo: isVideo,
          );
        } else {
          await callkit.showIncomingCall(
            session: call,
            callerName: callerName,
            avatarUrl: avatarUrl,
            isVideo: isVideo,
          );
        }
      } catch (e) {
        Logs().w('[VOIP] CallKit failed, falling back to overlay: $e');
      }
    }

    if (PlatformInfos.isAndroid) {
      try {
        final wasForeground = await FlutterForegroundTask.isAppOnForeground;

        await matrix.store.setString(
          'wasForeground',
          wasForeground == true ? 'true' : 'false',
        );
        FlutterForegroundTask.setOnLockScreenVisibility(true);
        FlutterForegroundTask.wakeUpScreen();
        FlutterForegroundTask.launchApp();
      } catch (e) {
        Logs().e('VOIP foreground failed $e');
      }
    }

    // Notify CallKit when the call actually connects so the native timer starts
    if (CallkitService.instance.isSupported) {
      call.onCallStateChanged.stream.listen((state) {
        if (state == CallState.kConnected) {
          ck.FlutterCallkitIncoming.setCallConnected(call.callId)
              .catchError((e) => Logs().w('[VOIP] setCallConnected failed: $e'));
        }
      });
    }
  }

  @override
  Future<void> handleCallEnded(CallSession session) async {
    // Dismiss native call screen
    try {
      await CallkitService.instance.endCall(session.callId);
    } catch (e) {
      Logs().w('[VOIP] CallKit endCall failed: $e');
    }

    // Clear the inline call sidebar panel (all platforms)
    callExpandedNotifier.value = false;
    // Small delay so the "Call ended" state is visible briefly
    Future.delayed(const Duration(seconds: 2), () {
      if (activeCallNotifier.value?.callId == session.callId) {
        activeCallNotifier.value = null;
      }
    });

    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }

    if (PlatformInfos.isAndroid) {
      FlutterForegroundTask.setOnLockScreenVisibility(false);
      FlutterForegroundTask.stopService();
      final wasForeground = matrix.store.getString('wasForeground');
      if (wasForeground == 'false') FlutterForegroundTask.minimizeApp();
    }
  }

  // ── Group Call State ──
  GroupCallSession? activeGroupCall;
  OverlayEntry? groupCallOverlayEntry;

  @override
  Future<void> handleGroupCallEnded(GroupCallSession groupCall) async {
    Logs().i('[VOIP] Group call ended: ${groupCall.groupCallId}');
    activeGroupCall = null;
    if (groupCallOverlayEntry != null) {
      groupCallOverlayEntry!.remove();
      groupCallOverlayEntry = null;
    }
  }

  @override
  Future<void> handleNewGroupCall(GroupCallSession groupCall) async {
    Logs().i('[VOIP] New group call: ${groupCall.groupCallId}');
    activeGroupCall = groupCall;

    final context = kIsWeb
        ? ChatList.contextForVoip!
        : this.context;

    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (context) => GroupCalling(
          context: context,
          client: client,
          groupCall: groupCall,
          onClear: () => Navigator.of(context).pop(),
        ),
      );
    } else {
      groupCallOverlayEntry = OverlayEntry(
        builder: (_) => GroupCalling(
          context: context,
          client: client,
          groupCall: groupCall,
          onClear: () {
            groupCallOverlayEntry?.remove();
            groupCallOverlayEntry = null;
          },
        ),
      );
      Overlay.of(context).insert(groupCallOverlayEntry!);
    }
  }

  @override
  // TODO: implement canHandleNewCall
  bool get canHandleNewCall =>
      voip.currentCID == null && voip.currentGroupCID == null;

  @override
  Future<void> handleMissedCall(CallSession session) async {
    Logs().i('[VOIP] Missed call from ${session.room.getLocalizedDisplayname()}');
    // Show a local notification for the missed call
    try {
      final flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin.show(
        id: session.callId.hashCode,
        title: 'Missed Call',
        body: 'Missed call from ${session.room.getLocalizedDisplayname()}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'calls_channel',
            'Calls',
            channelDescription: 'Incoming and missed call notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      Logs().w('[VOIP] Failed to show missed call notification: $e');
    }
  }

  @override
  EncryptionKeyProvider? get keyProvider => null;

  @override
  Future<void> registerListeners(CallSession session) async {
    // Call state listeners are registered in the dialer UI (Calling widget).
    // No additional SDK-level listeners needed here.
  }
}
