import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/models/upi_transaction.dart';
import '../../../core/services/bank_integration/upi_transaction_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import 'package:flow_finance/core/utils/extensions.dart';
import '../../../core/widgets/cupertino_toast.dart';
import '../../../core/widgets/app_scaffold.dart';

/// Screen for setting up UPI transaction tracking
class UPISetupScreen extends StatefulWidget {
  const UPISetupScreen({super.key});

  @override
  State<UPISetupScreen> createState() => _UPISetupScreenState();
}

class _UPISetupScreenState extends State<UPISetupScreen> {
  final UPITransactionService _upiService = UPITransactionService();

  bool _isLoading = false;
  bool _smsPermissionGranted = false;
  bool _notificationPermissionGranted = false;
  bool _autoSyncEnabled = true;
  int _scanDaysBack = 30;

  UPITransactionSummary? _summary;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _upiService.initialize();
    setState(() {
      _smsPermissionGranted = _upiService.isSmsPermissionGranted;
      _notificationPermissionGranted =
          _upiService.isNotificationPermissionGranted;
      _autoSyncEnabled = _upiService.isAutoSyncEnabled;
      _summary = _upiService.getSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'UPI Transaction Tracking'.tr(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            _buildInfoCard(isDark),

            const SizedBox(height: 24),

            // Permissions section
            _buildSectionTitle('Permissions'.tr(), isDark),
            const SizedBox(height: 12),
            _buildPermissionCard(isDark),

            const SizedBox(height: 24),

            // UPI Apps section
            _buildSectionTitle('UPI Apps'.tr(), isDark),
            const SizedBox(height: 12),
            _buildUPIAppsCard(isDark),

            const SizedBox(height: 24),

            // Settings section
            _buildSectionTitle('Settings'.tr(), isDark),
            const SizedBox(height: 12),
            _buildSettingsCard(isDark),

            const SizedBox(height: 24),

            // Statistics section
            if (_summary != null) ...[
              _buildSectionTitle('Statistics'.tr(), isDark),
              const SizedBox(height: 12),
              _buildStatisticsCard(isDark),
            ],

            const SizedBox(height: 24),

            // Actions
            _buildActionsCard(isDark),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return AppCard(
      backgroundColor: AppColors.success.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.info_circle, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Automatic UPI Tracking'.tr(),
                    style:
                        AppTypography.bodyMedium(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'We automatically detect UPI transactions from your SMS and notifications. No manual entry needed!'
                  .tr(),
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.titleMedium(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildPermissionCard(bool isDark) {
    return AppCard(
      child: Column(
        children: [
          // SMS Permission
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(CupertinoIcons.chat_bubble_2_fill, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SMS Access'.tr(),
                          style: AppTypography.bodyLarge(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        'Read UPI transaction SMS'.tr(),
                        style: AppTypography.bodySmall(
                          color: AppColors.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoSwitch(
                  value: _smsPermissionGranted,
                  onChanged: (value) => _toggleSmsPermission(value),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Notification Permission
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(CupertinoIcons.bell_fill, color: AppColors.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications'.tr(),
                          style: AppTypography.bodyLarge(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        'Read UPI app notifications'.tr(),
                        style: AppTypography.bodySmall(
                          color: AppColors.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoSwitch(
                  value: _notificationPermissionGranted,
                  onChanged: (value) => _toggleNotificationPermission(value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUPIAppsCard(bool isDark) {
    return AppCard(
      child: Column(
        children: UPIApp.supportedApps.map((app) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Icon(
                    true ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                    color: true ? AppColors.primary : AppColors.textTertiary(context),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(CupertinoIcons.creditcard_fill, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.name, style: AppTypography.bodyLarge()),
                        Text(
                          app.packageName,
                          style: AppTypography.bodySmall(
                            color: AppColors.textTertiary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (app.supportsSms)
                    Icon(CupertinoIcons.chat_bubble_2_fill, color: AppColors.success, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark) {
    return AppCard(
      child: Column(
        children: [
          // Auto-sync
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auto-Sync'.tr(), style: AppTypography.bodyLarge(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        'Automatically add UPI transactions to your budget'.tr(),
                        style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoSwitch(
                  value: _autoSyncEnabled,
                  onChanged: (value) {
                    setState(() {
                      _autoSyncEnabled = value;
                      _upiService.setAutoSyncEnabled(value);
                    });
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scan days back
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scan History'.tr(), style: AppTypography.bodyLarge(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        'Scan SMS from last {} days'.tr(args: [_scanDaysBack.toString()]),
                        style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                      ),
                    ],
                  ),
                ),
                DropdownButton<int>(
                  value: _scanDaysBack,
                  underline: const SizedBox(),
                  items: [7, 30, 60, 90, 180].map((days) {
                    return DropdownMenuItem(
                      value: days,
                      child: Text('{} days'.tr(args: [days.toString()])),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _scanDaysBack = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(bool isDark) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total'.tr(),
                    '${_summary!.totalTransactions}',
                    AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Debits'.tr(),
                    '₹${_summary!.totalDebit.toStringAsFixed(0)}',
                    AppColors.error,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Credits'.tr(),
                    '₹${_summary!.totalCredit.toStringAsFixed(0)}',
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Source app distribution
            ..._summary!.sourceAppDistribution.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: AppTypography.bodySmall(),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: entry.value / _summary!.totalTransactions,
                        backgroundColor: AppColors.backgroundLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value}',
                      style: AppTypography.labelSmall(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium(
            color: color,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall(color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildActionsCard(bool isDark) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton.primary(
              label: 'Scan Historical SMS'.tr(),
              icon: CupertinoIcons.clock,
              onPressed: _isLoading ? null : _scanHistoricalSms,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            AppButton.secondary(
              label: 'Test SMS Parser'.tr(),
              icon: Icons.bug_report,
              onPressed: _showTestParser,
            ),
            const SizedBox(height: 12),
            AppButton.secondary(
              label: 'View Pending Transactions'.tr(),
              icon: CupertinoIcons.list_bullet,
              onPressed: _showPendingTransactions,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSmsPermission(bool value) async {
    if (value) {
      final granted = await _upiService.requestSmsPermission();
      setState(() => _smsPermissionGranted = granted);

      if (granted) {
        _upiService.startListening();
      }
    } else {
      // Cannot revoke SMS permission programmatically
      // Show dialog directing user to settings
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Revoke Permission'.tr()),
          content: Text(
            'To revoke SMS permission, please go to Settings > Apps > Cashew > Permissions'.tr(),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'.tr()),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _toggleNotificationPermission(bool value) async {
    if (value) {
      final granted = await _upiService.requestNotificationPermission();
      setState(() => _notificationPermissionGranted = granted);

      if (granted) {
        _upiService.startListening();
      }
    } else {
      setState(() => _notificationPermissionGranted = false);
      _upiService.stopListening();
    }
  }

  Future<void> _scanHistoricalSms() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await _upiService.scanHistoricalSms(
        daysBack: _scanDaysBack,
      );

      if (mounted) {
        CupertinoToast.show(
          context,
          message: 'Found {} UPI transactions'.tr(args: [transactions.length.toString()]),
        );

        setState(() {
          _summary = _upiService.getSummary();
        });
      }
    } catch (e) {
      if (mounted) {
        CupertinoToast.show(
          context,
          message: '${'Error'.tr()}: $e',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showTestParser() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Test SMS Parser'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Paste UPI SMS here...'.tr(),
                border: const OutlineInputBorder(),
              ),
              maxLines: 5,
              onSubmitted: (value) => _testParser(value),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          AppButton.primary(
            label: 'Test'.tr(),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  void _testParser(String sms) {
    // Implementation would test the parser
  }

  void _showPendingTransactions() {
    final pending = _upiService.getPendingTransactions();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Pending Transactions ({count})'.tr(namedArgs: {'count': pending.length.toString()}),
                  style: AppTypography.titleMedium(),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: pending.length,
                  itemBuilder: (context, index) {
                    final tx = pending[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx.displayAmount, style: AppTypography.bodyLarge(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(tx.upiId, style: AppTypography.bodySmall(color: AppColors.textTertiary(context))),
                              ],
                            ),
                          ),
                          Text(
                            tx.sourceApp,
                            style: AppTypography.labelSmall(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
