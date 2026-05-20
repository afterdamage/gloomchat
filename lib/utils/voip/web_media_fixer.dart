import 'package:flutter/foundation.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc_impl;
import 'package:matrix/matrix.dart';
import 'package:webrtc_interface/webrtc_interface.dart';

/// A [MediaDevices] wrapper that prevents incoming calls from being killed on
/// web when the browser refuses `getUserMedia` due to a missing user gesture.
///
/// **Problem:** The Matrix SDK calls `getUserMedia()` inside
/// `initWithInvite()` *before* the user clicks "Answer". On web, browsers
/// require a user gesture to grant microphone/camera access, so the call throws
/// `NotAllowedError` → `_getUserMediaFailed` → call terminated. The user never
/// even sees the incoming call UI.
///
/// **Solution:** On web, this wrapper catches the permission error and returns
/// a silent empty [MediaStream] so the call can reach the "Ringing" state.
/// When the user taps "Answer" (a real user gesture), the actual media is
/// requested again by the SDK's `answer()` flow which replaces the placeholder
/// tracks.
///
/// On non-web platforms this wrapper is a transparent pass-through.
class WebMediaDevicesWrapper extends MediaDevices {
  final MediaDevices _delegate;

  /// Whether the last `getUserMedia` call returned a placeholder (silent)
  /// stream because the browser denied the real request.
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
      if (kIsWeb && _isPermissionError(e)) {
        Logs().w(
          '[WebMediaFixer] getUserMedia blocked (no user gesture / permission '
          'denied) — returning silent placeholder stream so the incoming call '
          'can ring. Error: $e',
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

  /// Detects permission-related errors from the browser's getUserMedia.
  static bool _isPermissionError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('notallowederror') ||
        msg.contains('not allowed') ||
        msg.contains('permission denied') ||
        msg.contains('permissiondenied') ||
        msg.contains('unable to getusermedia');
  }
}
