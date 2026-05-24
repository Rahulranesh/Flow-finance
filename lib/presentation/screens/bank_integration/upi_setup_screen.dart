import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/models/upi_transaction.dart';
import '../../../core/services/bank_integration/upi_transaction_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
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
                Icon(Icons.info_outline, color: AppColors.success),
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
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.sms, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SMS Access'.tr(),
                          style: AppTypography.bodyMedium()),
                      Text(
                        'Read UPI transaction SMS'.tr(),
                        style: AppTypography.labelSmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            value: _smsPermissionGranted,
            onChanged: (value) => _toggleSmsPermission(value),
          ),

          const Divider(height: 1),

          // Notification Permission
          SwitchListTile(
            title: Row(
              children: [
                Icon(Icons.notifications, color: AppColors.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications'.tr(),
                          style: AppTypography.bodyMedium()),
                      Text(
                        'Read UPI app notifications'.tr(),
                        style: AppTypography.labelSmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            value: _notificationPermissionGranted,
            onChanged: (value) => _toggleNotificationPermission(value),
          ),
        ],
      ),
    );
  }

  Widget _buildUPIAppsCard(bool isDark) {
    return AppCard(
      child: Column(
        children: UPIApp.supportedApps.map((app) {
          return CheckboxListTile(
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.payment, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.name, style: AppTypography.bodyMedium()),
                      Text(
                        app.packageName,
                        style: AppTypography.labelSmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            value: true, // In real implementation, check user preferences
            onChanged: (value) {
              // Toggle app tracking
            },
            secondary: app.supportsSms
                ? Icon(Icons.sms_outlined, color: AppColors.success, size: 20)
                : null,
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
          SwitchListTile(
            title: Text('Auto-Sync'.tr(), style: AppTypography.bodyMedium()),
            subtitle: Text(
              'Automatically add UPI transactions to your budget'.tr(),
              style: AppTypography.labelSmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
            value: _autoSyncEnabled,
            onChanged: (value) {
              setState(() {
                _autoSyncEnabled = value;
                _upiService.setAutoSyncEnabled(value);
              });
            },
          ),

          const Divider(height: 1),

          // Scan days back
          ListTile(
            title: Text('Scan History', style: AppTypography.bodyMedium()),
            subtitle: Text(
              'Scan SMS from last $_scanDaysBack days',
              style: AppTypography.labelSmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
            trailing: DropdownButton<int>(
              value: _scanDaysBack,
              underline: const SizedBox(),
              items: [7, 30, 60, 90, 180].map((days) {
                return DropdownMenuItem(
                  value: days,
                  child: Text('$days days'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _scanDaysBack = value);
                }
              },
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
                    'Total',
                    '${_summary!.totalTransactions}',
                    AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Debits',
                    '₹${_summary!.totalDebit.toStringAsFixed(0)}',
                    AppColors.error,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Credits',
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
              label: 'Scan Historical SMS',
              icon: Icons.history,
              onPressed: _isLoading ? null : _scanHistoricalSms,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            AppButton.secondary(
              label: 'Test SMS Parser',
              icon: Icons.bug_report,
              onPressed: _showTestParser,
            ),
            const SizedBox(height: 12),
            AppButton.secondary(
              label: 'View Pending Transactions',
              icon: Icons.list,
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Revoke Permission'),
          content: const Text(
            'To revoke SMS permission, please go to Settings > Apps > Cashew > Permissions',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${transactions.length} UPI transactions'),
          ),
        );

        setState(() {
          _summary = _upiService.getSummary();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showTestParser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test SMS Parser'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Paste UPI SMS here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              onSubmitted: (value) => _testParser(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton.primary(
            label: 'Test',
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  'Pending Transactions (${pending.length})',
                  style: AppTypography.titleMedium(),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: pending.length,
                  itemBuilder: (context, index) {
                    final tx = pending[index];
                    return ListTile(
                      title: Text(tx.displayAmount),
                      subtitle: Text(tx.upiId),
                      trailing: Text(
                        tx.sourceApp,
                        style: AppTypography.labelSmall(),
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
