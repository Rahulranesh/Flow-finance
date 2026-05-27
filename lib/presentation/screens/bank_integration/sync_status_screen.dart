import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/sync/transaction_sync_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import 'package:flow_finance/core/utils/extensions.dart';
import '../../../core/widgets/app_scaffold.dart';

/// Screen for viewing sync status and history
class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  final TransactionSyncEngine _syncEngine = TransactionSyncEngine();

  @override
  void initState() {
    super.initState();
    _syncEngine.addListener(_onSyncUpdate);
  }

  @override
  void dispose() {
    _syncEngine.removeListener(_onSyncUpdate);
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Sync Status'.tr(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current sync status
            _buildCurrentStatusCard(isDark),

            const SizedBox(height: 24),

            // Sync actions
            _buildActionsCard(isDark),

            const SizedBox(height: 24),

            // Connected accounts status
            _buildAccountsStatusCard(isDark),

            const SizedBox(height: 24),

            // Sync history
            _buildSectionTitle('Sync History'.tr(), isDark),
            const SizedBox(height: 12),
            _buildSyncHistoryList(isDark),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard(bool isDark) {
    final isSyncing = _syncEngine.isSyncing;
    final progress = _syncEngine.currentProgress;

    return AppCard(
      backgroundColor: isSyncing
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.success.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSyncing ? AppColors.primary : AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSyncing ? Icons.sync : Icons.check_circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSyncing ? 'Syncing...'.tr() : 'All Synced'.tr(),
                        style: AppTypography.titleMedium().copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (progress != null)
                        Text(
                          progress.message,
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondaryLight,
                          ),
                        )
                      else
                        Text(
                          '${'Last synced'.tr()}: ${_getLastSyncText()}',
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSyncing && progress != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress.percent,
                backgroundColor: AppColors.backgroundLight,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress.percent * 100).toInt()}%',
                style: AppTypography.labelSmall(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
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
              label: 'Sync Now'.tr(),
              icon: Icons.sync,
              onPressed: _syncEngine.isSyncing ? null : _syncNow,
              isLoading: _syncEngine.isSyncing,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'Incremental'.tr(),
                    icon: Icons.update,
                    onPressed: _syncEngine.isSyncing ? null : _syncIncremental,
                    size: AppButtonSize.small,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.secondary(
                    label: 'Full Sync'.tr(),
                    icon: Icons.cloud_download,
                    onPressed: _syncEngine.isSyncing ? null : _syncFull,
                    size: AppButtonSize.small,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsStatusCard(bool isDark) {
    // Mock data - in real implementation, fetch from database
    final accounts = [
      {
        'name': 'HDFC Bank',
        'type': 'Savings',
        'status': 'synced',
        'lastSync': '2 mins ago',
        'balance': '₹45,230.00',
      },
      {
        'name': 'ICICI Bank',
        'type': 'Current',
        'status': 'error',
        'lastSync': '2 hours ago',
        'balance': '₹12,450.00',
      },
      {
        'name': 'Google Pay UPI',
        'type': 'UPI',
        'status': 'synced',
        'lastSync': '5 mins ago',
        'balance': 'Linked',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Connected Accounts'.tr(), isDark),
        const SizedBox(height: 12),
        ...accounts.map((account) => _buildAccountStatusItem(account, isDark)),
      ],
    );
  }

  Widget _buildAccountStatusItem(Map<String, dynamic> account, bool isDark) {
    final status = account['status'] as String;
    final statusColor = status == 'synced'
        ? AppColors.success
        : status == 'error'
            ? AppColors.error
            : AppColors.warning;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.account_balance, color: AppColors.primary),
        ),
        title: Text(account['name'] as String),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${account['type']} • ${account['lastSync']}'),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  status.toUpperCase(),
                  style: AppTypography.labelSmall(color: statusColor),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          account['balance'] as String,
          style: AppTypography.bodyMedium(fontWeight: FontWeight.w600),
        ),
        onTap: () => _showAccountDetails(account),
      ),
    );
  }

  Widget _buildSyncHistoryList(bool isDark) {
    final history = _syncEngine.syncHistory;

    if (history.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(height: 12),
                Text(
                  'No sync history yet'.tr(),
                  style: AppTypography.bodyMedium(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: history.take(10).map((record) {
        return AppCard(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              record.success ? Icons.check_circle : Icons.error,
              color: record.success ? AppColors.success : AppColors.error,
            ),
            title: Text(
              record.success ? 'Sync Successful'.tr() : 'Sync Failed'.tr(),
              style: AppTypography.bodyMedium(),
            ),
            subtitle: Text(
              '${_formatTime(record.timestamp)} • ${record.transactionsAdded} transactions',
              style: AppTypography.labelSmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
            trailing: record.error != null
                ? IconButton(
                    icon: const Icon(Icons.error_outline),
                    onPressed: () => _showErrorDetails(record.error!),
                  )
                : null,
          ),
        );
      }).toList(),
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

  Future<void> _syncNow() async {
    // Get current user ID from auth service
    const userId = 'current_user'; // Replace with actual user ID

    final result = await _syncEngine.syncAllSources(userId);

    if (mounted) {
      context.showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Sync complete! Added {} transactions'.tr(args: [result.totalTransactionsAdded.toString()])
                : 'Sync failed: {error}'.tr(namedArgs: {'error': result.error ?? ''}),
          ),
          backgroundColor: result.success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _syncIncremental() async {
    const userId = 'current_user';
    await _syncEngine.incrementalSync(userId);
  }

  Future<void> _syncFull() async {
    const userId = 'current_user';
    await _syncEngine.syncAllSources(userId);
  }

  void _showAccountDetails(Map<String, dynamic> account) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account['name'] as String,
              style: AppTypography.titleMedium()
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Type'.tr(), account['type'] as String),
            _buildDetailRow('Status'.tr(), account['status'] as String),
            _buildDetailRow('Last Sync'.tr(), account['lastSync'] as String),
            _buildDetailRow('Balance'.tr(), account['balance'] as String),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton.primary(
                    label: 'Sync Now'.tr(),
                    onPressed: () {
                      Navigator.pop(context);
                      _syncNow();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.secondary(
                    label: 'Disconnect'.tr(),
                    onPressed: () {
                      Navigator.pop(context);
                      _showDisconnectDialog(account);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTypography.bodyMedium(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog(Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect Account?'.tr()),
        content: Text(
          'Are you sure you want to disconnect {accountName}? Your existing transactions will be preserved.'.tr(namedArgs: {'accountName': account['name'] as String}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          AppButton.primary(
            label: 'Disconnect'.tr(),
            onPressed: () {
              Navigator.pop(context);
              // Implement disconnect logic
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDetails(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sync Error'.tr()),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'.tr()),
          ),
        ],
      ),
    );
  }

  String _getLastSyncText() {
    // In real implementation, get from sync engine
    return 'Just now'.tr();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now'.tr();
    } else if (diff.inHours < 1) {
      return '{}m ago'.tr(args: [diff.inMinutes.toString()]);
    } else if (diff.inDays < 1) {
      return '{}h ago'.tr(args: [diff.inHours.toString()]);
    } else {
      return '{}d ago'.tr(args: [diff.inDays.toString()]);
    }
  }
}
