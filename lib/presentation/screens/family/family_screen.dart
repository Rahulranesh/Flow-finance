import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/family_model.dart';
import 'package:flow_finance/core/utils/extensions.dart';
import '../../../data/repositories/family_repository.dart';

/// Family/Shared Budget screen
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  bool _isLoading = true;
  List<Family> _families = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadFamilies();
  }

  Future<void> _loadFamilies() async {
    setState(() => _isLoading = true);

    try {
      final repo = context.read<FamilyRepository>();
      // Get user ID from SharedPreferences or use a default for now
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id') ??
          'user_${DateTime.now().millisecondsSinceEpoch}';
      // Save the user ID if it was generated
      if (!prefs.containsKey('user_id')) {
        await prefs.setString('user_id', _currentUserId!);
      }
      final families = await repo.getFamilies(_currentUserId!);

      setState(() {
        _families = families;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        context.showSnackBar(
          SnackBar(content: Text('Failed to load families'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Family Budget'.tr(),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _createFamily,
        ),
      ],
      body: _isLoading
          ? AppLoading.fullScreen()
          : _families.isEmpty
              ? _buildEmptyState(isDark)
              : _buildFamilyList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 24),
          Text(
            'No Family Groups'.tr(),
            style: AppTypography.titleLarge(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a family group to share budgets\nwith your loved ones'.tr(),
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          AppButton.primary(
            label: 'Create Family Group'.tr(),
            onPressed: _createFamily,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadFamilies,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _families.length,
        itemBuilder: (context, index) {
          final family = _families[index];
          return _FamilyCard(
            family: family,
            currentUserId: _currentUserId!,
            onTap: () => _openFamilyDetails(family),
          );
        },
      ),
    );
  }

  void _createFamily() {
    showDialog(
      context: context,
      builder: (context) => _CreateFamilyDialog(
        onCreate: (name, description) async {
          try {
            final repo = context.read<FamilyRepository>();
            final family = await repo.createFamily(
              id: const Uuid().v4(),
              name: name,
              description: description,
              createdBy: _currentUserId!,
              members: [
                FamilyMember(
                  id: const Uuid().v4(),
                  userId: _currentUserId!,
                  displayName: 'You'.tr(),
                  role: FamilyRole.owner,
                  joinedAt: DateTime.now(),
                ),
              ],
            );

            await repo.setCurrentFamily(family.id);
            _loadFamilies();

            if (mounted) {
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              context.showSnackBar(
                SnackBar(content: Text('Failed to create family'.tr())),
              );
            }
          }
        },
      ),
    );
  }

  void _openFamilyDetails(Family family) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FamilyDetailScreen(
          family: family,
          currentUserId: _currentUserId!,
        ),
      ),
    ).then((_) => _loadFamilies());
  }
}

class _FamilyCard extends StatelessWidget {
  final Family family;
  final String currentUserId;
  final VoidCallback onTap;

  const _FamilyCard({
    required this.family,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMember = family.getMember(currentUserId);
    final isOwner = currentMember?.role == FamilyRole.owner;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    family.name.substring(0, 1).toUpperCase(),
                    style: AppTypography.titleMedium(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family.name,
                        style: AppTypography.titleMedium(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (family.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          family.description!,
                          style: AppTypography.bodySmall(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Owner'.tr(),
                      style: AppTypography.labelSmall(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStat(
                  Icons.people,
                  '${family.activeMembers.length}',
                  'Members'.tr(),
                ),
                const SizedBox(width: 24),
                _buildStat(
                  Icons.account_balance_wallet,
                  CurrencyFormatter.format(family.totalAllocatedBudget,
                      decimalDigits: 0),
                  'Budget'.tr(),
                ),
                const SizedBox(width: 24),
                _buildStat(
                  Icons.trending_up,
                  CurrencyFormatter.format(family.totalSpent, decimalDigits: 0),
                  'Spent'.tr(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.labelMedium(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: AppTypography.labelSmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CreateFamilyDialog extends StatefulWidget {
  final Function(String name, String? description) onCreate;

  const _CreateFamilyDialog({required this.onCreate});

  @override
  State<_CreateFamilyDialog> createState() => _CreateFamilyDialogState();
}

class _CreateFamilyDialogState extends State<_CreateFamilyDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Family Group'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Family Name'.tr(),
              hintText: 'e.g., Smith Family'.tr(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (Optional)'.tr(),
              hintText: 'e.g., Shared household budget'.tr(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'.tr()),
        ),
        AppButton.primary(
          label: 'Create'.tr(),
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onCreate(
                _nameController.text,
                _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
              );
            }
          },
        ),
      ],
    );
  }
}

class _FamilyDetailScreen extends StatelessWidget {
  final Family family;
  final String currentUserId;

  const _FamilyDetailScreen({
    required this.family,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final currentMember = family.getMember(currentUserId);
    final canEdit = currentMember?.role.permissions == PermissionLevel.full ||
        currentMember?.role.permissions == PermissionLevel.edit;

    return AppScaffold(
      title: family.name,
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Overview'.tr()),
                Tab(text: 'Members'.tr()),
                Tab(text: 'Budgets'.tr()),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(family: family),
                  _MembersTab(
                    family: family,
                    currentUserId: currentUserId,
                    canEdit: canEdit,
                  ),
                  _BudgetsTab(
                    family: family,
                    canEdit: canEdit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, Family family) {
    final emailController = TextEditingController();
    FamilyRole selectedRole = FamilyRole.member;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'member@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FamilyRole>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: FamilyRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) selectedRole = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton.primary(
            label: 'Send Invite',
            onPressed: () async {
              if (emailController.text.isEmpty) return;

              try {
                final repo = context.read<FamilyRepository>();
                await repo.createInvitation(
                  id: const Uuid().v4(),
                  familyId: family.id,
                  familyName: family.name,
                  invitedBy: currentUserId,
                  invitedByName: 'You', // TODO: Get actual user name
                  email: emailController.text,
                  role: selectedRole,
                );
                Navigator.pop(context);
                context.showSnackBar(
                  const SnackBar(content: Text('Invitation sent!')),
                );
              } catch (e) {
                context.showSnackBar(
                  const SnackBar(content: Text('Failed to send invitation')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(
      BuildContext context, Family family, FamilyMember member) {
    FamilyRole selectedRole = member.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${member.displayName}'),
        content: DropdownButtonFormField<FamilyRole>(
          value: selectedRole,
          items: FamilyRole.values.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) selectedRole = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton.primary(
            label: 'Update',
            onPressed: () async {
              try {
                final repo = context.read<FamilyRepository>();
                await repo.updateMemberRole(
                    family.id, member.userId, selectedRole);
                Navigator.pop(context);
                context.showSnackBar(
                  const SnackBar(content: Text('Role updated!')),
                );
              } catch (e) {
                context.showSnackBar(
                  const SnackBar(content: Text('Failed to update role')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(
      BuildContext context, Family family, FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${member.displayName}?'),
        content: Text(
            'Are you sure you want to remove ${member.displayName} from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton.primary(
            label: 'Remove',
            onPressed: () async {
              try {
                final repo = context.read<FamilyRepository>();
                await repo.removeMember(family.id, member.userId);
                Navigator.pop(context);
                context.showSnackBar(
                  const SnackBar(content: Text('Member removed')),
                );
              } catch (e) {
                context.showSnackBar(
                  const SnackBar(content: Text('Failed to remove member')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCreateBudgetDialog(BuildContext context, Family family) {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g., Groceries, Utilities',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton.primary(
            label: 'Create',
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (categoryController.text.isEmpty ||
                  amount == null ||
                  amount <= 0) {
                context.showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              try {
                final repo = context.read<FamilyRepository>();
                await repo.setBudget(
                  family.id,
                  FamilyBudget(
                    category: categoryController.text,
                    allocatedAmount: amount,
                  ),
                );
                Navigator.pop(context);
                context.showSnackBar(
                  const SnackBar(content: Text('Budget created!')),
                );
              } catch (e) {
                context.showSnackBar(
                  const SnackBar(content: Text('Failed to create budget')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Family family;

  const _OverviewTab({required this.family});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Summary Card
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Summary',
                    style: AppTypography.titleMedium(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryRow(
                    'Total Allocated',
                    family.totalAllocatedBudget,
                    AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Total Spent',
                    family.totalSpent,
                    AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Divider(color: AppColors.border(context)),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Remaining',
                    family.remainingBudget,
                    family.remainingBudget >= 0
                        ? AppColors.success
                        : AppColors.error,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  'Members',
                  family.activeMembers.length.toString(),
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStat(
                  'Budgets',
                  family.budgets.length.toString(),
                  Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium(
            fontWeight: isBold ? FontWeight.w600 : null,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: AppTypography.bodyLarge(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.titleLarge().copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTypography.labelSmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final Family family;
  final String currentUserId;
  final bool canEdit;

  const _MembersTab({
    required this.family,
    required this.currentUserId,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: family.activeMembers.length + (canEdit ? 1 : 0),
      itemBuilder: (context, index) {
        if (canEdit && index == family.activeMembers.length) {
          return AppButton.secondary(
            label: 'Invite Member',
            onPressed: () => _showInviteDialog(context, family, currentUserId),
            icon: Icons.person_add,
            expanded: true,
          );
        }

        final member = family.activeMembers[index];
        final isCurrentUser = member.userId == currentUserId;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              member.displayName.substring(0, 1).toUpperCase(),
              style: AppTypography.bodyMedium(
                color: AppColors.primary,
              ),
            ),
          ),
          title: Text(
            member.displayName + (isCurrentUser ? ' (You)' : ''),
            style: AppTypography.bodyMedium(
              fontWeight: isCurrentUser ? FontWeight.w600 : null,
            ),
          ),
          subtitle: Text(
            member.role.displayName,
            style: AppTypography.labelSmall(
              color: AppColors.textSecondaryLight,
            ),
          ),
          trailing: canEdit && !isCurrentUser
              ? PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'role',
                      child: Text('Change Role'),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'role') {
                      _showChangeRoleDialog(context, family, member);
                    } else if (value == 'remove') {
                      _showRemoveMemberDialog(context, family, member);
                    }
                  },
                )
              : null,
        );
      },
    );
  }

  void _showInviteDialog(
      BuildContext context, Family family, String currentUserId) {
    final emailController = TextEditingController();
    FamilyRole selectedRole = FamilyRole.member;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'member@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FamilyRole>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: FamilyRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) selectedRole = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton.primary(
            label: 'Send Invite',
            onPressed: () async {
              if (emailController.text.isEmpty) return;

              try {
                final repo = context.read<FamilyRepository>();
                await repo.createInvitation(
                  id: const Uuid().v4(),
                  familyId: family.id,
                  familyName: family.name,
                  invitedBy: currentUserId,
                  invitedByName: 'You',
                  email: emailController.text,
                  role: selectedRole,
                );
                Navigator.pop(context);
                context.showSnackBar(
                  const SnackBar(content: Text('Invitation sent!')),
                );
              } catch (e) {
                context.showSnackBar(
                  const SnackBar(content: Text('Failed to send invitation')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(
      BuildContext context, Family family, FamilyMember member) {
    FamilyRole selectedRole = member.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${member.displayName}'),
        content: DropdownButtonFormField<FamilyRole>(
          value: selectedRole,
          items: FamilyRole.values.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) selectedRole = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton.primary(
            label: 'Update',
            onPressed: () async {
              try {
                final repo = context.read<FamilyRepository>();
                await repo.updateMemberRole(
                    family.id, member.userId, selectedRole);
                Navigator.pop(context);
                context.showSnackBar(
                  const SnackBar(content: Text('Role updated!')),
                );
              } catch (e) {
                context.showSnackBar(
                  const SnackBar(content: Text('Failed to update role')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(
      BuildContext context, Family family, FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${member.displayName}?'),
        content: Text(
            'Are you sure you want to remove ${member.displayName} from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton.primary(
            label: 'Remove',
            onPressed: () async {
              try {
                final repo = context.read<FamilyRepository>();
                await repo.removeMember(family.id, member.userId);
                Navigator.pop(context);
                context.showSnackBar(
                  const SnackBar(content: Text('Member removed')),
                );
              } catch (e) {
                context.showSnackBar(
                  const SnackBar(content: Text('Failed to remove member')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _BudgetsTab extends StatelessWidget {
  final Family family;
  final bool canEdit;

  const _BudgetsTab({
    required this.family,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (family.budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No Budgets Yet',
              style: AppTypography.titleMedium(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create budgets to track family spending',
              style: AppTypography.bodyMedium(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            if (canEdit) ...[
              const SizedBox(height: 24),
              AppButton.primary(
                label: 'Create Budget',
                onPressed: () => _showCreateBudgetDialog(context, family),
                icon: Icons.add,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: family.budgets.length + (canEdit ? 1 : 0),
      itemBuilder: (context, index) {
        if (canEdit && index == family.budgets.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AppButton.secondary(
              label: 'Add Budget',
              onPressed: () => _showCreateBudgetDialog(context, family),
              icon: Icons.add,
              expanded: true,
            ),
          );
        }

        final budget = family.budgets[index];
        return _BudgetCard(budget: budget);
      },
    );
  }

  void _showCreateBudgetDialog(BuildContext context, Family family) {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g., Groceries, Utilities',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton.primary(
            label: 'Create',
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (categoryController.text.isEmpty ||
                  amount == null ||
                  amount <= 0) {
                context.showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              try {
                final repo = context.read<FamilyRepository>();
                await repo.setBudget(
                  family.id,
                  FamilyBudget(
                    category: categoryController.text,
                    allocatedAmount: amount,
                  ),
                );
                Navigator.pop(context);
                context.showSnackBar(
                  const SnackBar(content: Text('Budget created!')),
                );
              } catch (e) {
                context.showSnackBar(
                  const SnackBar(content: Text('Failed to create budget')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final FamilyBudget budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = budget.percentageUsed / 100;
    final isOverBudget = budget.isOverBudget;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  budget.category,
                  style: AppTypography.bodyMedium(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${budget.spentAmount.toStringAsFixed(0)} / \$${budget.allocatedAmount.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall(
                    color: isOverBudget
                        ? AppColors.error
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                backgroundColor:
                    isDark ? AppColors.borderDark : AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget
                      ? AppColors.error
                      : progress > 0.8
                          ? AppColors.warning
                          : AppColors.success,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOverBudget
                  ? 'Over budget by \$${(budget.spentAmount - budget.allocatedAmount).toStringAsFixed(2)}'
                  : '\$${budget.remainingAmount.toStringAsFixed(2)} remaining',
              style: AppTypography.labelSmall(
                color: isOverBudget
                    ? AppColors.error
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
