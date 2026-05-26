import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' hide VideoRenderer;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/utils/voip/remote_audio_player.dart';
import 'package:afterdamage/utils/voip/video_renderer.dart';
import 'package:afterdamage/widgets/avatar.dart';

/// Full-screen call UI — incoming, outgoing, and active calls.
/// Shown via a [Stack] inside [AppNavigationShell] on mobile and as
/// a centred overlay on desktop/web. This widget owns no overlays of
/// its own; the parent is responsible for mounting/unmounting it.
class CallScreen extends StatefulWidget {
  final CallSession call;
  final Client client;

  /// Called when the call screen should be dismissed (e.g. call ended and the
  /// 2-second grace period has elapsed, or the user taps the minimise button
  /// on desktop).
  final VoidCallback? onClear;

  /// Whether to render the call screen's own top bar.
  /// Set to [false] when the screen is embedded inside a windowed container
  /// (e.g. the floating Discord-style window on web) that provides its own
  /// title bar and drag handle.
  final bool showTopBar;

  const CallScreen({
    required this.call,
    required this.client,
    this.onClear,
    this.showTopBar = true,
    super.key,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  CallSession get call => widget.call;

  CallState? _state;
  DateTime? _connectedAt;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;
  bool _isMicMuted = false;
  bool _isCamMuted = false;
  bool _speakerOn = false;
  bool _controlsVisible = true;
  Timer? _controlsHideTimer;
  AudioPlayer? _dialupPlayer;

  late final AnimationController _ringController;
  late final AnimationController _entryController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _state = call.state;
    _isMicMuted = call.isMicrophoneMuted;
    _isCamMuted = call.isLocalVideoMuted;

    // Slide-up entry animation (mobile/PWA full-screen).
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryController.forward();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    call.onCallStateChanged.stream.listen(_onCallStateChanged);
    call.onCallEventChanged.stream.listen((e) {
      if (e == CallStateChange.kFeedsChanged && mounted) {
        setState(() => call.tryRemoveStopedStreams());
      }
    });

    if (_state == CallState.kConnected) {
      _connectedAt = DateTime.now();
      _startTimer();
      _ringController.stop();
      if (call.type == CallType.kVideo) _scheduleHideControls();
    }
    if (call.type == CallType.kVideo) {
      WakelockPlus.enable().ignore();
    }

    // Play ringback tone while waiting for the remote party to answer.
    if (call.isOutgoing) {
      _playDialupTone();
    }
  }

  void _playDialupTone() async {
    if (!kIsWeb && !PlatformInfos.isMobile && !PlatformInfos.isMacOS) return;
    try {
      final player = AudioPlayer();
      _dialupPlayer = player;
      await player.setAsset('assets/sounds/dialup.ogg');
      await player.play();
    } catch (e) {
      Logs().w('[CallScreen] Failed to play dial-up tone: $e');
    }
  }

  void _stopDialupTone() {
    _dialupPlayer?.stop();
    _dialupPlayer?.dispose();
    _dialupPlayer = null;
  }

  void _onCallStateChanged(CallState state) {
    if (!mounted) return;
    setState(() {
      _state = state;
      _isMicMuted = call.isMicrophoneMuted;
      _isCamMuted = call.isLocalVideoMuted;
    });

    if (state == CallState.kConnected && _connectedAt == null) {
      HapticFeedback.mediumImpact();
      _stopDialupTone();
      setState(() {
        _connectedAt = DateTime.now();
      });
      _ringController.stop();
      _startTimer();
      if (call.type == CallType.kVideo) _scheduleHideControls();
    }

    if (state == CallState.kEnded || state == CallState.kEnding) {
      HapticFeedback.heavyImpact();
      _stopDialupTone();
      _durationTimer?.cancel();
      _ringController.stop();
      Timer(const Duration(seconds: 2), () {
        if (mounted) widget.onClear?.call();
      });
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _callDuration = DateTime.now().difference(_connectedAt!);
      });
    });
  }

  void _scheduleHideControls() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _revealControls() {
    setState(() => _controlsVisible = true);
    _scheduleHideControls();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _ringController.dispose();
    _durationTimer?.cancel();
    _controlsHideTimer?.cancel();
    _stopDialupTone();
    if (call.type == CallType.kVideo) {
      WakelockPlus.disable().ignore();
    }
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _answer() async {
    try {
      await call.answer();
    } catch (e) {
      Logs().w('[CallScreen] answer error: $e');
    }
    if (mounted) setState(() {});
  }

  void _decline() {
    try {
      call.reject();
    } catch (e) {
      Logs().w('[CallScreen] reject error: $e');
    }
  }

  void _hangUp() {
    try {
      if (call.isRinging && !call.isOutgoing) {
        call.reject();
      } else {
        call.hangup(reason: CallErrorCode.userHangup);
      }
    } catch (e) {
      Logs().w('[CallScreen] hangup error: $e');
    }
  }

  Future<void> _toggleMic() async {
    try {
      await call.setMicrophoneMuted(!call.isMicrophoneMuted);
    } catch (e) {
      Logs().w('[CallScreen] setMicrophoneMuted error: $e');
    }
    if (mounted) setState(() => _isMicMuted = call.isMicrophoneMuted);
  }

  Future<void> _toggleCamera() async {
    try {
      await call.setLocalVideoMuted(!call.isLocalVideoMuted);
    } catch (e) {
      Logs().w('[CallScreen] setLocalVideoMuted error: $e');
    }
    if (mounted) setState(() => _isCamMuted = call.isLocalVideoMuted);
  }

  Future<void> _toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    try {
      await Helper.setSpeakerphoneOn(_speakerOn);
    } catch (e) {
      Logs().w('[CallScreen] setSpeakerphoneOn error: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _flipCamera() async {
    final tracks = call.localUserMediaStream?.stream?.getVideoTracks();
    if (tracks != null && tracks.isNotEmpty) {
      try {
        await Helper.switchCamera(tracks.first);
      } catch (e) {
        Logs().w('[CallScreen] switchCamera error: $e');
      }
    }
  }

  // ── Derived helpers ───────────────────────────────────────────────────────

  bool get _isIncomingRinging =>
      !call.isOutgoing &&
      (_state == CallState.kRinging || _state == CallState.kFledgling);
  bool get _isConnected => _state == CallState.kConnected;
  bool get _isEnded =>
      _state == CallState.kEnded || _state == CallState.kEnding;
  bool get _isVideoCall => call.type == CallType.kVideo;
  bool get _isVoiceOnly => call.type == CallType.kVoice;

  WrappedMediaStream? get _remoteStream =>
      call.remoteUserMediaStream ?? call.remoteScreenSharingStream;
  WrappedMediaStream? get _localStream => call.localUserMediaStream;

  String get _callerName {
    if (call.room.isDirectChat) {
      final userId = call.room.directChatMatrixID ?? '';
      final user = call.room.unsafeGetUserFromMemoryOrFallback(userId);
      return user.displayName ?? user.id;
    }
    return call.room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)),
    );
  }

  Uri? get _callerAvatar {
    if (call.room.isDirectChat) {
      final userId = call.room.directChatMatrixID ?? '';
      return call.room.unsafeGetUserFromMemoryOrFallback(userId).avatarUrl;
    }
    return call.room
        .getState(EventTypes.RoomAvatar)
        ?.content
        .tryGet<Uri>('url');
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String get _statusLabel {
    if (_isEnded) return 'Call ended';
    if (_isConnected) return _formatDuration(_callDuration);
    if (_isIncomingRinging) {
      return _isVideoCall ? 'Incoming video call' : 'Incoming voice call';
    }
    switch (_state) {
      case CallState.kInviteSent:
      case CallState.kCreateOffer:
        return 'Calling…';
      case CallState.kRinging:
        return 'Ringing…';
      case CallState.kCreateAnswer:
      case CallState.kConnecting:
        return 'Connecting…';
      default:
        return 'Setting up…';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // For video calls show the video as the background when connected.
    final showVideoBackground = _isConnected &&
        _isVideoCall &&
        _remoteStream != null &&
        !_remoteStream!.videoMuted;

    return SlideTransition(
      position: _slideAnimation,
      child: Material(
      color: Colors.black,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: showVideoBackground ? _revealControls : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background ──────────────────────────────────────────────
            if (showVideoBackground)
              VideoRenderer(
                _remoteStream!,
                mirror: false,
                fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              _buildGradientBackground(),

            // ── Hidden audio engine (web only) ───────────────────────────
            Positioned(
              width: 0,
              height: 0,
              child: RemoteAudioPlayer(call: call),
            ),

            // ── Main chrome (top + centre + bottom) ──────────────────────
            AnimatedOpacity(
              opacity: showVideoBackground && !_controlsVisible ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(child: _buildCenter(showVideoBackground)),
                    _buildBottomControls(),
                  ],
                ),
              ),
            ),

            // ── Local video PiP (video calls only) ────────────────────────
            if (_isConnected && _isVideoCall) _buildLocalPip(),
          ],
        ),
      ),
      ),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1B2F), Color(0xFF0D0D1A)],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    if (!widget.showTopBar) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Only show a close/minimise button when the call has ended
          // (otherwise the user can't accidentally leave an active call).
          if (_isEnded)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 16),
              color: Colors.white70,
              onPressed: widget.onClear,
            )
          else
            const SizedBox(width: 48),

          const Spacer(),

          Text(
            call.isOutgoing
                ? (_isVideoCall ? 'Video call' : 'Voice call')
                : (_isIncomingRinging
                    ? (_isVideoCall ? 'Incoming video call' : 'Incoming call')
                    : (_isVideoCall ? 'Video call' : 'Voice call')),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Centre ───────────────────────────────────────────────────────────────

  Widget _buildCenter(bool overlaidOnVideo) {
    if (overlaidOnVideo) {
      // Video is the background — just overlay the caller name at the top.
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            _callerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 10)],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated ring behind avatar when incoming call is ringing.
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isIncomingRinging)
                AnimatedBuilder(
                  animation: _ringController,
                  builder: (context, _) {
                    final t = _ringController.value;
                    // Outer ring — slightly delayed phase
                    final t2 = (t + 0.35) % 1.0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Inner ring
                        Container(
                          width: 130 + t * 30,
                          height: 130 + t * 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green.withValues(
                                alpha: (1.0 - t) * 0.65,
                              ),
                              width: 2.5,
                            ),
                          ),
                        ),
                        // Outer ring (offset phase)
                        Container(
                          width: 130 + t2 * 30,
                          height: 130 + t2 * 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green.withValues(
                                alpha: (1.0 - t2) * 0.35,
                              ),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              // Avatar
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Avatar(
                    mxContent: _callerAvatar,
                    name: _callerName,
                    size: 110,
                    client: widget.client,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Caller name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _callerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),

        const SizedBox(height: 10),

        // Status / timer
        Text(
          _statusLabel,
          style: TextStyle(
            color: _isEnded ? Colors.white38 : Colors.white60,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // ── Bottom controls ───────────────────────────────────────────────────────

  Widget _buildBottomControls() {
    if (_isEnded) return const SizedBox(height: 80);

    // ── INCOMING RINGING: big Decline + Answer buttons ─────────────────────
    if (_isIncomingRinging) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(40, 16, 40, 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CallButton(
              icon: FontAwesomeIcons.phoneSlash,
              label: 'Decline',
              backgroundColor: const Color(0xFFE53935),
              onTap: _decline,
            ),
            _CallButton(
              icon: FontAwesomeIcons.phone,
              label: 'Answer',
              backgroundColor: const Color(0xFF43A047),
              onTap: _answer,
            ),
          ],
        ),
      );
    }

    // ── OUTGOING / PRE-CONNECT: single Cancel button ────────────────────────
    if (!_isConnected) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(40, 16, 40, 48),
        child: Center(
          child: _CallButton(
            icon: FontAwesomeIcons.phoneSlash,
            label: L10n.of(context).cancel,
            backgroundColor: const Color(0xFFE53935),
            onTap: _hangUp,
          ),
        ),
      );
    }

    // ── CONNECTED: control row ──────────────────────────────────────────────
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: _isMicMuted
                ? FontAwesomeIcons.microphoneSlash
                : FontAwesomeIcons.microphone,
            label: _isMicMuted ? 'Unmute' : 'Mute',
            active: _isMicMuted,
            onTap: _toggleMic,
          ),
          if (!kIsWeb && _isVoiceOnly)
            _ControlButton(
              icon: _speakerOn
                  ? FontAwesomeIcons.volumeHigh
                  : FontAwesomeIcons.phone,
              label: 'Speaker',
              active: _speakerOn,
              onTap: _toggleSpeaker,
            ),
          if (_isVideoCall) ...[
            _ControlButton(
              icon: _isCamMuted
                  ? FontAwesomeIcons.videoSlash
                  : FontAwesomeIcons.video,
              label: _isCamMuted ? 'Cam off' : 'Camera',
              active: _isCamMuted,
              onTap: _toggleCamera,
            ),
            if (!kIsWeb)
              _ControlButton(
                icon: FontAwesomeIcons.arrowsRotate,
                label: 'Flip',
                active: false,
                onTap: _flipCamera,
              ),
          ],
          // End-call button — always present + most prominent
          _CallButton(
            icon: FontAwesomeIcons.phoneSlash,
            label: 'End',
            backgroundColor: const Color(0xFFE53935),
            onTap: _hangUp,
            size: 64,
          ),
        ],
      ),
    );
  }

  // ── Local PiP ─────────────────────────────────────────────────────────────

  Widget _buildLocalPip() {
    final localStream = _localStream;
    if (localStream == null || _isCamMuted) return const SizedBox.shrink();

    return Positioned(
      top: 80,
      right: 12,
      width: 90,
      height: 130,
      child: GestureDetector(
        onTap: _revealControls,
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: VideoRenderer(
            localStream,
            mirror: true,
            fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

/// Large circular button used for Answer / Decline / Cancel / End.
class _CallButton extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;
  final double size;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
    this.size = 70,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          shadowColor: backgroundColor.withValues(alpha: 0.45),
          elevation: 6,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            splashColor: Colors.white24,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: FaIcon(icon, color: Colors.white, size: size * 0.38),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

/// Smaller circular button used for Mute / Speaker / Camera / Flip in the
/// connected-call controls row.
class _ControlButton extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        active ? Colors.white : Colors.white.withValues(alpha: 0.15);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bgColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            splashColor: active ? Colors.black12 : Colors.white24,
            child: SizedBox(
              width: 54,
              height: 54,
              child: Center(
                child: FaIcon(
                  icon,
                  color: active ? Colors.black : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
