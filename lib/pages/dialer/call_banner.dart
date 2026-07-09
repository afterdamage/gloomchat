import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' hide VideoRenderer;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/theme/dracula_colors.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/utils/voip/active_call_controller.dart';
import 'package:afterdamage/utils/voip/video_renderer.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/matrix.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CallSidebarPanel — compact Discord-style call bar for the navigation sidebar
// ─────────────────────────────────────────────────────────────────────────────

/// A compact call status panel that sits at the bottom of the sidebar,
/// exactly like Discord's "Voice Connected" bar. Shows connection status,
/// room name, duration, and minimal controls. Does NOT obstruct navigation.
///
/// Pure view on [ActiveCallController] — no sounds, timers or SDK
/// subscriptions of its own.
class CallSidebarPanel extends StatefulWidget {
  final ActiveCallController controller;
  final VoidCallback? onExpand;

  const CallSidebarPanel({required this.controller, this.onExpand, super.key});

  @override
  State<CallSidebarPanel> createState() => _CallSidebarPanelState();
}

class _CallSidebarPanelState extends State<CallSidebarPanel>
    with TickerProviderStateMixin {
  ActiveCallController get controller => widget.controller;

  late final AnimationController _pulseController;
  // Horizontal shimmy played when an incoming call first rings.
  late final AnimationController _shimmyController;
  late final Animation<double> _shimmyAnimation;
  bool _autoExpanded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shimmyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shimmyAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shimmyController, curve: Curves.easeInOut),
        );

    controller.addListener(_onControllerChanged);
    if (controller.isIncomingRinging) {
      _shimmyController.forward();
    }
    _syncPulse();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {
      _syncPulse();
      // Auto-expand the call panel once the call connects (Discord shows the
      // voice panel above the chat as soon as you join).
      if (controller.isConnected && !_autoExpanded) {
        _autoExpanded = true;
        widget.onExpand?.call();
      }
    });
  }

  void _syncPulse() {
    if (controller.isConnected || controller.isEnded) {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 1.0;
      }
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    _pulseController.dispose();
    _shimmyController.dispose();
    super.dispose();
  }

  String get _statusText {
    if (controller.isEnded) return 'Call Ended';
    if (controller.isConnected) {
      return controller.voiceOnly ? 'Voice Connected' : 'Video Connected';
    }
    if (controller.isIncomingRinging) return 'Incoming Call';
    return controller.isOutgoing ? 'Calling...' : 'Connecting...';
  }

  Color get _statusColor {
    if (controller.isConnected) return DraculaColors.green;
    if (controller.isEnded) return DraculaColors.red;
    if (controller.isIncomingRinging) return DraculaColors.yellow;
    return DraculaColors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final isRinging = controller.isIncomingRinging;
    final isConnected = controller.isConnected;
    final isEnded = controller.isEnded;

    return AnimatedBuilder(
      animation: _shimmyAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shimmyAnimation.value, 0),
          child: child,
        );
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 1, color: DraculaColors.currentLine),

            // Main call panel
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isConnected && !isEnded
                    ? const Color(0xFF1A2E1A)
                    : DraculaColors.background,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Row(
                      children: [
                        // Animated status dot
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                color: _statusColor.withValues(
                                  alpha: isConnected
                                      ? 1.0
                                      : 0.5 + (_pulseController.value * 0.5),
                                ),
                                boxShadow: isConnected
                                    ? [
                                        BoxShadow(
                                          color: _statusColor.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusText,
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (isConnected)
                          Text(
                            ActiveCallController.formatDuration(
                              controller.duration,
                            ),
                            style: const TextStyle(
                              color: DraculaColors.muted,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Room / caller name
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 2, 12, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        controller.displayName,
                        style: const TextStyle(
                          color: DraculaColors.muted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Control buttons row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                    child: Row(
                      children: [
                        // Answer button (incoming ringing)
                        if (isRinging) ...[
                          _SidebarControlButton(
                            icon: FontAwesomeIcons.phone,
                            color: DraculaColors.green,
                            bgColor: DraculaColors.green.withValues(
                              alpha: 0.15,
                            ),
                            onTap: () async {
                              await controller.answer();
                              widget.onExpand?.call();
                            },
                            tooltip: 'Answer',
                          ),
                          const SizedBox(width: 4),
                        ],

                        // Hang up / Decline
                        if (!isEnded)
                          _SidebarControlButton(
                            icon: FontAwesomeIcons.phoneSlash,
                            color: DraculaColors.foreground,
                            bgColor: DraculaColors.red,
                            onTap: controller.hangUp,
                            tooltip: isRinging ? 'Decline' : 'Disconnect',
                            wide: true,
                          ),

                        // Mic toggle
                        if (isConnected) ...[
                          const SizedBox(width: 8),
                          _SidebarControlButton(
                            icon: controller.isMicrophoneMuted
                                ? FontAwesomeIcons.microphoneSlash
                                : FontAwesomeIcons.microphone,
                            color: controller.isMicrophoneMuted
                                ? DraculaColors.red
                                : DraculaColors.foreground.withValues(
                                    alpha: 0.7,
                                  ),
                            bgColor: controller.isMicrophoneMuted
                                ? DraculaColors.red.withValues(alpha: 0.15)
                                : DraculaColors.currentLine.withValues(
                                    alpha: 0.6,
                                  ),
                            onTap: controller.toggleMicrophone,
                            tooltip: controller.isMicrophoneMuted
                                ? 'Unmute'
                                : 'Mute',
                          ),
                        ],

                        // Camera toggle (video calls only)
                        if (isConnected && controller.isVideoCall) ...[
                          const SizedBox(width: 4),
                          _SidebarControlButton(
                            icon: controller.isLocalVideoMuted
                                ? FontAwesomeIcons.videoSlash
                                : FontAwesomeIcons.video,
                            color: controller.isLocalVideoMuted
                                ? DraculaColors.red
                                : DraculaColors.foreground.withValues(
                                    alpha: 0.7,
                                  ),
                            bgColor: controller.isLocalVideoMuted
                                ? DraculaColors.red.withValues(alpha: 0.15)
                                : DraculaColors.currentLine.withValues(
                                    alpha: 0.6,
                                  ),
                            onTap: controller.toggleCamera,
                            tooltip: controller.isLocalVideoMuted
                                ? 'Turn on camera'
                                : 'Turn off camera',
                          ),
                        ],

                        const Spacer(),

                        // Expand button
                        if (isConnected)
                          _SidebarControlButton(
                            icon: FontAwesomeIcons.upRightAndDownLeftFromCenter,
                            color: DraculaColors.foreground.withValues(
                              alpha: 0.7,
                            ),
                            bgColor: DraculaColors.currentLine.withValues(
                              alpha: 0.6,
                            ),
                            onTap: widget.onExpand,
                            tooltip: 'Expand call',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small control button used in the sidebar call panel.
class _SidebarControlButton extends StatelessWidget {
  final FaIconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;
  final String tooltip;
  final bool wide;

  const _SidebarControlButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    required this.tooltip,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.zero,
          child: Container(
            width: wide ? 40 : 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.zero,
              color: bgColor,
            ),
            child: FaIcon(icon, color: color, size: 13),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CallFloatingPanel — fixed call panel that sits on top of the chat area
// ─────────────────────────────────────────────────────────────────────────────

/// A fixed panel that shows the call view (video feeds + avatars + controls)
/// at the top of the chat content area, like Discord. Does NOT float or drag;
/// it sits above the chat messages and can be collapsed back to sidebar-only.
class CallFloatingPanel extends StatelessWidget {
  final ActiveCallController controller;
  final VoidCallback? onMinimize;

  const CallFloatingPanel({
    required this.controller,
    this.onMinimize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final remoteStream = controller.remoteStream;
        final localStream = controller.localStream;
        final hasRemoteVideo = controller.hasRemoteVideo;
        final hasLocalVideo =
            localStream != null && !controller.isLocalVideoMuted;

        // Scale with the window like Discord's voice area: video calls get
        // more room than voice-only avatar tiles.
        final windowHeight = MediaQuery.sizeOf(context).height;
        final panelHeight = (windowHeight * (hasRemoteVideo ? 0.55 : 0.42))
            .clamp(280.0, hasRemoteVideo ? 640.0 : 480.0);

        return Container(
          width: double.infinity,
          height: panelHeight,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1F2E),
            border: Border(
              bottom: BorderSide(color: DraculaColors.currentLine, width: 1),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Title bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: DraculaColors.currentLine.withValues(alpha: 0.8),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      controller.voiceOnly
                          ? FontAwesomeIcons.phone
                          : FontAwesomeIcons.video,
                      color: DraculaColors.green,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.displayName,
                        style: const TextStyle(
                          color: DraculaColors.foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      controller.statusLabel,
                      style: const TextStyle(
                        color: DraculaColors.muted,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FloatingControlButton(
                      icon: FontAwesomeIcons.chevronUp,
                      color: DraculaColors.foreground.withValues(alpha: 0.7),
                      onTap: onMinimize,
                      tooltip: 'Collapse',
                      size: 24,
                    ),
                  ],
                ),
              ),

              // Main content area — avatar grid or video
              Expanded(
                child: Container(
                  color: const Color(0xFF1A1B2E),
                  child: _buildMainContent(
                    hasRemoteVideo: hasRemoteVideo,
                    hasLocalVideo: hasLocalVideo,
                    remoteStream: remoteStream,
                    localStream: localStream,
                  ),
                ),
              ),

              // Bottom control bar
              _buildControlBar(context),
            ],
          ),
        );
      },
    );
  }

  /// Discord-style main content area.
  /// Voice calls: participant avatars in a centered grid.
  /// Video calls / screen shares: video feeds with local PiP.
  Widget _buildMainContent({
    required bool hasRemoteVideo,
    required bool hasLocalVideo,
    WrappedMediaStream? remoteStream,
    WrappedMediaStream? localStream,
  }) {
    if (hasRemoteVideo) {
      return LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(
              child: VideoRenderer(
                remoteStream!,
                mirror: false,
                fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              ),
            ),
            if (hasLocalVideo)
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  // Keep the self-view proportional to the panel.
                  width: (constraints.maxHeight * 0.42).clamp(120.0, 240.0),
                  height:
                      (constraints.maxHeight * 0.42).clamp(120.0, 240.0) * 0.75,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: DraculaColors.currentLine,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: VideoRenderer(
                    localStream!,
                    mirror: true,
                    fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Voice call or video call with no remote video yet —
    // Discord-style avatar tiles for both participants, scaled to the panel.
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSize =
            (constraints.maxHeight * 0.45).clamp(88.0, 176.0).toDouble();
        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 32,
            runSpacing: 16,
            children: [
              _ParticipantAvatar(
                avatarUrl: controller.avatarUrl,
                name: controller.displayName,
                isMuted:
                    controller.call.remoteUserMediaStream?.audioMuted ?? false,
                isSpeaking: controller.isConnected,
                client: controller.client,
                size: tileSize,
              ),
              _ParticipantAvatar(
                avatarUrl: null,
                name: controller.client.userID?.localpart ?? 'You',
                isMuted: controller.isMicrophoneMuted,
                isSpeaking: false,
                isLocal: true,
                client: controller.client,
                size: tileSize,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlBar(BuildContext context) {
    final canScreenshare = PlatformInfos.isWeb || PlatformInfos.isDesktop;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: DraculaColors.currentLine.withValues(alpha: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FloatingControlButton(
            icon: controller.isMicrophoneMuted
                ? FontAwesomeIcons.microphoneSlash
                : FontAwesomeIcons.microphone,
            color: controller.isMicrophoneMuted
                ? DraculaColors.red
                : DraculaColors.foreground,
            bgColor: controller.isMicrophoneMuted
                ? DraculaColors.red.withValues(alpha: 0.2)
                : DraculaColors.background.withValues(alpha: 0.5),
            onTap: controller.toggleMicrophone,
            tooltip: controller.isMicrophoneMuted ? 'Unmute' : 'Mute',
          ),
          if (controller.isVideoCall) ...[
            const SizedBox(width: 8),
            _FloatingControlButton(
              icon: controller.isLocalVideoMuted
                  ? FontAwesomeIcons.videoSlash
                  : FontAwesomeIcons.video,
              color: controller.isLocalVideoMuted
                  ? DraculaColors.red
                  : DraculaColors.foreground,
              bgColor: controller.isLocalVideoMuted
                  ? DraculaColors.red.withValues(alpha: 0.2)
                  : DraculaColors.background.withValues(alpha: 0.5),
              onTap: controller.toggleCamera,
              tooltip: controller.isLocalVideoMuted
                  ? 'Turn on camera'
                  : 'Turn off camera',
            ),
          ],
          if (canScreenshare && controller.isConnected) ...[
            const SizedBox(width: 8),
            _FloatingControlButton(
              icon: FontAwesomeIcons.display,
              color: controller.isScreensharingEnabled
                  ? DraculaColors.green
                  : DraculaColors.foreground,
              bgColor: controller.isScreensharingEnabled
                  ? DraculaColors.green.withValues(alpha: 0.2)
                  : DraculaColors.background.withValues(alpha: 0.5),
              onTap: controller.toggleScreenshare,
              tooltip: controller.isScreensharingEnabled
                  ? 'Stop sharing'
                  : 'Share your screen',
            ),
          ],
          const SizedBox(width: 20),
          // Hang up (red)
          Tooltip(
            message: 'Disconnect',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  controller.hangUp();
                  onMinimize?.call();
                },
                borderRadius: BorderRadius.zero,
                child: Container(
                  width: 52,
                  height: 36,
                  alignment: Alignment.center,
                  color: DraculaColors.red,
                  child: const FaIcon(
                    FontAwesomeIcons.phoneSlash,
                    color: DraculaColors.foreground,
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingControlButton extends StatelessWidget {
  final FaIconData icon;
  final Color color;
  final Color? bgColor;
  final VoidCallback? onTap;
  final String tooltip;
  final double size;

  const _FloatingControlButton({
    required this.icon,
    required this.color,
    this.bgColor,
    required this.onTap,
    required this.tooltip,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.zero,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: bgColor ?? DraculaColors.background.withValues(alpha: 0.5),
            ),
            child: FaIcon(icon, color: color, size: size * 0.38),
          ),
        ),
      ),
    );
  }
}

/// Discord-style participant avatar tile with name label and mute indicator.
class _ParticipantAvatar extends StatelessWidget {
  final Uri? avatarUrl;
  final String name;
  final bool isMuted;
  final bool isSpeaking;
  final bool isLocal;
  final Client client;
  final double size;

  const _ParticipantAvatar({
    required this.avatarUrl,
    required this.name,
    required this.isMuted,
    required this.client,
    this.isSpeaking = false,
    this.isLocal = false,
    this.size = 88,
  });

  @override
  Widget build(BuildContext context) {
    // Border (3) + padding (3) on each side around the inner avatar.
    final avatarSize = size - 12;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            border: Border.all(
              color: isSpeaking ? DraculaColors.green : Colors.transparent,
              width: 3,
            ),
            boxShadow: isSpeaking
                ? [
                    BoxShadow(
                      color: DraculaColors.green.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: isLocal
                ? FutureBuilder(
                    future: client.fetchOwnProfile(),
                    builder: (context, snapshot) {
                      return Avatar(
                        mxContent: snapshot.data?.avatarUrl,
                        name:
                            snapshot.data?.displayName ??
                            client.userID?.localpart ??
                            'You',
                        size: avatarSize,
                        client: client,
                      );
                    },
                  )
                : Avatar(
                    mxContent: avatarUrl,
                    name: name,
                    size: avatarSize,
                    client: client,
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: size + 12,
          child: Text(
            isLocal ? 'You' : name,
            style: const TextStyle(
              color: DraculaColors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        if (isMuted)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.microphoneSlash,
                color: DraculaColors.red,
                size: 10,
              ),
              SizedBox(width: 4),
              Text(
                'Muted',
                style: TextStyle(
                  color: DraculaColors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global convenience widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Renders the Discord-style sidebar call bar when a call is active.
/// Drop this into any sidebar [Column].
class GlobalCallSidebar extends StatelessWidget {
  const GlobalCallSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix.of(context);
    return ValueListenableBuilder<ActiveCallController?>(
      valueListenable: matrix.activeCallNotifier,
      builder: (context, controller, _) {
        if (controller == null) return const SizedBox.shrink();
        return CallSidebarPanel(
          // Rebuild the panel from scratch for each new call.
          key: ValueKey(controller.callId),
          controller: controller,
          onExpand: () => matrix.callExpandedNotifier.value = true,
        );
      },
    );
  }
}

/// Renders the expanded call panel above the chat content when a call is
/// active and the panel is expanded.
class GlobalCallFloatingPanel extends StatelessWidget {
  const GlobalCallFloatingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix.of(context);
    return ValueListenableBuilder<ActiveCallController?>(
      valueListenable: matrix.activeCallNotifier,
      builder: (context, controller, _) {
        if (controller == null) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: matrix.callExpandedNotifier,
          builder: (context, isExpanded, _) {
            if (!isExpanded) return const SizedBox.shrink();
            return CallFloatingPanel(
              key: ValueKey(controller.callId),
              controller: controller,
              onMinimize: () => matrix.callExpandedNotifier.value = false,
            );
          },
        );
      },
    );
  }
}

/// Legacy alias — renders the sidebar panel for backward compatibility
/// with route definitions that use GlobalCallBanner.
class GlobalCallBanner extends StatelessWidget {
  const GlobalCallBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlobalCallSidebar();
  }
}
