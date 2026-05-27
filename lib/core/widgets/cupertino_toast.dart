import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Single source of truth for all in-app notifications.
/// Uses Overlay (no ScaffoldMessenger dependency), plays Lottie mascot,
/// and shows a premium gradient banner.
class CupertinoToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    CupertinoToastType type = CupertinoToastType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onUndo,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    // Haptic feedback per type
    switch (type) {
      case CupertinoToastType.success:
        HapticFeedback.lightImpact();
      case CupertinoToastType.error:
        HapticFeedback.heavyImpact();
      case CupertinoToastType.warning:
        HapticFeedback.mediumImpact();
      case CupertinoToastType.info:
        HapticFeedback.selectionClick();
    }

    _currentEntry = OverlayEntry(
      builder: (context) => _MascotToastBody(
        message: message,
        type: type,
        onUndo: onUndo,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
        duration: duration,
      ),
    );

    Overlay.of(context).insert(_currentEntry!);

    Future.delayed(duration + const Duration(milliseconds: 400), () {
      _currentEntry?.remove();
      _currentEntry = null;
    });
  }
}

enum CupertinoToastType { success, error, warning, info }

// ─── Toast body with entry/exit animation ─────────────────────────────────────────

class _MascotToastBody extends StatefulWidget {
  final String message;
  final CupertinoToastType type;
  final VoidCallback? onUndo;
  final VoidCallback onDismiss;
  final Duration duration;

  const _MascotToastBody({
    required this.message,
    required this.type,
    this.onUndo,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_MascotToastBody> createState() => _MascotToastBodyState();
}

class _MascotToastBodyState extends State<_MascotToastBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.3, curve: Curves.easeIn)),
    );
    _ctrl.forward();

    Future.delayed(widget.duration, () {
      if (mounted) _ctrl.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = MediaQuery.of(context).padding.top + 12;
    final colors = _resolveColors(isDark);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          top: top,
          left: 16,
          right: 16,
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: child!,
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: GestureDetector(
            onTap: () => _ctrl.reverse().then((_) => widget.onDismiss()),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.bg, colors.bg2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.accent.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    // Subtle shimmer sweep
                    Positioned.fill(
                      child: _ShimmerBar(colors.accent),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
                      child: Row(
                        children: [
                          // Lottie mascot
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: Lottie.asset(
                              'assets/mascot.json',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Accent bar
                          Container(
                            width: 3,
                            height: 34,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Message area
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(colors.icon, color: colors.accent, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      colors.label,
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
                                  style: TextStyle(
                                    color: colors.text,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (widget.onUndo != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                _ctrl.reverse().then((_) {
                                  widget.onDismiss();
                                  widget.onUndo!();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: colors.accent.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: colors.accent.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  'Undo',
                                  style: TextStyle(
                                    color: colors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastColors _resolveColors(bool isDark) {
    switch (widget.type) {
      case CupertinoToastType.success:
        return _ToastColors(
          bg: isDark ? const Color(0xFF0D2E1A) : const Color(0xFFE8F5E9),
          bg2: isDark ? const Color(0xFF133322) : const Color(0xFFD0EDDA),
          accent: AppColors.success,
          text: isDark ? Colors.white : const Color(0xFF1B5E20),
          icon: CupertinoIcons.checkmark_alt_circle_fill,
          label: 'SUCCESS',
        );
      case CupertinoToastType.error:
        return _ToastColors(
          bg: isDark ? const Color(0xFF2E0D0D) : const Color(0xFFFFEBEE),
          bg2: isDark ? const Color(0xFF3A1010) : const Color(0xFFFFD6D6),
          accent: AppColors.error,
          text: isDark ? Colors.white : const Color(0xFFB71C1C),
          icon: CupertinoIcons.exclamationmark_circle_fill,
          label: 'ERROR',
        );
      case CupertinoToastType.warning:
        return _ToastColors(
          bg: isDark ? const Color(0xFF2E220D) : const Color(0xFFFFF8E1),
          bg2: isDark ? const Color(0xFF3A2C10) : const Color(0xFFFFECB3),
          accent: const Color(0xFFF59E0B),
          text: isDark ? Colors.white : const Color(0xFF78350F),
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          label: 'WARNING',
        );
      case CupertinoToastType.info:
        return _ToastColors(
          bg: isDark ? const Color(0xFF0D1A2E) : const Color(0xFFE3F2FD),
          bg2: isDark ? const Color(0xFF10223A) : const Color(0xFFBBDEFB),
          accent: AppColors.primary,
          text: isDark ? Colors.white : const Color(0xFF0D47A1),
          icon: CupertinoIcons.info_circle_fill,
          label: 'INFO',
        );
    }
  }
}

// ─── Shimmer bar ──────────────────────────────────────────────────────────────────

class _ShimmerBar extends StatefulWidget {
  final Color accent;
  const _ShimmerBar(this.accent);

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _ShimmerPainter(_ctrl.value, widget.accent),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter(this.progress, this.accent);
  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final x = progress * (size.width + size.width * 0.6) - size.width * 0.3;
    final gradient = LinearGradient(
      colors: [Colors.transparent, accent.withOpacity(0.05), Colors.transparent],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment((-1.0 + progress * 3), -1),
      end: Alignment((progress * 3), 1),
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(x, 0, size.width * 0.5, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ─── Color data ───────────────────────────────────────────────────────────────────

class _ToastColors {
  final Color bg, bg2, accent, text;
  final IconData icon;
  final String label;
  const _ToastColors({
    required this.bg,
    required this.bg2,
    required this.accent,
    required this.text,
    required this.icon,
    required this.label,
  });
}
