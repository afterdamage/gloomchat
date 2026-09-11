import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:afterdamage/theme/dracula_colors.dart';
import 'package:afterdamage/utils/voip/active_call_controller.dart';
import 'package:afterdamage/widgets/avatar.dart';

/// Compact notification card for incoming calls on wide desktop/web layouts.
///
/// Slides in from the bottom-right corner (like a Discord call toast) while
/// the call is ringing. Once the call leaves the ringing state the card
/// slides back out — the sidebar panel takes over for connected calls.
class IncomingCallCard extends StatefulWidget {
  final ActiveCallController controller;

  /// Called when the card should be removed (call answered, declined, ended).
  final VoidCallback? onDismiss;

  /// Called after the user answers from this card (e.g. to expand the panel).
  final VoidCallback? onAnswered;

  const IncomingCallCard({
    required this.controller,
    this.onDismiss,
    this.onAnswered,
    super.key,
  });

  @override
  State<IncomingCallCard> createState() => _IncomingCallCardState();
}

class _IncomingCallCardState extends State<IncomingCallCard>
    with TickerProviderStateMixin {
  ActiveCallController get controller => widget.controller;

  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _pulseController;

  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _slideController, curve: Curves.easeOut);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _slideController.forward();
    HapticFeedback.heavyImpact();

    controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    // Any non-ringing state means the call was answered or ended — dismiss.
    if (!controller.isIncomingRinging) {
      _dismiss();
    }
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
    controller.removeListener(_onControllerChanged);
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _answer() async {
    HapticFeedback.mediumImpact();
    await controller.answer();
    widget.onAnswered?.call();
    _dismiss();
  }

  Future<void> _decline() async {
    HapticFeedback.mediumImpact();
    await controller.reject();
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
                  controller.isVideoCall
                      ? FontAwesomeIcons.video
                      : FontAwesomeIcons.phone,
                  color: DraculaColors.green,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  controller.isVideoCall
                      ? 'Incoming video call'
                      : 'Incoming voice call',
                  style: const TextStyle(
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
                      mxContent: controller.avatarUrl,
                      name: controller.displayName,
                      size: 52,
                      client: controller.client,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.displayName,
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
                        controller.call.room.getLocalizedDisplayname(),
                        style: const TextStyle(
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
  final FaIconData icon;
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
