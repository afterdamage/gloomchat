import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/matrix.dart';

/// An invisible widget that attaches the remote audio stream to an
/// HTML media element so that audio playback works on web.
///
/// On native platforms, audio is routed via the OS audio layer automatically,
/// so this widget does nothing there.
class RemoteAudioPlayer extends StatefulWidget {
  final CallSession call;

  const RemoteAudioPlayer({required this.call, super.key});

  @override
  State<RemoteAudioPlayer> createState() => _RemoteAudioPlayerState();
}

class _RemoteAudioPlayerState extends State<RemoteAudioPlayer> {
  RTCVideoRenderer? _audioRenderer;
  StreamSubscription? _callEventSubscription;
  StreamSubscription? _callStateSubscription;
  bool _attached = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _callEventSubscription =
          widget.call.onCallEventChanged.stream.listen((event) {
        if (event == CallStateChange.kFeedsChanged) {
          _attachRemoteAudio();
        }
      });
      // Also listen for state changes — the remote stream may arrive at
      // kConnected before a kFeedsChanged event is emitted.
      _callStateSubscription =
          widget.call.onCallStateChanged.stream.listen((state) {
        if (state == CallState.kConnected) {
          _attachRemoteAudio();
        }
      });
      _attachRemoteAudio();
    }
  }

  Future<void> _attachRemoteAudio() async {
    if (!kIsWeb) return;

    final remoteStream = widget.call.remoteUserMediaStream?.stream;
    if (remoteStream == null) return;

    try {
      if (_audioRenderer == null) {
        _audioRenderer = RTCVideoRenderer();
        await _audioRenderer!.initialize();
      }
      _audioRenderer!.srcObject = remoteStream;
      _attached = true;
      if (mounted) setState(() {});
      Logs().i('[RemoteAudioPlayer] Attached remote audio stream');
    } catch (e) {
      Logs().w('[RemoteAudioPlayer] Failed to attach remote audio: $e');
    }
  }

  @override
  void didUpdateWidget(RemoteAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.call != widget.call) {
      _detach();
      _attached = false;
      _attachRemoteAudio();
    }
  }

  void _detach() {
    try {
      _audioRenderer?.srcObject = null;
      _audioRenderer?.dispose();
      _audioRenderer = null;
    } catch (_) {}
  }

  @override
  void dispose() {
    _callEventSubscription?.cancel();
    _callStateSubscription?.cancel();
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On web, we MUST render an RTCVideoView so the underlying HTML <video>
    // element is actually inserted into the DOM — otherwise audio won't play.
    // We use a 1x1 Opacity(0) box instead of 0x0 because Flutter web can
    // optimise away zero-sized elements, preventing the <video> tag from
    // reaching the DOM and silencing remote audio.
    if (!kIsWeb || _audioRenderer == null || !_attached) {
      return const SizedBox.shrink();
    }
    return Opacity(
      opacity: 0,
      child: SizedBox(
        width: 1,
        height: 1,
        child: RTCVideoView(
          _audioRenderer!,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
        ),
      ),
    );
  }
}
