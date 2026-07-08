import 'package:flutter/foundation.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc_impl;
import 'package:matrix/matrix.dart';
import 'package:webrtc_interface/webrtc_interface.dart';

import 'package:afterdamage/utils/platform_infos.dart';

/// A [MediaDevices] wrapper that prevents incoming calls from being killed
/// when `getUserMedia` fails before the user has interacted.
///
/// **Problem:** The Matrix SDK calls `getUserMedia()` inside
/// `initWithInvite()` *before* the user clicks "Answer". On web, browsers
/// require a user gesture to grant microphone/camera access, so the call
/// throws `NotAllowedError` → `_getUserMediaFailed` → call terminated. On
/// desktop, a missing or busy capture device does the same. Either way the
/// user never even sees the incoming call UI.
///
/// **Solution:** On web and desktop, this wrapper catches the error and
/// returns a silent empty [MediaStream] so the call can reach the "Ringing"
/// state. When the user taps "Answer" (a real user gesture),
/// [ActiveCallController.answer] swaps in the real media.
class WebMediaDevicesWrapper extends MediaDevices {
  final MediaDevices _delegate;

  /// Whether the last `getUserMedia` call returned a placeholder (silent)
  /// stream because the real request failed.
  bool usedPlaceholder = false;

  WebMediaDevicesWrapper(this._delegate);

  @override
  Future<MediaStream> getUserMedia(
    Map<String, dynamic> mediaConstraints,
  ) async {
    try {
      final stream = await _delegate.getUserMedia(mediaConstraints);
      usedPlaceholder = false;
      return stream;
    } catch (e) {
      final canFallBack = kIsWeb || PlatformInfos.isDesktop;
      if (canFallBack && _isRecoverableMediaError(e)) {
        Logs().w(
          '[WebMediaFixer] getUserMedia failed (no user gesture / permission '
          'denied / device unavailable) — returning silent placeholder stream '
          'so the incoming call can ring. Error: $e',
        );
        usedPlaceholder = true;
        // Create a real but empty MediaStream so the SDK doesn't crash.
        final placeholder =
            await webrtc_impl.createLocalMediaStream('placeholder');
        return placeholder;
      }
      rethrow;
    }
  }

  @override
  Future<MediaStream> getDisplayMedia(
    Map<String, dynamic> mediaConstraints,
  ) =>
      _delegate.getDisplayMedia(mediaConstraints);

  @override
  Future<List<MediaDeviceInfo>> enumerateDevices() =>
      _delegate.enumerateDevices();

  @override
  @Deprecated('use enumerateDevices() instead')
  Future<List<dynamic>> getSources() =>
      // ignore: deprecated_member_use
      _delegate.getSources();

  @override
  MediaTrackSupportedConstraints getSupportedConstraints() =>
      _delegate.getSupportedConstraints();

  @override
  Future<MediaDeviceInfo> selectAudioOutput([AudioOutputOptions? options]) =>
      _delegate.selectAudioOutput(options);

  @override
  set ondevicechange(Function(dynamic event)? listener) {
    _delegate.ondevicechange = listener;
  }

  @override
  Function(dynamic event)? get ondevicechange => _delegate.ondevicechange;

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Errors from getUserMedia that should ring with a placeholder stream
  /// rather than kill the incoming call: permission problems (web gesture
  /// requirement) and missing/busy capture devices (desktop).
  static bool _isRecoverableMediaError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('notallowederror') ||
        msg.contains('not allowed') ||
        msg.contains('permission denied') ||
        msg.contains('permissiondenied') ||
        msg.contains('notfounderror') ||
        msg.contains('devicesnotfounderror') ||
        msg.contains('notreadableerror') ||
        msg.contains('trackstarterror') ||
        msg.contains('unable to getusermedia');
  }
}
