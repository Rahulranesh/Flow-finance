import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum MascotSnackBarType { info, success, error }

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );

  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color textColor = Colors.white;

    switch (widget.type) {
      case MascotSnackBarType.success:
        backgroundColor = AppColors.success.withOpacity(0.9);
        break;
      case MascotSnackBarType.error:
        backgroundColor = AppColors.error.withOpacity(0.9);
        break;
      case MascotSnackBarType.info:
        backgroundColor = isDark
            ? AppColors.surfaceDark.withOpacity(0.9)
            : AppColors.surfaceLight.withOpacity(0.9);
        textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Lottie.asset(
                'assets/mascot.json',
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.message,
              style: AppTypography.bodyMedium(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

SnackBar buildMascotSnackBar(BuildContext context, String message, {MascotSnackBarType type = MascotSnackBarType.info}) {
  return SnackBar(
    content: MascotSnackBarContent(message: message, type: type),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    padding: EdgeInsets.zero,
    duration: const Duration(seconds: 4),
  );
}
