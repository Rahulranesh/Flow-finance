import 'package:flutter/cupertino.dart';
import 'cupertino_toast.dart';

/// Notification type (maps to CupertinoToastType).
enum MascotSnackBarType { info, success, error, warning }

/// Dispatches directly to the premium Lottie CupertinoToast.
void showCupertinoMascotNotification(
  BuildContext context,
  String message, {
  MascotSnackBarType type = MascotSnackBarType.info,
}) {
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
