import 'package:flutter/material.dart';

/// Animation system with consistent durations and curves
/// Follows modern motion design principles for 2025 UI
class AppAnimations {
  AppAnimations._();

  // Durations
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);

  // Curves
  static const Curve linear = Curves.linear;
  static const Curve ease = Curves.ease;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;

  // Specialized curves
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  static const Curve easeOutQuart = Curves.easeOutQuart;
  static const Curve easeInOutQuart = Curves.easeInOutQuart;
  static const Curve easeOutExpo = Curves.easeOutExpo;
  static const Curve easeInOutExpo = Curves.easeInOutExpo;

  // Spring curves for bouncy effects
  static const Curve spring = Curves.elasticOut;
  static const Curve springLight = Curves.easeOutBack;
  static const Curve bounce = Curves.bounceOut;

  // Decelerate curves for smooth endings
  static const Curve decelerate = Curves.decelerate;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  /// Standard page transition duration
  static const Duration pageTransition = Duration(milliseconds: 300);

  /// Standard page transition curve
  static const Curve pageTransitionCurve = Curves.easeInOutCubic;

  /// Dialog/Bottom sheet entrance duration
  static const Duration modalEntrance = Duration(milliseconds: 350);

  /// Dialog/Bottom sheet exit duration
  static const Duration modalExit = Duration(milliseconds: 250);

  /// Snackbar/Toast duration
  static const Duration snackbar = Duration(milliseconds: 300);

  /// Loading spinner rotation duration
  static const Duration spinner = Duration(milliseconds: 1000);

  /// Shimmer animation duration
  static const Duration shimmer = Duration(milliseconds: 1500);

  /// Stagger animation delay between items
  static const Duration staggerDelay = Duration(milliseconds: 50);

  /// Button press scale duration
  static const Duration buttonPress = Duration(milliseconds: 100);

  /// Card hover/elevation change duration
  static const Duration cardElevation = Duration(milliseconds: 200);

  /// Input field focus transition duration
  static const Duration inputFocus = Duration(milliseconds: 150);

  /// Scroll animation duration
  static const Duration scroll = Duration(milliseconds: 400);

  /// Number counting animation duration
  static const Duration numberCount = Duration(milliseconds: 800);

  /// Chart animation duration
  static const Duration chart = Duration(milliseconds: 1000);

  /// Progress bar animation duration
  static const Duration progress = Duration(milliseconds: 600);

  /// Fade transition duration
  static const Duration fade = Duration(milliseconds: 250);

  /// Scale transition duration
  static const Duration scale = Duration(milliseconds: 200);

  /// Slide transition duration
  static const Duration slide = Duration(milliseconds: 300);
}

/// Animation presets for common use cases
class AppAnimationPresets {
  AppAnimationPresets._();

  /// Fade in animation
  static Animation<double> fadeIn(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: AppAnimations.easeOut,
    );
  }

  /// Fade in with scale animation
  static Animation<double> fadeInScale(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: AppAnimations.springLight,
    );
  }

  /// Slide up animation
  static Animation<Offset> slideUp(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: AppAnimations.easeOutCubic,
    ));
  }

  /// Slide from right animation
  static Animation<Offset> slideFromRight(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: AppAnimations.easeOutCubic,
    ));
  }

  /// Scale up animation
  static Animation<double> scaleUp(AnimationController controller) {
    return Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: AppAnimations.springLight,
    ));
  }

  /// Button press scale animation
  static Animation<double> buttonPress(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: AppAnimations.easeOut,
    ));
  }
}

/// Widget animation builders
class AppAnimatedWidgets {
  AppAnimatedWidgets._();

  /// Fade transition wrapper
  static Widget fade({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Scale transition wrapper
  static Widget scale({
    required Widget child,
    required Animation<double> animation,
  }) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }

  /// Slide transition wrapper
  static Widget slide({
    required Widget child,
    required Animation<Offset> animation,
  }) {
    return SlideTransition(
      position: animation,
      child: child,
    );
  }

  /// Fade + Scale combined
  static Widget fadeScale({
    required Widget child,
    required Animation<double> fadeAnimation,
    required Animation<double> scaleAnimation,
  }) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }

  /// Slide + Fade combined
  static Widget slideFade({
    required Widget child,
    required Animation<Offset> slideAnimation,
    required Animation<double> fadeAnimation,
  }) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}
