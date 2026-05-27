import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'flow_mascot.dart';
import 'cupertino_toast.dart';

enum MascotSnackBarType { info, success, error, warning }

// ─── Content widget ───────────────────────────────────────────────────────────

class MascotSnackBarContent extends StatefulWidget {
  final String message;
  final MascotSnackBarType type;

  const MascotSnackBarContent({
    super.key,
    required this.message,
    this.type = MascotSnackBarType.info,
  });

  @override
  State<MascotSnackBarContent> createState() => _MascotSnackBarContentState();
}

class _MascotSnackBarContentState extends State<MascotSnackBarContent>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );
  late final AnimationController _shimmerCtrl = AnimationController(
    duration: const Duration(milliseconds: 1600),
    vsync: this,
  );

  late final Animation<double> _scaleAnim = CurvedAnimation(
    parent: _entryCtrl,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _slideAnim = Tween(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _entryCtrl.forward();
    _shimmerCtrl.repeat();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _resolveColors(isDark);

    return AnimatedBuilder(
      animation: Listenable.merge([_entryCtrl, _shimmerCtrl]),
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _slideAnim.value)),
          child: Opacity(
            opacity: _slideAnim.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.bg,
                    colors.bg2,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.accent.withOpacity(0.35),
                  width: 1.2,
                ),

              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    // Shimmer sweep
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SnackShimmerPainter(_shimmerCtrl.value, colors.accent),
                      ),
                    ),
                    // Content row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          // Mascot with 3D float + scale pop
                          ScaleTransition(
                            scale: _scaleAnim,
                            child: FlowMascotAvatar(
                              size: 46,
                              showGlow: true,
                              celebrating: widget.type == MascotSnackBarType.success,
                              showParticles: widget.type == MascotSnackBarType.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Vertical accent bar
                          Container(
                            width: 3,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Message + type icon
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(colors.icon, color: colors.accent, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      _typeLabel(widget.type),
                                      style: AppTypography.labelSmall(
                                        color: colors.accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.message,
                                  style: AppTypography.bodySmall(
                                    color: colors.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ),
        );
      },
    );
  }

  String _typeLabel(MascotSnackBarType type) {
    switch (type) {
      case MascotSnackBarType.success:
        return 'SUCCESS'.tr();
      case MascotSnackBarType.error:
        return 'ERROR'.tr();
      case MascotSnackBarType.warning:
        return 'WARNING'.tr();
      case MascotSnackBarType.info:
        return 'INFO'.tr();
    }
  }

  _SnackColors _resolveColors(bool isDark) {
    switch (widget.type) {
      case MascotSnackBarType.success:
        return _SnackColors(
          bg: isDark ? const Color(0xFF0D2E1A) : const Color(0xFFE8F5E9),
          bg2: isDark ? const Color(0xFF133322) : const Color(0xFFD0EDDA),
          accent: AppColors.success,
          text: isDark ? Colors.white : const Color(0xFF1B5E20),
          icon: CupertinoIcons.checkmark_alt_circle_fill,
        );
      case MascotSnackBarType.error:
        return _SnackColors(
          bg: isDark ? const Color(0xFF2E0D0D) : const Color(0xFFFFEBEE),
          bg2: isDark ? const Color(0xFF3A1010) : const Color(0xFFFFD6D6),
          accent: AppColors.error,
          text: isDark ? Colors.white : const Color(0xFFB71C1C),
          icon: CupertinoIcons.exclamationmark_circle_fill,
        );
      case MascotSnackBarType.warning:
        return _SnackColors(
          bg: isDark ? const Color(0xFF2E220D) : const Color(0xFFFFF8E1),
          bg2: isDark ? const Color(0xFF3A2C10) : const Color(0xFFFFECB3),
          accent: const Color(0xFFF59E0B),
          text: isDark ? Colors.white : const Color(0xFF78350F),
          icon: CupertinoIcons.exclamationmark_triangle_fill,
        );
      case MascotSnackBarType.info:
        return _SnackColors(
          bg: isDark ? const Color(0xFF0D1A2E) : const Color(0xFFE3F2FD),
          bg2: isDark ? const Color(0xFF10223A) : const Color(0xFFBBDEFB),
          accent: AppColors.primary,
          text: isDark ? Colors.white : const Color(0xFF0D47A1),
          icon: CupertinoIcons.info_circle_fill,
        );
    }
  }
}

// ─── Shimmer painter ──────────────────────────────────────────────────────────

class _SnackShimmerPainter extends CustomPainter {
  _SnackShimmerPainter(this.progress, this.accent);
  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final sweep = progress * (size.width + size.width * 0.6) - size.width * 0.3;
    final gradient = LinearGradient(
      colors: [Colors.transparent, accent.withOpacity(0.06), Colors.transparent],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment((-1.0 + progress * 3), -1),
      end: Alignment((progress * 3), 1),
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(sweep, 0, size.width * 0.5, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_SnackShimmerPainter old) => old.progress != progress;
}

// ─── Color data ───────────────────────────────────────────────────────────────

class _SnackColors {
  final Color bg, bg2, accent, text;
  final IconData icon;
  const _SnackColors({
    required this.bg,
    required this.bg2,
    required this.accent,
    required this.text,
    required this.icon,
  });
}

/// Show a Cupertino-styled mascot notification
void showCupertinoMascotNotification(BuildContext context, String message, {MascotSnackBarType type = MascotSnackBarType.info}) {
  CupertinoToast.show(
    context,
    message: message,
    type: switch (type) {
      MascotSnackBarType.success => CupertinoToastType.success,
      MascotSnackBarType.error => CupertinoToastType.error,
      MascotSnackBarType.warning => CupertinoToastType.warning,
      MascotSnackBarType.info => CupertinoToastType.info,
    },
  );
}

// ─── Builder helper ───────────────────────────────────────────────────────────

SnackBar buildMascotSnackBar(
  BuildContext context,
  String message, {
  MascotSnackBarType type = MascotSnackBarType.info,
}) {
  return SnackBar(
    content: MascotSnackBarContent(message: message, type: type),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: EdgeInsets.zero,
    duration: const Duration(seconds: 4),
    dismissDirection: DismissDirection.horizontal,
  );
}
