import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Modern settings screen with grouped sections
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScrollScaffold(
      title: 'Settings',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                _ProfileSection(),

                const SizedBox(height: 32),

                // Appearance Section
                _SettingsSection(
                  title: 'Appearance',
                  children: [
                    _ThemeSelector(),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.palette,
                      iconColor: AppColors.primary,
                      title: 'Accent Color',
                      subtitle: 'Indigo',
                      onTap: () {},
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.font_download,
                      iconColor: AppColors.secondary,
                      title: 'Font',
                      subtitle: 'Inter',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Preferences Section
                _SettingsSection(
                  title: 'Preferences',
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.notifications,
                      iconColor: AppColors.warning,
                      title: 'Notifications',
                      subtitle: 'Get alerts for transactions',
                      value: true,
                      onChanged: (value) {},
                    ),
                    const _SettingsDivider(),
                    _SettingsSwitchTile(
                      icon: Icons.fingerprint,
                      iconColor: AppColors.info,
                      title: 'Biometric Lock',
                      subtitle: 'Secure with fingerprint',
                      value: false,
                      onChanged: (value) {},
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.language,
                      iconColor: AppColors.success,
                      title: 'Language',
                      subtitle: 'English (US)',
                      onTap: () {},
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.attach_money,
                      iconColor: AppColors.income,
                      title: 'Currency',
                      subtitle: 'USD (\$)',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Data Section
                _SettingsSection(
                  title: 'Data',
                  children: [
                    _SettingsTile(
                      icon: Icons.backup,
                      iconColor: AppColors.primary,
                      title: 'Backup & Restore',
                      subtitle: 'Sync to cloud storage',
                      onTap: () {},
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.download,
                      iconColor: AppColors.secondary,
                      title: 'Export Data',
                      subtitle: 'Download as CSV or PDF',
                      onTap: () {},
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.delete_outline,
                      iconColor: AppColors.expense,
                      title: 'Clear Data',
                      subtitle: 'Delete all transactions',
                      onTap: () {},
                      isDestructive: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // About Section
                _SettingsSection(
                  title: 'About',
                  children: [
                    _SettingsTile(
                      icon: Icons.info,
                      iconColor: AppColors.info,
                      title: 'About Flow Finance',
                      subtitle: 'Version 1.0.0',
                      onTap: () {},
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.star,
                      iconColor: AppColors.warning,
                      title: 'Rate App',
                      subtitle: 'Share your feedback',
                      onTap: () {},
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.help_outline,
                      iconColor: AppColors.success,
                      title: 'Help & Support',
                      subtitle: 'FAQs and contact',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign Out Button
                AppButton.secondary(
                  label: 'Sign Out',
                  onPressed: () {},
                  expanded: true,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Profile section with avatar and name
class _ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            child: const Center(
              child: Text(
                'JD',
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
                  'John Doe',
                  style: AppTypography.titleLarge(),
                ),
                const SizedBox(height: 4),
                Text(
                  'john.doe@example.com',
                  style: AppTypography.bodyMedium(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.edit,
            onPressed: () {},
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
class _ThemeSelector extends StatefulWidget {
  @override
  State<_ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<_ThemeSelector> {
  String _selectedTheme = 'System';
  final List<String> _themes = ['Light', 'Dark', 'System'];

  @override
  Widget build(BuildContext context) {
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
                      'Theme',
                      style: AppTypography.bodyLarge(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose your preferred theme',
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
            children: _themes.map((theme) {
              final isSelected = theme == _selectedTheme;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTheme = theme;
                    });
                  },
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
                        theme,
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
