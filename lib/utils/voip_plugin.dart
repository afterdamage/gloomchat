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
import 'package:afterdamage/utils/voip/active_call_controller.dart';
import 'package:afterdamage/utils/voip/call_sounds.dart';
import 'package:afterdamage/utils/voip/callkit_events.dart' as ck;
import 'package:afterdamage/utils/voip/callkit_service.dart';
import 'package:afterdamage/utils/voip/web_media_fixer.dart';
import '../widgets/matrix.dart';

/// WebRTC delegate for the Matrix SDK.
///
/// Owns the [VoIP] instance and publishes exactly one [ActiveCallController]
/// per 1:1 call via [activeCallNotifier]. All call UI (full-screen screen,
/// sidebar panel, incoming card) renders from that controller — this class
/// never builds widgets itself.
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
  late VoIP voip;
  StreamSubscription<ck.CallEvent?>? _callkitEventSub;
  BuildContext get context => matrix.context;

  /// Wraps getUserMedia so a permission/missing-device error on web and
  /// desktop returns a silent placeholder stream instead of killing the
  /// incoming call before its UI ever appears (the SDK requests media
  /// *before* handleNewCall fires). The real stream is swapped in by
  /// [ActiveCallController.answer].
  late final WebMediaDevicesWrapper _mediaDevicesWrapper =
      WebMediaDevicesWrapper(webrtc_impl.navigator.mediaDevices);

  /// The active 1:1 call, or null. Lives on [MatrixState] so the overlay is
  /// wired up even before this plugin exists.
  ValueNotifier<ActiveCallController?> get activeCallNotifier =>
      matrix.activeCallNotifier;

  /// Whether the Discord-style panel above the chat is expanded.
  ValueNotifier<bool> get callExpandedNotifier => matrix.callExpandedNotifier;

  void dispose() {
    if (!kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _callkitEventSub?.cancel();
    _callkitEventSub = null;
    _publish(null);
    // The controller only stops sounds on state transitions — a mid-call
    // teardown (logout / client switch) must silence them explicitly.
    CallSounds.instance.stop();
  }

  /// Forwards native call UI events (Accept / Decline / End) from
  /// flutter_callkit_incoming to the matching call controller.
  void _listenCallkitEvents() {
    _callkitEventSub = ck.FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      final body = event.body;
      if (body is! Map) return;
      final callId = body['id'] as String?;
      if (callId == null) return;

      final controller = activeCallNotifier.value;
      if (controller == null || controller.callId != callId) {
        Logs().w('[VOIP] Callkit event for unknown callId $callId, ignoring');
        return;
      }

      switch (event.event) {
        case ck.Event.actionCallAccept:
          Logs().i('[VOIP] Callkit accept => answering call $callId');
          await controller.answer();
          break;
        case ck.Event.actionCallDecline:
          Logs().i('[VOIP] Callkit decline => rejecting call $callId');
          await controller.reject();
          break;
        case ck.Event.actionCallEnded:
        case ck.Event.actionCallTimeout:
          Logs().i('[VOIP] Callkit ended/timeout => hanging up call $callId');
          if (!controller.call.callHasEnded) {
            await controller.hangUp();
          }
          break;
        // The real (mobile) Event enum has more variants than the stub.
        // ignore: unreachable_switch_default
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

  /// Publishes [controller] as the active call, disposing any previous one.
  void _publish(ActiveCallController? controller) {
    final previous = activeCallNotifier.value;
    if (previous == controller) return;
    activeCallNotifier.value = controller;
    previous?.dispose();
    if (controller == null) {
      callExpandedNotifier.value = false;
    }
  }

  /// Returns the controller for [call], creating and publishing it if needed.
  ActiveCallController _controllerFor(CallSession call) {
    final existing = activeCallNotifier.value;
    if (existing != null && existing.callId == call.callId) return existing;
    final controller = ActiveCallController(call: call, client: client);
    _publish(controller);
    return controller;
  }

  @override
  MediaDevices get mediaDevices =>
      (kIsWeb || PlatformInfos.isDesktop)
          ? _mediaDevicesWrapper
          : webrtc_impl.navigator.mediaDevices;

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
        if (urls is List) {
          return urls.any((u) => u.toString().startsWith('stun:'));
        }
        return false;
      });
      if (!hasStun) {
        configuration = Map<String, dynamic>.from(configuration)
          ..['iceServers'] = [...iceServers, ..._fallbackIceServers];
      }
    }

    return webrtc_impl.createPeerConnection(configuration, constraints);
  }

  // The SDK rings before handleNewCall (so the user hears the call even if
  // media setup is slow). CallSounds is idempotent, so this composes safely
  // with ActiveCallController driving the same sounds.
  @override
  Future<void> playRingtone() async {
    if (CallkitService.instance.isSupported) return; // native UI rings
    await CallSounds.instance.startRingtone();
  }

  @override
  Future<void> stopRingtone() async {
    await CallSounds.instance.stop();
  }

  @override
  Future<void> registerListeners(CallSession session) async {
    // Called by the SDK before media setup for both incoming and outgoing
    // calls — the earliest reliable moment to show the call UI. Incoming
    // calls whose getUserMedia fails still get a visible (ended) call this
    // way instead of disappearing silently.
    _controllerFor(session);
  }

  @override
  Future<void> handleNewCall(CallSession call) async {
    // Idempotent — normally already published by registerListeners.
    final controller = _controllerFor(call);

    final isVideo = call.type == CallType.kVideo;
    final callkit = CallkitService.instance;
    if (callkit.isSupported) {
      final avatarUrl = call.room
          .getState(EventTypes.RoomAvatar)
          ?.content
          .tryGet<String>('url');
      try {
        if (call.isOutgoing) {
          await callkit.showOutgoingCall(
            session: call,
            calleeName: controller.displayName,
            avatarUrl: avatarUrl,
            isVideo: isVideo,
          );
        } else {
          await callkit.showIncomingCall(
            session: call,
            callerName: controller.displayName,
            avatarUrl: avatarUrl,
            isVideo: isVideo,
          );
        }
      } catch (e) {
        Logs().w('[VOIP] CallKit failed, falling back to in-app UI: $e');
      }
    }

    if (PlatformInfos.isAndroid && !call.isOutgoing) {
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
  }

  @override
  Future<void> handleCallEnded(CallSession session) async {
    // Dismiss native call screen.
    try {
      await CallkitService.instance.endCall(session.callId);
    } catch (e) {
      Logs().w('[VOIP] CallKit endCall failed: $e');
    }

    // Collapse the expanded panel; keep the "Call ended" state visible
    // briefly, then clear — unless a new call has replaced it already.
    callExpandedNotifier.value = false;
    Future.delayed(const Duration(seconds: 2), () {
      if (activeCallNotifier.value?.callId == session.callId) {
        _publish(null);
      }
    });

    if (PlatformInfos.isAndroid) {
      FlutterForegroundTask.setOnLockScreenVisibility(false);
      FlutterForegroundTask.stopService();
      final wasForeground = matrix.store.getString('wasForeground');
      if (wasForeground == 'false') FlutterForegroundTask.minimizeApp();
    }
  }

  @override
  bool get canHandleNewCall =>
      voip.currentCID == null && voip.currentGroupCID == null;

  @override
  Future<void> handleMissedCall(CallSession session) async {
    Logs().i(
      '[VOIP] Missed call from ${session.room.getLocalizedDisplayname()}',
    );
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
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

    final context = kIsWeb ? ChatList.contextForVoip! : this.context;

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
}
