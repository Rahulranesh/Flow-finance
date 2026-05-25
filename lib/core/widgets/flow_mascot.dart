import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';
import '../theme/app_animations.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

class FlowMascotBubble extends StatelessWidget {
  const FlowMascotBubble({
    super.key,
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard.highlighted(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FlowMascotAvatar(size: 54),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTypography.bodyMedium(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FlowMascotAvatar extends StatefulWidget {
  const FlowMascotAvatar({super.key, this.size = 72, this.celebrating = false});

  final double size;
  final bool celebrating;

  @override
  State<FlowMascotAvatar> createState() => _FlowMascotAvatarState();
}

class _FlowMascotAvatarState extends State<FlowMascotAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bounce = Curves.easeInOut.transform(_controller.value);
        final tilt = math.sin(_controller.value * math.pi * 2) * 0.03;

        return Transform.translate(
          offset: Offset(0, -4 * bounce),
          child: Transform.rotate(
            angle: tilt,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Lottie.asset(
                'assets/mascot.json',
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),
            ),
          ),
        );
      },
    );
  }
}

class FlowGuideChip extends StatelessWidget {
  const FlowGuideChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
      selectedColor: AppColors.primary.withOpacity(0.12),
      labelStyle: AppTypography.labelMedium(
        color: selected ? AppColors.primary : AppColors.textSecondary(context),
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border(context),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
    );
  }
}
