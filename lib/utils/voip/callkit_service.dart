import 'package:flutter/foundation.dart';

import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/utils/platform_infos.dart';

/// Wraps flutter_callkit_incoming for native call UI on iOS & Android.
/// On desktop/web, this is a no-op — the VoipPlugin overlay handles it.
class CallkitService {
  CallkitService._();
  static final CallkitService instance = CallkitService._();

  /// Whether the current platform supports native call UI.
  bool get isSupported =>
      !kIsWeb && (PlatformInfos.isAndroid || PlatformInfos.isIOS);

  /// Show native incoming call screen.
  Future<void> showIncomingCall({
    required CallSession session,
    required String callerName,
    String? avatarUrl,
    bool isVideo = false,
  }) async {
    if (!isSupported) return;

    final params = CallKitParams(
      id: session.callId,
      nameCaller: callerName,
      appName: 'GloomChat',
      avatar: avatarUrl,
      handle: session.room.id,
      type: isVideo ? 1 : 0, // 0 = audio, 1 = video
      duration: 45000, // ring for 45 seconds
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      extra: <String, dynamic>{
        'roomId': session.room.id,
        'callId': session.callId,
      },
      android: const AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1B1B2F',
        actionColor: '#7B2FBE',
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: false,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: null, // use system default
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// Show outgoing call screen (for native integration).
  Future<void> showOutgoingCall({
    required CallSession session,
    required String calleeName,
    String? avatarUrl,
    bool isVideo = false,
  }) async {
    if (!isSupported) return;

    final params = CallKitParams(
      id: session.callId,
      nameCaller: calleeName,
      appName: 'GloomChat',
      avatar: avatarUrl,
      handle: session.room.id,
      type: isVideo ? 1 : 0,
      extra: <String, dynamic>{
        'roomId': session.room.id,
        'callId': session.callId,
      },
      android: const AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        backgroundColor: '#1B1B2F',
        actionColor: '#7B2FBE',
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
      ),
    );

    await FlutterCallkitIncoming.startCall(params);
  }

  /// Mark the call as connected so the native UI starts its timer.
  Future<void> setConnected(String callId) async {
    if (!isSupported) return;
    try {
      await FlutterCallkitIncoming.setCallConnected(callId);
    } catch (e) {
      Logs().w('[VOIP] setCallConnected failed: $e');
    }
  }

  /// Dismiss the native call screen.
  Future<void> endCall(String callId) async {
    if (!isSupported) return;
    await FlutterCallkitIncoming.endCall(callId);
  }

  /// End all active calls.
  Future<void> endAllCalls() async {
    if (!isSupported) return;
    await FlutterCallkitIncoming.endAllCalls();
  }
}
