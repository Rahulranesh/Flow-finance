import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/currency_formatter.dart';
import '../../../core/services/data_export_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/database/database.dart';
import '../../../data/models/currency_model.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/repositories/goal_repository.dart';
import 'sms_sync_screen.dart';
import 'google_pay_sync_screen.dart';
import '../family/family_screen.dart';
import '../goals/goals_screen.dart';
import '../wallets/wallets_screen.dart';
import '../recurring/recurring_transactions_screen.dart';
import '../bank_integration/bank_connect_screen.dart';
import '../automation/automation_screen.dart';
import '../../blocs/blocs.dart';

/// Modern settings screen with grouped sections
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final DataExportService _dataExportService = const DataExportService();

  Future<void> _editProfile(SettingsController controller) async {
    final nameController =
        TextEditingController(text: controller.settings.userName ?? '');
    final emailController =
        TextEditingController(text: controller.settings.userEmail ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'.tr()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'.tr()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              await controller.updateProfile(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
              );
              if (mounted) Navigator.pop(context);
            },
            child: Text('Save'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCurrency(SettingsController controller) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: SupportedCurrencies.all.map((currency) {
            return ListTile(
              title: Text('${currency.code} (${currency.symbol})'),
              subtitle: Text(currency.name),
              trailing: controller.currencyCode == currency.code
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, currency.code),
            );
          }).toList(),
        ),
      ),
    );
    if (selected != null) {
      await controller.updateCurrency(selected);
    }
  }

  Future<void> _pickLanguage(SettingsController controller) async {
    const languages = {
      'en': 'English',
      'ta': 'Tamil',
    };
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.entries.map((entry) {
            return ListTile(
              title: Text(entry.value.tr()),
              trailing: controller.languageCode == entry.key
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, entry.key),
            );
          }).toList(),
        ),
      ),
    );
    if (selected != null) {
      await controller.updateLanguage(selected);
      if (mounted) {
        await context.setLocale(Locale(selected));
      }
    }
  }

  Future<void> _toggleBiometric(
      SettingsController controller, bool enabled) async {
    if (enabled) {
      final supported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.canCheckBiometrics;
      if (!supported || !available) {
        if (mounted) {
          context.showSnackBar(
            SnackBar(
              content: Text(
                'Biometric authentication is not available on this device'.tr(),
              ),
            ),
          );
        }
        return;
      }
    }
    await controller.setBiometricEnabled(enabled);
  }

  Future<void> _shareExport(ExportFormat format) async {
    final transactions = context.read<TransactionBloc>().transactions;
    final now = DateTime.now();
    await _dataExportService.shareExport(
      transactions: transactions,
      dateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      format: format,
      currencySymbol: CurrencyFormatter.currentCurrency.symbol,
    );
  }

  Future<void> _openAbout() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'Flow Finance'.tr(),
      applicationVersion: info.version,
      children: [
        Text(
          'Track expenses, budgets, reports, imports, and family finance workflows.'
              .tr(),
        ),
      ],
    );
  }

  Future<void> _resetProfile(SettingsController controller) async {
    await controller.updateProfile(name: '', email: '');
    if (mounted) {
      context.showSnackBar(SnackBar(content: Text('Profile reset'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) => AppScrollScaffold(
        title: 'Settings'.tr(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileSection(
                    name: controller.settings.userName,
                    email: controller.settings.userEmail,
                    onEdit: () => _editProfile(controller),
                  ),
                  const SizedBox(height: 32),
                  _SettingsSection(
                    title: 'Appearance'.tr(),
                    children: [
                      _ThemeSelector(
                        selectedTheme: controller.themeMode,
                        onThemeSelected: (mode) =>
                            controller.updateThemeMode(mode),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Preferences'.tr(),
                    children: [
                      _SettingsSwitchTile(
                        icon: Icons.notifications,
                        iconColor: AppColors.warning,
                        title: 'Notifications'.tr(),
                        subtitle: 'Budget alerts and reminders'.tr(),
                        value: controller.settings.notificationsEnabled,
                        onChanged: controller.setNotificationsEnabled,
                      ),
                      const _SettingsDivider(),
                      _SettingsSwitchTile(
                        icon: Icons.fingerprint,
                        iconColor: AppColors.info,
                        title: 'Biometric Lock'.tr(),
                        subtitle:
                            'Require device biometrics for sensitive actions'
                                .tr(),
                        value: controller.settings.biometricEnabled,
                        onChanged: (value) =>
                            _toggleBiometric(controller, value),
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.language,
                        iconColor: AppColors.success,
                        title: 'Language'.tr(),
                        subtitle: controller.languageCode == 'ta'
                            ? 'Tamil'.tr()
                            : 'English'.tr(),
                        onTap: () => _pickLanguage(controller),
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.currency_rupee,
                        iconColor: AppColors.income,
                        title: 'Currency'.tr(),
                        subtitle:
                            '${controller.currencyCode} (${CurrencyFormatter.currentCurrency.symbol})',
                        onTap: () => _pickCurrency(controller),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Accounts & Features'.tr(),
                    children: [
                      _SettingsTile(
                        icon: Icons.account_balance_wallet,
                        iconColor: AppColors.income,
                        title: 'Wallets & Accounts'.tr(),
                        subtitle: 'Manage your cash and bank accounts'.tr(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const WalletsScreen()),
                        ),
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.repeat,
                        iconColor: AppColors.primary,
                        title: 'Recurring Transactions'.tr(),
                        subtitle: 'Manage subscriptions and repeat bills'.tr(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RecurringTransactionsScreen()),
                        ),
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.account_balance,
                        iconColor: AppColors.info,
                        title: 'Bank Integration'.tr(),
                        subtitle: 'Connect your real bank accounts'.tr(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BankConnectScreen()),
                        ),
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.auto_awesome,
                        iconColor: AppColors.warning,
                        title: 'Automation & Rules'.tr(),
                        subtitle: 'Smart routing and categorization'.tr(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AutomationScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Sync & Integration'.tr(),
                    children: [
                      _SettingsTile(
                        icon: Icons.sms,
                        iconColor: AppColors.primary,
                        title: 'SMS Sync'.tr(),
                        subtitle:
                            'Import bank and UPI transactions from SMS'.tr(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SmsSyncScreen()),
                        ),
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.payment,
                        iconColor: AppColors.secondary,
                        title: 'Google Pay Sync'.tr(),
                        subtitle:
                            'Import Google Pay transactions from SMS'.tr(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GooglePaySyncScreen(),
                          ),
                        ),
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.flag,
                        iconColor: AppColors.success,
                        title: 'Goals'.tr(),
                        subtitle: 'Create and track savings goals'.tr(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GoalsScreen()),
                        ),
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.family_restroom,
                        iconColor: AppColors.warning,
                        title: 'Family Mode'.tr(),
                        subtitle:
                            'Shared budgets and expense collaboration'.tr(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FamilyScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Data'.tr(),
                    children: [
                      _SettingsTile(
                        icon: Icons.backup,
                        iconColor: AppColors.primary,
                        title: 'Backup & Share'.tr(),
                        subtitle: 'Create a portable JSON backup'.tr(),
                        onTap: () async {
                          await BackupService(context.read<AppDatabase>())
                              .shareCompressedBackup();
                        },
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.table_chart,
                        iconColor: AppColors.secondary,
                        title: 'Export CSV'.tr(),
                        subtitle:
                            'Share all transactions as spreadsheet data'.tr(),
                        onTap: () => _shareExport(ExportFormat.csv),
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.picture_as_pdf,
                        iconColor: AppColors.warning,
                        title: 'Export PDF'.tr(),
                        subtitle: 'Share a printable finance report'.tr(),
                        onTap: () => _shareExport(ExportFormat.pdf),
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.delete_outline,
                        iconColor: AppColors.expense,
                        title: 'Clear Data'.tr(),
                        subtitle:
                            'Delete transactions, budgets, and custom data'
                                .tr(),
                        onTap: () async {
                          await BackupService(context.read<AppDatabase>())
                              .clearAllData();
                          await context
                              .read<TransactionBloc>()
                              .loadTransactions();
                          await context.read<BudgetBloc>().loadBudgets();
                          await context
                              .read<GoalRepository>()
                              .saveGoals(const <Goal>[]);
                          if (mounted) {
                            context.showSnackBar(
                              SnackBar(content: Text('App data cleared'.tr())),
                            );
                          }
                        },
                        isDestructive: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'About'.tr(),
                    children: [
                      _SettingsTile(
                        icon: Icons.info,
                        iconColor: AppColors.info,
                        title: 'About Flow Finance'.tr(),
                        subtitle: 'Version and app details'.tr(),
                        onTap: _openAbout,
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.star,
                        iconColor: AppColors.warning,
                        title: 'Rate App'.tr(),
                        subtitle: 'Open your app store review page'.tr(),
                        onTap: () async {
                          await launchUrl(
                            Uri.parse('https://play.google.com/store'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.help_outline,
                        iconColor: AppColors.success,
                        title: 'Help & Support'.tr(),
                        subtitle: 'Contact support via email'.tr(),
                        onTap: () async {
                          await launchUrl(
                            Uri.parse('mailto:support@flowfinance.app'),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  AppButton.secondary(
                    label: 'Reset Profile'.tr(),
                    onPressed: () => _resetProfile(controller),
                    expanded: true,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile section with avatar and name
class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  final String? name;
  final String? email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final resolvedName =
        (name == null || name!.trim().isEmpty) ? 'Your Profile'.tr() : name!;
    final resolvedEmail = (email == null || email!.trim().isEmpty)
        ? 'Add your email for shared budgeting'.tr()
        : email!;
    final initials = resolvedName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? 'U'.tr() : initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resolvedName,
                  style: AppTypography.titleLarge(),
                ),
                const SizedBox(height: 4),
                Text(
                  resolvedEmail,
                  style: AppTypography.bodyMedium(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.edit,
            onPressed: onEdit,
            variant: AppIconButtonVariant.filled,
          ),
        ],
      ),
    );
  }
}

/// Settings section container
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelLarge(
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          variant: AppCardVariant.flat,
          padding: EdgeInsets.zero,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

/// Settings tile with icon
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge(
          color: isDestructive ? AppColors.error : null,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.bodySmall(
                color: AppColors.textTertiary(context),
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textTertiary(context),
      ),
      onTap: onTap,
    );
  }
}

/// Settings tile with switch
class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.bodySmall(
                color: AppColors.textTertiary(context),
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

/// Settings divider
class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      color: AppColors.border(context),
    );
  }
}

/// Theme selector widget
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.selectedTheme,
    required this.onThemeSelected,
  });

  final ThemeMode selectedTheme;
  final ValueChanged<ThemeMode> onThemeSelected;

  @override
  Widget build(BuildContext context) {
    final themes = ThemeMode.values;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dark_mode,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme'.tr(),
                      style: AppTypography.bodyLarge(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose your preferred theme'.tr(),
                      style: AppTypography.bodySmall(
                        color: AppColors.textTertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: themes.map((theme) {
              final isSelected = theme == selectedTheme;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onThemeSelected(theme),
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        theme.name.capitalize.tr(),
                        style: AppTypography.labelMedium(
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
