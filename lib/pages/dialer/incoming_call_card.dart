import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc_impl
    show navigator;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/theme/dracula_colors.dart';
import 'package:afterdamage/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/matrix.dart';

/// Compact notification card for incoming calls on web desktop.
///
/// Slides in from the bottom-right corner (like a system notification) when
/// a call is ringing. Once the call transitions out of the ringing state the
/// card slides back out — the sidebar panel takes over for connected calls.
class IncomingCallCard extends StatefulWidget {
  final CallSession call;
  final Client client;

  /// Called when the card should be removed (call answered, declined, or timed out).
  final VoidCallback? onDismiss;

  const IncomingCallCard({
    required this.call,
    required this.client,
    this.onDismiss,
    super.key,
  });

  @override
  State<IncomingCallCard> createState() => _IncomingCallCardState();
}

class _IncomingCallCardState extends State<IncomingCallCard>
    with TickerProviderStateMixin {
  CallSession get call => widget.call;

  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  StreamSubscription? _stateSub;
  bool _dismissing = false;

  // Pulse animation for the ringing ring
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(parent: _slideController, curve: Curves.easeOut);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // Slide in immediately
    _slideController.forward();

    // Vibrate to notify user of incoming call
    HapticFeedback.heavyImpact();

    _stateSub = call.onCallStateChanged.stream.listen(_onStateChanged);
  }

  void _onStateChanged(CallState state) {
    if (state == CallState.kRinging) return; // stay visible
    // Any non-ringing state means the call was answered or ended — dismiss.
    _dismiss();
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _slideController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String get _callerName {
    if (call.room.isDirectChat) {
      final userId = call.room.directChatMatrixID ?? '';
      final user = call.room.unsafeGetUserFromMemoryOrFallback(userId);
      return user.displayName ?? user.id;
    }
    return call.room.getLocalizedDisplayname(MatrixLocals(L10n.of(context)));
  }

  Uri? get _callerAvatar {
    if (call.room.isDirectChat) {
      final userId = call.room.directChatMatrixID ?? '';
      return call.room.unsafeGetUserFromMemoryOrFallback(userId).avatarUrl;
    }
    return null;
  }

  bool get _isVideoCall => call.type == CallType.kVideo;

  Future<void> _answer() async {
    HapticFeedback.mediumImpact();
    if (kIsWeb) {
      try {
        final constraints = <String, dynamic>{
          'audio': true,
          'video': _isVideoCall,
        };
        final realStream =
            await webrtc_impl.navigator.mediaDevices.getUserMedia(constraints);
        final audioTracks = realStream.getAudioTracks();
        if (audioTracks.isNotEmpty) {
          final placeholder = call.localUserMediaStream;
          if (placeholder != null) await call.removeLocalStream(placeholder);
          await call.addLocalStream(realStream, SDPStreamMetadataPurpose.Usermedia);
          final voipPlugin = Matrix.of(context).voipPlugin;
          voipPlugin?.mediaDevicesWrapper?.usedPlaceholder = false;
        }
      } catch (e) {
        Logs().w('[IncomingCallCard] Failed to get real media: $e');
      }
    }
    try {
      await call.answer();
    } catch (e) {
      Logs().w('[IncomingCallCard] answer error: $e');
    }
    _dismiss();
  }

  void _decline() {
    HapticFeedback.mediumImpact();
    try {
      call.reject();
    } catch (e) {
      Logs().w('[IncomingCallCard] reject error: $e');
    }
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.zero,
      color: const Color(0xFF1E1F2E),
      shadowColor: Colors.black54,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: DraculaColors.green.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                FaIcon(
                  _isVideoCall ? FontAwesomeIcons.video : FontAwesomeIcons.phone,
                  color: DraculaColors.green,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  _isVideoCall ? 'Incoming video call' : 'Incoming voice call',
                  style: TextStyle(
                    color: DraculaColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                // Pulsing green dot
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DraculaColors.green.withValues(
                          alpha: 0.5 + _pulseController.value * 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DraculaColors.green.withValues(
                              alpha: _pulseController.value * 0.5,
                            ),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Avatar + name row
            Row(
              children: [
                // Avatar with animated ring
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) {
                    return Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: DraculaColors.green.withValues(
                            alpha: (1.0 - _pulseController.value) * 0.8,
                          ),
                          width: 2 + _pulseController.value * 1.5,
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: ClipOval(
                    child: Avatar(
                      mxContent: _callerAvatar,
                      name: _callerName,
                      size: 52,
                      client: widget.client,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _callerName,
                        style: const TextStyle(
                          color: DraculaColors.foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        call.room.getLocalizedDisplayname(
                          MatrixLocals(L10n.of(context)),
                        ),
                        style: TextStyle(
                          color: DraculaColors.muted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Answer / Decline buttons
            Row(
              children: [
                Expanded(
                  child: _CardButton(
                    label: 'Decline',
                    icon: FontAwesomeIcons.phoneSlash,
                    color: DraculaColors.red,
                    onTap: _decline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CardButton(
                    label: 'Answer',
                    icon: FontAwesomeIcons.phone,
                    color: DraculaColors.green,
                    onTap: _answer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CardButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        splashColor: color.withValues(alpha: 0.3),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, color: color, size: 12),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
