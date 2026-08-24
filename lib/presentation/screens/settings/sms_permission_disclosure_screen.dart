import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/theme.dart';
import '../../../core/services/sms_transaction_service.dart';

/// Full-screen prominent disclosure screen shown BEFORE any SMS permission request.
/// This satisfies Google Play's "Missing user prompt for permissions access" policy requirement.
/// Google Policy reference: https://support.google.com/googleplay/android-developer/answer/9214102
class SmsPermissionDisclosureScreen extends StatefulWidget {
  /// Called when permission is granted successfully
  final VoidCallback onGranted;
  /// Called when user declines or skips
  final VoidCallback? onDeclined;

  const SmsPermissionDisclosureScreen({
    super.key,
    required this.onGranted,
    this.onDeclined,
  });

  @override
  State<SmsPermissionDisclosureScreen> createState() => _SmsPermissionDisclosureScreenState();
}

class _SmsPermissionDisclosureScreenState extends State<SmsPermissionDisclosureScreen> {
  final _smsService = SmsTransactionService();
  bool _isRequesting = false;

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);

    // Permission request — triggers OS runtime dialog
    final granted = await _smsService.requestPermissions();

    if (!mounted) return;
    setState(() => _isRequesting = false);

    if (granted) {
      widget.onGranted();
    } else {
      // Check if permanently denied — guide user to settings
      final status = await Permission.sms.status;
      if (status.isPermanentlyDenied && mounted) {
        _showSettingsDialog();
      }
    }
  }

  void _showSettingsDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Permission Denied'.tr()),
        content: Text(
          'SMS permission was permanently denied. Please open Settings and grant SMS permission to use this feature.'.tr(),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'.tr()),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Open Settings'.tr()),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onDeclined != null
            ? IconButton(
                icon: const Icon(CupertinoIcons.xmark),
                onPressed: widget.onDeclined,
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  CupertinoIcons.chat_bubble_2_fill,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),

              const SizedBox(height: 28),

              // Title
              Text(
                'Allow SMS Access for\nAutomatic Expense Tracking'.tr(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary(context),
                ),
              ),

              const SizedBox(height: 16),

              // Purpose explanation (Google Play requires clear, specific disclosure)
              Text(
                'Flow Finance needs to read your SMS messages to automatically detect and import bank transaction alerts such as:'.tr(),
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary(context),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // Use cases
              _buildUseCase(
                icon: CupertinoIcons.creditcard_fill,
                color: Colors.blue,
                title: 'Debit & Credit Alerts'.tr(),
                description: 'Auto-detect UPI, NEFT, IMPS & card transactions from your bank.'.tr(),
              ),
              const SizedBox(height: 12),
              _buildUseCase(
                icon: CupertinoIcons.tag_fill,
                color: Colors.orange,
                title: 'Expense Categorization'.tr(),
                description: 'Automatically categorize spending into Food, Travel, Shopping, etc.'.tr(),
              ),
              const SizedBox(height: 12),
              _buildUseCase(
                icon: CupertinoIcons.lock_shield_fill,
                color: Colors.green,
                title: '100% Private & On-Device'.tr(),
                description: 'All SMS processing happens on your device only. Your data is never uploaded or shared.'.tr(),
              ),

              const SizedBox(height: 28),

              // Privacy commitment box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.18),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(CupertinoIcons.info_circle_fill,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'We only access SMS messages to detect bank transactions. We do not read personal messages, contacts, or any other data. SMS data is NEVER transmitted off your device.'.tr(),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary(context),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Primary CTA — triggers OS runtime permission dialog
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isRequesting
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          'Allow SMS Access'.tr(),
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Decline option
              if (widget.onDeclined != null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: widget.onDeclined,
                    child: Text(
                      'Not now'.tr(),
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUseCase({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
