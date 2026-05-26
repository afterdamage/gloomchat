import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' hide VideoRenderer;
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc_impl
    show navigator;
import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/theme/dracula_colors.dart';
import 'package:afterdamage/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/utils/voip/remote_audio_player.dart';
import 'package:afterdamage/utils/voip/video_renderer.dart';
import 'package:afterdamage/utils/voip_plugin.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/matrix.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Web media helper
// ─────────────────────────────────────────────────────────────────────────────

/// On web, the initial getUserMedia call returns a silent placeholder stream so
/// incoming calls can reach the ringing state before the user grants permission.
/// This helper swaps it out for real media — must be called inside a user-gesture
/// callback (button tap) so the browser allows the permission prompt.
Future<void> _replaceWithRealMedia(
  CallSession call,
  VoipPlugin? voipPlugin,
) async {
  if (!kIsWeb) return;
  final localStream = call.localUserMediaStream;
  final audioTracks = localStream?.stream?.getAudioTracks() ?? [];
  if (audioTracks.isNotEmpty) return; // already have real media

  Logs().i('[VoIP] No audio tracks — requesting real media on user gesture');
  try {
    final realStream = await webrtc_impl.navigator.mediaDevices.getUserMedia(
      <String, dynamic>{
        'audio': true,
        'video': call.type == CallType.kVideo,
      },
    );
    if (realStream.getAudioTracks().isEmpty) {
      Logs().w('[VoIP] getUserMedia returned no audio tracks');
      return;
    }
    if (localStream != null) await call.removeLocalStream(localStream);
    await call.addLocalStream(realStream, SDPStreamMetadataPurpose.Usermedia);
    voipPlugin?.mediaDevicesWrapper?.usedPlaceholder = false;
    Logs().i('[VoIP] Replaced placeholder with real media');
  } catch (e) {
    Logs().e('[VoIP] Failed to get real media: $e');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CallSidebarPanel — compact Discord-style call bar for the navigation sidebar
// ─────────────────────────────────────────────────────────────────────────────

/// A compact call status panel that sits at the bottom of the sidebar,
/// exactly like Discord's "Voice Connected" bar. Shows connection status,
/// room name, duration, and minimal controls. Does NOT obstruct navigation.
class CallSidebarPanel extends StatefulWidget {
  final BuildContext callContext;
  final String callId;
  final CallSession call;
  final Client client;
  final VoidCallback? onClear;
  final VoidCallback? onExpand;

  const CallSidebarPanel({
    required this.callContext,
    required this.callId,
    required this.call,
    required this.client,
    this.onClear,
    this.onExpand,
    super.key,
  });

  @override
  State<CallSidebarPanel> createState() => _CallSidebarPanelState();
}

class _CallSidebarPanelState extends State<CallSidebarPanel>
    with TickerProviderStateMixin {
  CallSession get call => widget.call;

  String get displayName => call.room.getLocalizedDisplayname(
        MatrixLocals(L10n.of(widget.callContext)),
      );

  bool get voiceonly => call.type == CallType.kVoice;
  bool get connected => call.state == CallState.kConnected;
  bool get isMicrophoneMuted => call.isMicrophoneMuted;
  bool get isLocalVideoMuted => call.isLocalVideoMuted;

  CallState? _state;
  Timer? _durationTimer;
  Duration _callDuration = Duration.zero;
  DateTime? _connectedAt;
  late AnimationController _pulseController;
  // Horizontal shimmy played when an incoming call first rings
  late AnimationController _shimmyController;
  late Animation<double> _shimmyAnimation;
  AudioPlayer? _dialupPlayer;

  @override
  void initState() {
    super.initState();
    _state = call.state;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shimmyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shimmyAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shimmyController, curve: Curves.easeInOut),
    );

    call.onCallStateChanged.stream.listen(_handleCallState);
    call.onCallEventChanged.stream.listen((event) {
      if (event == CallStateChange.kFeedsChanged) {
        setState(() => call.tryRemoveStopedStreams());
      }
    });

    // Play dial-up tone for outgoing calls; shimmy for incoming ringing
    if (call.isOutgoing) {
      _playDialupTone();
    } else if (_state == CallState.kRinging) {
      _shimmyController.forward();
    }
  }

  void _playDialupTone() async {
    if (kIsWeb || PlatformInfos.isMobile || PlatformInfos.isMacOS) {
      try {
        final player = AudioPlayer();
        _dialupPlayer = player;
        await player.setAsset('assets/sounds/dialup.ogg');
        await player.play();
      } catch (e) {
        Logs().w('Failed to play dial-up tone', e);
      }
    }
  }

  void _stopDialupTone() {
    _dialupPlayer?.stop();
    _dialupPlayer?.dispose();
    _dialupPlayer = null;
  }

  void _handleCallState(CallState state) {
    if (!mounted) return;
    // Stop dial-up tone when call connects or ends
    if ({CallState.kConnected, CallState.kEnded}.contains(state)) {
      _stopDialupTone();
    }
    setState(() {
      _state = state;
      if (state == CallState.kConnected && _connectedAt == null) {
        _connectedAt = DateTime.now();
        _pulseController.stop();
        _pulseController.value = 1.0;
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {
            _callDuration = DateTime.now().difference(_connectedAt!);
          });
        });
        // Auto-expand the floating call window on connect
        widget.onExpand?.call();
      }
      if (state == CallState.kEnded) {
        _durationTimer?.cancel();
        _pulseController.stop();
        Timer(const Duration(seconds: 2), () => widget.onClear?.call());
      }
    });
  }

  @override
  void dispose() {
    _stopDialupTone();
    _durationTimer?.cancel();
    _pulseController.dispose();
    _shimmyController.dispose();
    super.dispose();
  }

  void _answerCall() async {
    await _replaceWithRealMedia(call, Matrix.of(widget.callContext).voipPlugin);
    try {
      await call.answer();
    } catch (e) {
      Logs().w('[CallSidebarPanel] Error answering call (likely 429): $e');
    }
    if (mounted) setState(() {});
  }

  void _hangUp() {
    setState(() {
      if (call.isRinging) {
        call.reject();
      } else {
        call.hangup(reason: CallErrorCode.userHangup);
      }
    });
  }

  void _muteMic() async {
    await _replaceWithRealMedia(call, Matrix.of(widget.callContext).voipPlugin);
    try {
      await call.setMicrophoneMuted(!call.isMicrophoneMuted);
    } catch (e) {
      Logs().w('[CallSidebarPanel] setMicrophoneMuted error (likely 429): $e');
    }
    if (mounted) setState(() {});
  }

  void _muteCamera() async {
    try {
      await call.setLocalVideoMuted(!call.isLocalVideoMuted);
    } catch (e) {
      Logs().w('[CallSidebarPanel] setLocalVideoMuted error (likely 429): $e');
    }
    if (mounted) setState(() {});
  }

  String get _statusText {
    switch (_state) {
      case CallState.kRinging:
        return call.isOutgoing ? 'Ringing...' : 'Incoming Call';
      case CallState.kInviteSent:
        return 'Calling...';
      case CallState.kCreateAnswer:
      case CallState.kConnecting:
        return 'Connecting...';
      case CallState.kConnected:
        return voiceonly ? 'Voice Connected' : 'Video Connected';
      case CallState.kEnded:
        return 'Call Ended';
      default:
        return 'Setting up...';
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  Color get _statusColor {
    switch (_state) {
      case CallState.kConnected:
        return DraculaColors.green;
      case CallState.kEnded:
        return DraculaColors.red;
      case CallState.kRinging:
        return DraculaColors.yellow;
      default:
        return DraculaColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRinging = _state == CallState.kRinging && !call.isOutgoing;
    final isConnected = _state == CallState.kConnected;
    final isEnded = _state == CallState.kEnded;

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
        // Hidden audio player for remote audio on web
        RemoteAudioPlayer(call: call),

        // Separator
        Container(
          height: 1,
          color: DraculaColors.currentLine,
        ),

        // Main call panel
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isEnded
                ? DraculaColors.background
                : isConnected
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
                                      color:
                                          _statusColor.withValues(alpha: 0.4),
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
                    // Status text
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
                    // Duration
                    if (isConnected)
                      Text(
                        _formatDuration(_callDuration),
                        style: TextStyle(
                          color: DraculaColors.muted,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
              ),

              // Room name
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 2, 12, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayName,
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
                        bgColor: DraculaColors.green.withValues(alpha: 0.15),
                        onTap: _answerCall,
                        tooltip: 'Answer',
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Hang up / Decline — always left-aligned,
                    // right next to Answer when ringing
                    _SidebarControlButton(
                      icon: FontAwesomeIcons.phoneSlash,
                      color: DraculaColors.foreground,
                      bgColor: DraculaColors.red,
                      onTap: _hangUp,
                      tooltip: isRinging ? 'Decline' : 'Disconnect',
                      wide: true,
                    ),

                    // Mic toggle
                    if (isConnected) ...[
                      const SizedBox(width: 8),
                      _SidebarControlButton(
                        icon: isMicrophoneMuted
                            ? FontAwesomeIcons.microphoneSlash
                            : FontAwesomeIcons.microphone,
                        color: isMicrophoneMuted
                            ? DraculaColors.red
                            : DraculaColors.foreground.withValues(alpha: 0.7),
                        bgColor: isMicrophoneMuted
                            ? DraculaColors.red.withValues(alpha: 0.15)
                            : DraculaColors.currentLine.withValues(alpha: 0.6),
                        onTap: _muteMic,
                        tooltip: isMicrophoneMuted ? 'Unmute' : 'Mute',
                      ),
                    ],

                    // Camera toggle (video calls only)
                    if (isConnected && !voiceonly) ...[
                      const SizedBox(width: 4),
                      _SidebarControlButton(
                        icon: isLocalVideoMuted
                            ? FontAwesomeIcons.videoSlash
                            : FontAwesomeIcons.video,
                        color: isLocalVideoMuted
                            ? DraculaColors.red
                            : DraculaColors.foreground.withValues(alpha: 0.7),
                        bgColor: isLocalVideoMuted
                            ? DraculaColors.red.withValues(alpha: 0.15)
                            : DraculaColors.currentLine.withValues(alpha: 0.6),
                        onTap: _muteCamera,
                        tooltip: isLocalVideoMuted
                            ? 'Turn on camera'
                            : 'Turn off camera',
                      ),
                    ],

                    const Spacer(),

                    // Expand / pop-out button
                    if (isConnected) ...[
                      _SidebarControlButton(
                        icon: FontAwesomeIcons.upRightAndDownLeftFromCenter,
                        color: DraculaColors.foreground.withValues(alpha: 0.7),
                        bgColor:
                            DraculaColors.currentLine.withValues(alpha: 0.6),
                        onTap: widget.onExpand,
                        tooltip: 'Expand call',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
        ),  // Column
      ),  // AnimatedSize
    );  // AnimatedBuilder
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
// CallTopPanel — fixed call panel that sits on top of the chat area
// ─────────────────────────────────────────────────────────────────────────────

/// A fixed panel that shows the call view (video feeds + avatars + controls)
/// at the top of the chat content area, like Discord. Does NOT float or drag;
/// it sits above the chat messages and can be collapsed back to sidebar-only.
class CallFloatingPanel extends StatefulWidget {
  final BuildContext callContext;
  final CallSession call;
  final Client client;
  final VoidCallback? onMinimize;

  const CallFloatingPanel({
    required this.callContext,
    required this.call,
    required this.client,
    this.onMinimize,
    super.key,
  });

  @override
  State<CallFloatingPanel> createState() => _CallFloatingPanelState();
}

class _CallFloatingPanelState extends State<CallFloatingPanel> {
  CallSession get call => widget.call;

  bool get isMicrophoneMuted => call.isMicrophoneMuted;
  bool get isLocalVideoMuted => call.isLocalVideoMuted;
  bool get voiceonly => call.type == CallType.kVoice;

  String get displayName => call.room.getLocalizedDisplayname(
        MatrixLocals(L10n.of(widget.callContext)),
      );

  StreamSubscription? _stateSub;
  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _eventSub = call.onCallEventChanged.stream.listen((event) {
      if (event == CallStateChange.kFeedsChanged) {
        setState(() => call.tryRemoveStopedStreams());
      }
    });
    _stateSub = call.onCallStateChanged.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }

  String get _remoteDisplayName {
    if (call.room.isDirectChat) {
      final other = call.room.unsafeGetUserFromMemoryOrFallback(
        call.room.directChatMatrixID ?? '',
      );
      return other.displayName ?? other.id;
    }
    return displayName;
  }

  Uri? get _remoteAvatarUrl {
    if (call.room.isDirectChat) {
      final other = call.room.unsafeGetUserFromMemoryOrFallback(
        call.room.directChatMatrixID ?? '',
      );
      return other.avatarUrl;
    }
    return null;
  }

  // Local avatar is fetched inside _ParticipantAvatar via FutureBuilder.

  @override
  Widget build(BuildContext context) {
    final remoteStream =
        call.remoteUserMediaStream ?? call.remoteScreenSharingStream;
    final localStream = call.localUserMediaStream;
    final isConnected = call.state == CallState.kConnected;
    final hasRemoteVideo = remoteStream != null && !remoteStream.videoMuted;
    final hasLocalVideo = localStream != null && !isLocalVideoMuted;

    // Fixed height panel that sits at the top of the chat area
    const panelHeight = 320.0;

    return Container(
      width: double.infinity,
      height: panelHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E),
        border: Border(
          bottom: BorderSide(
            color: DraculaColors.currentLine,
            width: 1,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Title bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: DraculaColors.currentLine.withValues(alpha: 0.8),
            ),
            child: Row(
              children: [
                FaIcon(
                  voiceonly
                      ? FontAwesomeIcons.phone
                      : FontAwesomeIcons.video,
                  color: DraculaColors.green,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      color: DraculaColors.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Minimize button
                _FloatingControlButton(
                  icon: FontAwesomeIcons.chevronUp,
                  color: DraculaColors.foreground.withValues(alpha: 0.7),
                  onTap: widget.onMinimize,
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
                isConnected: isConnected,
                hasRemoteVideo: hasRemoteVideo,
                hasLocalVideo: hasLocalVideo,
                remoteStream: remoteStream,
                localStream: localStream,
              ),
            ),
          ),

          // Bottom control bar
          _buildControlBar(),
        ],
      ),
    );
  }

  /// Discord/Slack-style main content area.
  /// Voice calls: shows participant avatars in a centered grid.
  /// Video calls: shows video feeds with PiP.
  Widget _buildMainContent({
    required bool isConnected,
    required bool hasRemoteVideo,
    required bool hasLocalVideo,
    WrappedMediaStream? remoteStream,
    WrappedMediaStream? localStream,
  }) {
    // If it's a video call and we have remote video, show video feeds
    if (!voiceonly && hasRemoteVideo) {
      return Stack(
        children: [
          Positioned.fill(
            child: VideoRenderer(
              remoteStream!,
              mirror: false,
              fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            ),
          ),
          // Local video PiP
          if (hasLocalVideo)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                width: 120,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.zero,
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
      );
    }

    // Voice call or video call with no video yet —
    // show Discord-style avatar circles for participants
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 32,
        runSpacing: 16,
        children: [
          // Remote participant
          _ParticipantAvatar(
            avatarUrl: _remoteAvatarUrl,
            name: _remoteDisplayName,
            isMuted: call.remoteUserMediaStream?.audioMuted ?? false,
            isSpeaking: isConnected,
            client: widget.client,
          ),
          // Local participant (you) — avatar and name loaded via FutureBuilder inside _ParticipantAvatar
          _ParticipantAvatar(
            avatarUrl: null,
            name: widget.client.userID?.localpart ?? 'You',
            isMuted: isMicrophoneMuted,
            isSpeaking: false,
            isLocal: true,
            client: widget.client,
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: DraculaColors.currentLine.withValues(alpha: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FloatingControlButton(
            icon: isMicrophoneMuted
                ? FontAwesomeIcons.microphoneSlash
                : FontAwesomeIcons.microphone,
            color: isMicrophoneMuted
                ? DraculaColors.red
                : DraculaColors.foreground,
            bgColor: isMicrophoneMuted
                ? DraculaColors.red.withValues(alpha: 0.2)
                : DraculaColors.background.withValues(alpha: 0.5),
            onTap: () async {
              await _replaceWithRealMedia(
                call,
                Matrix.of(widget.callContext).voipPlugin,
              );
              try {
                await call.setMicrophoneMuted(!call.isMicrophoneMuted);
              } catch (e) {
                Logs().w('[CallFloatingPanel] setMicrophoneMuted error: $e');
              }
              if (mounted) setState(() {});
            },
            tooltip: isMicrophoneMuted ? 'Unmute' : 'Mute',
          ),
          if (!voiceonly) ...[
            const SizedBox(width: 8),
            _FloatingControlButton(
              icon: isLocalVideoMuted
                  ? FontAwesomeIcons.videoSlash
                  : FontAwesomeIcons.video,
              color: isLocalVideoMuted
                  ? DraculaColors.red
                  : DraculaColors.foreground,
              bgColor: isLocalVideoMuted
                  ? DraculaColors.red.withValues(alpha: 0.2)
                  : DraculaColors.background.withValues(alpha: 0.5),
              onTap: () async {
                try {
                  await call.setLocalVideoMuted(!call.isLocalVideoMuted);
                } catch (e) {
                  Logs().w('[CallFloatingPanel] setLocalVideoMuted error: $e');
                }
                if (mounted) setState(() {});
              },
              tooltip:
                  isLocalVideoMuted ? 'Turn on camera' : 'Turn off camera',
            ),
          ],
          const SizedBox(width: 20),
          // Hang up (pill shaped, red)
          Tooltip(
            message: 'Disconnect',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  call.hangup(reason: CallErrorCode.userHangup);
                  widget.onMinimize?.call();
                },
                borderRadius: BorderRadius.zero,
                child: Container(
                  width: 52,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    color: DraculaColors.red,
                  ),
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
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: bgColor ??
                  DraculaColors.background.withValues(alpha: 0.5),
            ),
            child: FaIcon(icon, color: color, size: size * 0.38),
          ),
        ),
      ),
    );
  }
}

/// Discord-style participant avatar circle with name label and mute indicator.
class _ParticipantAvatar extends StatelessWidget {
  final Uri? avatarUrl;
  final String name;
  final bool isMuted;
  final bool isSpeaking;
  final bool isLocal;
  final Client client;

  const _ParticipantAvatar({
    required this.avatarUrl,
    required this.name,
    required this.isMuted,
    required this.client,
    this.isSpeaking = false,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with speaking ring
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            border: Border.all(
              color: isSpeaking
                  ? DraculaColors.green
                  : Colors.transparent,
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
                        name: snapshot.data?.displayName ??
                            client.userID?.localpart ??
                            'You',
                        size: 76,
                        client: client,
                      );
                    },
                  )
                : Avatar(
                    mxContent: avatarUrl,
                    name: name,
                    size: 76,
                    client: client,
                  ),
          ),
        ),
        const SizedBox(height: 10),
        // Name
        SizedBox(
          width: 100,
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
        // Mute indicator
        if (isMuted)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.microphoneSlash,
                color: DraculaColors.red,
                size: 10,
              ),
              const SizedBox(width: 4),
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

/// Convenience widget that listens to VoIP plugin's [activeCallNotifier]
/// and renders a [CallSidebarPanel] when a call is active.
///
/// Drop this into any sidebar [Column] to show the call bar inline.
class GlobalCallSidebar extends StatelessWidget {
  const GlobalCallSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final voipPlugin = Matrix.of(context).voipPlugin;
    if (voipPlugin == null) return const SizedBox.shrink();

    return ValueListenableBuilder<ActiveCallState?>(
      valueListenable: voipPlugin.activeCallNotifier,
      builder: (ctx, activeCall, _) {
        if (activeCall == null) return const SizedBox.shrink();
        return CallSidebarPanel(
          callContext: ctx,
          callId: activeCall.callId,
          call: activeCall.call,
          client: activeCall.client,
          onClear: () {
            voipPlugin.activeCallNotifier.value = null;
          },
          onExpand: () {
            voipPlugin.callExpandedNotifier.value = true;
          },
        );
      },
    );
  }
}

/// Convenience widget that shows the expanded call panel above the chat content.
///
/// Place this inside a [Column] above the chat/content area so it appears
/// at the top of the chat section without blocking navigation.
class GlobalCallFloatingPanel extends StatelessWidget {
  const GlobalCallFloatingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final voipPlugin = Matrix.of(context).voipPlugin;
    if (voipPlugin == null) return const SizedBox.shrink();

    return ValueListenableBuilder<ActiveCallState?>(
      valueListenable: voipPlugin.activeCallNotifier,
      builder: (ctx, activeCall, _) {
        if (activeCall == null) return const SizedBox.shrink();

        return ValueListenableBuilder<bool>(
          valueListenable: voipPlugin.callExpandedNotifier,
          builder: (ctx2, isExpanded, _) {
            if (!isExpanded) return const SizedBox.shrink();

            return CallFloatingPanel(
              callContext: ctx2,
              call: activeCall.call,
              client: activeCall.client,
              onMinimize: () {
                voipPlugin.callExpandedNotifier.value = false;
              },
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
