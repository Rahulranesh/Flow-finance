import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';

/// Premium Cupertino-styled overlay toast with Lottie mascot animation.
/// Works without a ScaffoldMessenger ancestor using Overlay.
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color textColor;
    switch (type) {
      case CupertinoToastType.success:
        bgColor = AppColors.success;
        textColor = Colors.white;
      case CupertinoToastType.error:
        bgColor = AppColors.error;
        textColor = Colors.white;
      case CupertinoToastType.warning:
        bgColor = AppColors.warning;
        textColor = Colors.white;
      case CupertinoToastType.info:
        bgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFF1C1C1E);
        textColor = isDark ? const Color(0xFFF1F5F9) : Colors.white;
    }

    _currentEntry = OverlayEntry(
      builder: (context) => _CupertinoToastBody(
        bgColor: bgColor,
        textColor: textColor,
        message: message,
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

class _CupertinoToastBody extends StatefulWidget {
  final Color bgColor;
  final Color textColor;
  final String message;
  final VoidCallback? onUndo;
  final VoidCallback onDismiss;
  final Duration duration;

  const _CupertinoToastBody({
    required this.bgColor,
    required this.textColor,
    required this.message,
    this.onUndo,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_CupertinoToastBody> createState() => _CupertinoToastBodyState();
}

class _CupertinoToastBodyState extends State<_CupertinoToastBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _animController.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 12;
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Positioned(
          top: top,
          left: 16,
          right: 16,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
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
            onTap: () {
              _animController.reverse().then((_) => widget.onDismiss());
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
              decoration: BoxDecoration(
                color: widget.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
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
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onUndo != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _animController.reverse().then((_) {
                          widget.onDismiss();
                          widget.onUndo!();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.textColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Undo',
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
