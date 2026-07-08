import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' hide VideoRenderer;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/utils/voip/active_call_controller.dart';
import 'package:afterdamage/utils/voip/video_renderer.dart';
import 'package:afterdamage/widgets/avatar.dart';

/// Full-screen call UI — incoming, outgoing, and active calls.
///
/// Used on mobile and on narrow windows (mobile web, small desktop windows).
/// Pure view: all state, sounds and actions live on [ActiveCallController].
class CallScreen extends StatefulWidget {
  final ActiveCallController controller;

  /// Called when the call screen should be dismissed (call ended and the
  /// grace period has elapsed).
  final VoidCallback? onClear;

  const CallScreen({
    required this.controller,
    this.onClear,
    super.key,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  ActiveCallController get controller => widget.controller;

  bool _controlsVisible = true;
  Timer? _controlsHideTimer;
  Timer? _dismissTimer;

  late final AnimationController _ringController;
  late final AnimationController _entryController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Slide-up entry animation.
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryController.forward();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    controller.addListener(_onControllerChanged);
    _syncWithController();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(_syncWithController);
  }

  void _syncWithController() {
    if (controller.isConnected || controller.isEnded) {
      _ringController.stop();
    } else if (!_ringController.isAnimating) {
      _ringController.repeat();
    }
    if (controller.isEnded && _dismissTimer == null) {
      _dismissTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) widget.onClear?.call();
      });
    }
    if (controller.isConnected &&
        controller.isVideoCall &&
        _controlsHideTimer == null) {
      _scheduleHideControls();
    }
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
    controller.removeListener(_onControllerChanged);
    _entryController.dispose();
    _ringController.dispose();
    _controlsHideTimer?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // For video calls show the remote video as the background when connected.
    final showVideoBackground = controller.isConnected &&
        controller.isVideoCall &&
        controller.hasRemoteVideo;

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
                  controller.remoteStream!,
                  mirror: false,
                  fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              else
                _buildGradientBackground(),

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
              if (controller.isConnected && controller.isVideoCall)
                _buildLocalPip(),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildTopBar() {
    final title = controller.isIncomingRinging
        ? (controller.isVideoCall ? 'Incoming video call' : 'Incoming call')
        : (controller.isVideoCall ? 'Video call' : 'Voice call');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Only show a close button when the call has ended (otherwise the
          // user can't accidentally leave an active call).
          if (controller.isEnded)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 16),
              color: Colors.white70,
              onPressed: widget.onClear,
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          Text(
            title,
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

  Widget _buildCenter(bool overlaidOnVideo) {
    if (overlaidOnVideo) {
      // Video is the background — just overlay the caller name at the top.
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            controller.displayName,
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
        // Animated rings behind the avatar while ringing.
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (controller.isIncomingRinging)
                AnimatedBuilder(
                  animation: _ringController,
                  builder: (context, _) {
                    final t = _ringController.value;
                    final t2 = (t + 0.35) % 1.0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
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
                    mxContent: controller.avatarUrl,
                    name: controller.displayName,
                    size: 110,
                    client: controller.client,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            controller.displayName,
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
        Text(
          controller.statusLabel,
          style: TextStyle(
            color: controller.isEnded ? Colors.white38 : Colors.white60,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    if (controller.isEnded) return const SizedBox(height: 80);

    // ── INCOMING RINGING: big Decline + Answer buttons ─────────────────────
    if (controller.isIncomingRinging) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(40, 16, 40, 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CallButton(
              icon: FontAwesomeIcons.phoneSlash,
              label: 'Decline',
              backgroundColor: const Color(0xFFE53935),
              onTap: controller.reject,
            ),
            _CallButton(
              icon: FontAwesomeIcons.phone,
              label: 'Answer',
              backgroundColor: const Color(0xFF43A047),
              onTap: controller.answer,
            ),
          ],
        ),
      );
    }

    // ── OUTGOING / PRE-CONNECT: single Cancel button ────────────────────────
    if (!controller.isConnected) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(40, 16, 40, 48),
        child: Center(
          child: _CallButton(
            icon: FontAwesomeIcons.phoneSlash,
            label: L10n.of(context).cancel,
            backgroundColor: const Color(0xFFE53935),
            onTap: controller.hangUp,
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
            icon: controller.isMicrophoneMuted
                ? FontAwesomeIcons.microphoneSlash
                : FontAwesomeIcons.microphone,
            label: controller.isMicrophoneMuted ? 'Unmute' : 'Mute',
            active: controller.isMicrophoneMuted,
            onTap: controller.toggleMicrophone,
          ),
          if (PlatformInfos.isMobile && controller.voiceOnly)
            _ControlButton(
              icon: controller.speakerOn
                  ? FontAwesomeIcons.volumeHigh
                  : FontAwesomeIcons.phone,
              label: 'Speaker',
              active: controller.speakerOn,
              onTap: controller.toggleSpeaker,
            ),
          if (controller.isVideoCall) ...[
            _ControlButton(
              icon: controller.isLocalVideoMuted
                  ? FontAwesomeIcons.videoSlash
                  : FontAwesomeIcons.video,
              label: controller.isLocalVideoMuted ? 'Cam off' : 'Camera',
              active: controller.isLocalVideoMuted,
              onTap: controller.toggleCamera,
            ),
            if (PlatformInfos.isMobile)
              _ControlButton(
                icon: FontAwesomeIcons.arrowsRotate,
                label: 'Flip',
                active: false,
                onTap: controller.flipCamera,
              ),
          ],
          // End-call button — always present + most prominent.
          _CallButton(
            icon: FontAwesomeIcons.phoneSlash,
            label: 'End',
            backgroundColor: const Color(0xFFE53935),
            onTap: controller.hangUp,
            size: 64,
          ),
        ],
      ),
    );
  }

  Widget _buildLocalPip() {
    final localStream = controller.localStream;
    if (localStream == null || controller.isLocalVideoMuted) {
      return const SizedBox.shrink();
    }

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
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
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
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
