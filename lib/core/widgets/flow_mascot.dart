import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

// ─── Mascot Bubble ────────────────────────────────────────────────────────────

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
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FlowMascotAvatar(size: 58),
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
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onAction,
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

// ─── Particle dot ─────────────────────────────────────────────────────────────

class _Particle {
  _Particle({required this.angle, required this.radius, required this.size, required this.phase});
  final double angle;
  final double radius;
  final double size;
  final double phase;
}

// ─── Main Avatar ──────────────────────────────────────────────────────────────

class FlowMascotAvatar extends StatefulWidget {
  const FlowMascotAvatar({
    super.key,
    this.size = 72,
    this.celebrating = false,
    this.showGlow = true,
    this.showParticles = false,
  });

  final double size;
  final bool celebrating;
  final bool showGlow;
  final bool showParticles;

  @override
  State<FlowMascotAvatar> createState() => _FlowMascotAvatarState();
}

class _FlowMascotAvatarState extends State<FlowMascotAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _particleCtrl;

  // Pre-built particle list so we don't rebuild each frame
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    final rng = math.Random(42);
    _particles = List.generate(8, (i) {
      return _Particle(
        angle: (i / 8) * math.pi * 2,
        radius: widget.size * 0.62 + rng.nextDouble() * widget.size * 0.18,
        size: 3.0 + rng.nextDouble() * 4.0,
        phase: rng.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return SizedBox(
      width: s * 1.5,
      height: s * 1.5,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatCtrl, _glowCtrl, _shimmerCtrl, _particleCtrl]),
        builder: (context, _) {
          final t = _floatCtrl.value;
          final floatY = math.sin(t * math.pi * 2) * s * 0.08;
          final angleY = math.sin(t * math.pi * 2) * 0.22;
          final angleX = math.cos(t * math.pi * 2) * 0.10;
          final glowPulse = 0.5 + _glowCtrl.value * 0.5;
          final shimmerX = _shimmerCtrl.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              // ── Outer glow ring ──────────────────────────────────────────
              if (widget.showGlow)
                Container(
                  width: s * 1.0,
                  height: s * 1.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                  ),
                ),

              // ── Orbit particles ──────────────────────────────────────────
              if (widget.showParticles || widget.celebrating)
                ..._particles.map((p) {
                  final phase = (_particleCtrl.value + p.phase) % 1.0;
                  final orbitAngle = p.angle + _particleCtrl.value * math.pi * 2;
                  final px = math.cos(orbitAngle) * p.radius;
                  final py = math.sin(orbitAngle) * p.radius * 0.45; // ellipse
                  final opacity = (math.sin(phase * math.pi * 2) * 0.5 + 0.5) * 0.8;
                  return Positioned(
                    left: s * 0.75 + px - p.size / 2,
                    top: s * 0.75 + py - p.size / 2,
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (p.phase < 0.5 ? AppColors.primary : AppColors.secondary)
                            .withOpacity(opacity),
                      ),
                    ),
                  );
                }),

              // ── 3D transformed lottie ────────────────────────────────────
              Transform.translate(
                offset: Offset(0, floatY),
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateX(angleX)
                    ..rotateY(angleY),
                  alignment: FractionalOffset.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle ground shadow
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: s * 0.6,
                          height: s * 0.08,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(s),
                            color: AppColors.primary.withOpacity(0.08 + 0.07 * (floatY / (s * 0.08 + 0.001)).abs()),
                          ),
                        ),
                      ),
                      // Lottie avatar
                      SizedBox(
                        width: s,
                        height: s,
                        child: Lottie.asset(
                          'assets/mascot.json',
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                        ),
                      ),
                      // Shimmer overlay
                      ClipRRect(
                        borderRadius: BorderRadius.circular(s),
                        child: SizedBox(
                          width: s,
                          height: s,
                          child: CustomPaint(
                            painter: _ShimmerPainter(shimmerX),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Shimmer paint ────────────────────────────────────────────────────────────

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerX = -size.width + progress * size.width * 3;
    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        Colors.white.withOpacity(0.08),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment(-2 + progress * 4, -1),
      end: Alignment(-1 + progress * 4, 1),
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(shimmerX, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ─── Guide Chip ───────────────────────────────────────────────────────────────

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border(context),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium(
            color: selected ? AppColors.primary : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}
