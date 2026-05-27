import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/smart_rules_engine.dart';
import '../../../core/services/auto_transfer_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/flow_mascot.dart';
import '../../../core/widgets/mascot_snackbar.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/wallet_model.dart';
import '../../blocs/wallet_bloc.dart';

// ─── Main Screen ──────────────────────────────────────────────────────────────

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen>
    with SingleTickerProviderStateMixin {
  late final SmartRulesEngine _rulesEngine;
  late final AutoTransferService _transferService;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _rulesEngine = context.read<SmartRulesEngine>();
    _transferService = context.read<AutoTransferService>();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Automation'.tr(),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary(context),
        tabs: [
          Tab(text: 'Rules'.tr()),
          Tab(text: 'Transfers'.tr()),
          Tab(text: 'Round-Up'.tr()),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SmartRulesTab(rulesEngine: _rulesEngine),
          _AutoTransferTab(transferService: _transferService),
          _RoundUpTab(transferService: _transferService),
        ],
      ),
    );
  }
}

// ─── Smart Rules Tab ──────────────────────────────────────────────────────────

class _SmartRulesTab extends StatefulWidget {
  final SmartRulesEngine rulesEngine;
  const _SmartRulesTab({required this.rulesEngine});

  @override
  State<_SmartRulesTab> createState() => _SmartRulesTabState();
}

class _SmartRulesTabState extends State<_SmartRulesTab> {
  @override
  Widget build(BuildContext context) {
    final rules = widget.rulesEngine.getRules();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: CupertinoButton(
        onPressed: _showAddRuleDialog,
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.add, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text('Add Rule'.tr(), style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
      body: rules.isEmpty
          ? _buildEmptyState(
              icon: Icons.auto_fix_high_rounded,
              title: 'No smart rules yet'.tr(),
              subtitle: 'Rules auto-categorize your transactions'.tr(),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _RuleTile(
                rule: rules[i],
                onToggle: (value) {
                  setState(() {
                    widget.rulesEngine.updateRule(rules[i].copyWith(isActive: value));
                  });
                },
                onDelete: () {
                  setState(() {
                    widget.rulesEngine.removeRule(rules[i].id);
                  });
                  context.showMascotSnackBar('Rule deleted'.tr(), type: MascotSnackBarType.info);
                },
                onEdit: () => _showEditRuleDialog(rules[i]),
              ),
            ),
    );
  }

  void _showAddRuleDialog() async {
    final result = await showCupertinoDialog<SmartRule>(
      context: context,
      builder: (_) => const _SmartRuleDialog(),
    );
    if (result != null) {
      setState(() => widget.rulesEngine.addRule(result));
      if (mounted) {
        context.showMascotSnackBar('Rule added!'.tr(), type: MascotSnackBarType.success);
      }
    }
  }

  void _showEditRuleDialog(SmartRule existing) async {
    final result = await showCupertinoDialog<SmartRule>(
      context: context,
      builder: (_) => _SmartRuleDialog(existing: existing),
    );
    if (result != null) {
      setState(() => widget.rulesEngine.updateRule(result));
      if (mounted) {
        context.showMascotSnackBar('Rule updated!'.tr(), type: MascotSnackBarType.success);
      }
    }
  }
}

class _RuleTile extends StatelessWidget {
  final SmartRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _RuleTile({
    required this.rule,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (rule.isActive ? AppColors.primary : AppColors.textSecondary(context))
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconForType(rule.type),
                color: rule.isActive ? AppColors.primary : AppColors.textSecondary(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.name, style: AppTypography.bodyLarge(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${rule.conditions.length} ${'conditions'.tr()} → ${rule.actions.length} ${'actions'.tr()}',
                    style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                  ),
                ],
              ),
            ),
            Switch(
              value: rule.isActive,
              onChanged: onToggle,
              activeColor: AppColors.primary,
            ),
            GestureDetector(
              onTap: () {
                showCupertinoModalPopup<void>(
                  context: context,
                  builder: (context) => CupertinoActionSheet(
                    actions: [
                      CupertinoActionSheetAction(
                        child: Text('Edit'.tr()),
                        onPressed: () { Navigator.pop(context); onEdit(); },
                      ),
                      CupertinoActionSheetAction(
                        isDestructiveAction: true,
                        child: Text('Delete'.tr()),
                        onPressed: () { Navigator.pop(context); onDelete(); },
                      ),
                    ],
                    cancelButton: CupertinoActionSheetAction(
                      isDefaultAction: true,
                      child: Text('Cancel'.tr()),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
              child: Icon(CupertinoIcons.ellipsis, color: AppColors.textSecondary(context), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(RuleType type) {
    switch (type) {
      case RuleType.categorization:
        return Icons.label_rounded;
      case RuleType.tagging:
        return Icons.tag_rounded;
      case RuleType.walletAssignment:
        return CupertinoIcons.creditcard;
      case RuleType.typeAssignment:
        return Icons.swap_horiz_rounded;
      case RuleType.notification:
        return CupertinoIcons.bell_fill;
    }
  }
}

// ─── Auto-Transfer Tab ────────────────────────────────────────────────────────

class _AutoTransferTab extends StatefulWidget {
  final AutoTransferService transferService;
  const _AutoTransferTab({required this.transferService});

  @override
  State<_AutoTransferTab> createState() => _AutoTransferTabState();
}

class _AutoTransferTabState extends State<_AutoTransferTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rules = widget.transferService.rules;
    final summary = widget.transferService.getSavingsSummary();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: CupertinoButton(
        onPressed: _showAddDialog,
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.add, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text('Add Transfer'.tr(), style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // Summary card
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 0.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const FlowMascotAvatar(size: 52, showGlow: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Last 30 Days'.tr(),
                            style: AppTypography.labelSmall(color: AppColors.textSecondary(context))),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _statChip('Saved'.tr(), '\$${summary.totalSaved.toStringAsFixed(2)}',
                                AppColors.success),
                            const SizedBox(width: 12),
                            _statChip('Transfers'.tr(), '${summary.transferCount}', AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (rules.isEmpty)
            _buildEmptyState(
              icon: CupertinoIcons.refresh_thick,
              title: 'No auto-transfer rules'.tr(),
              subtitle: 'Set up rules to move money automatically'.tr(),
            )
          else
            ...rules.map((rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AutoTransferTile(
                    rule: rule,
                    onToggle: (v) {
                      setState(() {
                        widget.transferService.addAutoTransferRule(rule.copyWith(isActive: v));
                      });
                    },
                    onDelete: () {
                      setState(() {
                        widget.transferService.removeAutoTransferRule(rule.id);
                      });
                      context.showMascotSnackBar('Transfer rule deleted'.tr(), type: MascotSnackBarType.info);
                    },
                  ),
                )),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTypography.titleSmall(color: color).copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTypography.labelSmall(color: AppColors.textSecondary(context))),
      ],
    );
  }

  void _showAddDialog() async {
    final wallets = context.read<WalletBloc>().wallets;
    if (wallets.length < 2) {
      _showNeedMoreWallets();
      return;
    }
    final result = await showCupertinoDialog<AutoTransferRule>(
      context: context,
      builder: (_) => _AutoTransferDialog(wallets: wallets),
    );
    if (result != null) {
      setState(() => widget.transferService.addAutoTransferRule(result));
      if (mounted) {
        context.showMascotSnackBar('Auto-transfer rule added!'.tr(), type: MascotSnackBarType.success);
      }
    }
  }

  void _showNeedMoreWallets() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Need More Wallets'.tr()),
        content: Text('You need at least 2 wallets to set up auto-transfers.'.tr()),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: Text('OK'.tr())),
        ],
      ),
    );
  }
}

class _AutoTransferTile extends StatelessWidget {
  final AutoTransferRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _AutoTransferTile({required this.rule, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(CupertinoIcons.refresh_thick, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.name, style: AppTypography.bodyLarge(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${rule.calculationType.name} · \$${rule.amount}',
                    style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                  ),
                ],
              ),
            ),
            Switch(value: rule.isActive, onChanged: onToggle, activeColor: AppColors.primary),
            IconButton(
              icon: Icon(CupertinoIcons.delete_solid, color: AppColors.error, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Round-Up Tab ─────────────────────────────────────────────────────────────

class _RoundUpTab extends StatefulWidget {
  final AutoTransferService transferService;
  const _RoundUpTab({required this.transferService});

  @override
  State<_RoundUpTab> createState() => _RoundUpTabState();
}

class _RoundUpTabState extends State<_RoundUpTab> {
  @override
  Widget build(BuildContext context) {
    final rules = widget.transferService.roundUpRules;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: CupertinoButton(
        onPressed: _showAddDialog,
        color: AppColors.success,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.add, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text('Add Round-Up'.tr(), style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
      body: rules.isEmpty
          ? _buildEmptyState(
              icon: CupertinoIcons.money_dollar,
              title: 'No round-up rules yet'.tr(),
              subtitle: 'Round up purchases and save the change'.tr(),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _RoundUpTile(
                rule: rules[i],
                onToggle: (v) {
                  setState(() {
                    widget.transferService.addRoundUpRule(RoundUpRule(
                      id: rules[i].id,
                      name: rules[i].name,
                      roundUpTo: rules[i].roundUpTo,
                      customAmount: rules[i].customAmount,
                      sourceWalletId: rules[i].sourceWalletId,
                      savingsWalletId: rules[i].savingsWalletId,
                      isActive: v,
                      createdAt: rules[i].createdAt,
                    ));
                  });
                },
                onDelete: () {
                  setState(() {
                    widget.transferService.removeRoundUpRule(rules[i].id);
                  });
                  context.showMascotSnackBar('Round-up rule deleted'.tr(), type: MascotSnackBarType.info);
                },
              ),
            ),
    );
  }

  void _showAddDialog() async {
    final wallets = context.read<WalletBloc>().wallets;
    if (wallets.length < 2) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text('Need More Wallets'.tr()),
          content: Text('You need at least 2 wallets to set up round-up savings.'.tr()),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: Text('OK'.tr())),
          ],
        ),
      );
      return;
    }
    final result = await showCupertinoDialog<RoundUpRule>(
      context: context,
      builder: (_) => _RoundUpDialog(wallets: wallets),
    );
    if (result != null) {
      setState(() => widget.transferService.addRoundUpRule(result));
      if (mounted) {
        context.showMascotSnackBar('Round-up rule added!'.tr(), type: MascotSnackBarType.success);
      }
    }
  }
}

class _RoundUpTile extends StatelessWidget {
  final RoundUpRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _RoundUpTile({required this.rule, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    String roundUpText;
    switch (rule.roundUpTo) {
      case RoundUpTo.nearestDollar:
        roundUpText = 'Nearest \$1';
        break;
      case RoundUpTo.nearestFive:
        roundUpText = 'Nearest \$5';
        break;
      case RoundUpTo.nearestTen:
        roundUpText = 'Nearest \$10';
        break;
      case RoundUpTo.custom:
        roundUpText = 'Nearest \$${rule.customAmount ?? '?'}';
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(CupertinoIcons.money_dollar, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.name, style: AppTypography.bodyLarge(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(roundUpText,
                      style: AppTypography.bodySmall(color: AppColors.textTertiary(context))),
                ],
              ),
            ),
            Switch(value: rule.isActive, onChanged: onToggle, activeColor: AppColors.success),
            IconButton(
              icon: Icon(CupertinoIcons.delete_solid, color: AppColors.error, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State Helper ───────────────────────────────────────────────────────

Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowMascotAvatar(size: 80, showGlow: true, showParticles: false),
          const SizedBox(height: 24),
          Icon(icon, size: 40, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title,
              style: AppTypography.titleSmall(color: AppColors.primary),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle,
              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

// ─── Smart Rule Dialog ────────────────────────────────────────────────────────

class _SmartRuleDialog extends StatefulWidget {
  final SmartRule? existing;
  const _SmartRuleDialog({this.existing});

  @override
  State<_SmartRuleDialog> createState() => _SmartRuleDialogState();
}

class _SmartRuleDialogState extends State<_SmartRuleDialog> {
  final _nameCtrl = TextEditingController();
  final _condValueCtrl = TextEditingController();
  final _actionValueCtrl = TextEditingController();

  RuleType _ruleType = RuleType.categorization;
  TransactionField _condField = TransactionField.title;
  ConditionOperator _condOp = ConditionOperator.contains;
  ActionType _actionType = ActionType.setCategory;

  final List<RuleCondition> _conditions = [];
  final List<RuleAction> _actions = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final r = widget.existing!;
      _nameCtrl.text = r.name;
      _ruleType = r.type;
      _conditions.addAll(r.conditions);
      _actions.addAll(r.actions);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _condValueCtrl.dispose();
    _actionValueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const FlowMascotAvatar(size: 36, showGlow: false),
                  const SizedBox(width: 12),
                  Text(
                    widget.existing == null ? 'Add Smart Rule'.tr() : 'Edit Rule'.tr(),
                    style: AppTypography.titleSmall(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rule name
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Rule Name'.tr(),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rule type
                      _label('Rule Type'.tr()),
                      DropdownButtonFormField<RuleType>(
                        value: _ruleType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: RuleType.values.map((t) {
                          return DropdownMenuItem(value: t, child: Text(_ruleTypeName(t).tr()));
                        }).toList(),
                        onChanged: (v) => setState(() => _ruleType = v!),
                      ),
                      const SizedBox(height: 20),

                      // Conditions section
                      _sectionHeader('Conditions'.tr(), CupertinoIcons.slider_horizontal_3),
                      const SizedBox(height: 8),
                      ..._conditions.asMap().entries.map((e) => _conditionChip(e.key, e.value)),
                      const SizedBox(height: 8),
                      _buildAddConditionRow(),
                      const SizedBox(height: 20),

                      // Actions section
                      _sectionHeader('Actions'.tr(), Icons.bolt_rounded),
                      const SizedBox(height: 8),
                      ..._actions.asMap().entries.map((e) => _actionChip(e.key, e.value)),
                      const SizedBox(height: 8),
                      _buildAddActionRow(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'.tr()),
                  ),
                  const SizedBox(width: 12),
                  AppButton.primary(
                    label: widget.existing == null ? 'Add Rule'.tr() : 'Save'.tr(),
                    onPressed: _save,
                    size: AppButtonSize.small,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTypography.labelMedium(color: AppColors.textSecondaryLight)),
    );
  }

  Widget _sectionHeader(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(text,
            style: AppTypography.labelMedium(
                color: AppColors.primary, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _conditionChip(int index, RuleCondition cond) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${cond.field.name} ${cond.operator.name} "${cond.value}"',
                style: AppTypography.labelSmall(),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _conditions.removeAt(index)),
              child: Icon(CupertinoIcons.xmark, size: 16, color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(int index, RuleAction action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${action.type.name} → "${action.value}"',
                style: AppTypography.labelSmall(),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _actions.removeAt(index)),
              child: Icon(CupertinoIcons.xmark, size: 16, color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddConditionRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<TransactionField>(
                value: _condField,
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'Field'.tr(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                items: TransactionField.values.map((f) {
                  return DropdownMenuItem(value: f, child: Text(f.name, style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (v) => setState(() => _condField = v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<ConditionOperator>(
                value: _condOp,
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'Operator'.tr(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                items: [
                  ConditionOperator.contains,
                  ConditionOperator.equals,
                  ConditionOperator.startsWith,
                  ConditionOperator.greaterThan,
                  ConditionOperator.lessThan,
                ].map((o) {
                  return DropdownMenuItem(value: o, child: Text(o.name, style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (v) => setState(() => _condOp = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _condValueCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Value'.tr(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final val = _condValueCtrl.text.trim();
                if (val.isEmpty) return;
                setState(() {
                  _conditions.add(RuleCondition(
                    field: _condField,
                    operator: _condOp,
                    value: val,
                  ));
                  _condValueCtrl.clear();
                });
              },
              icon: const Icon(CupertinoIcons.add, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddActionRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<ActionType>(
          value: _actionType,
          isDense: true,
          decoration: InputDecoration(
            labelText: 'Action Type'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
          items: [
            ActionType.setCategory,
            ActionType.setNote,
            ActionType.setType,
          ].map((a) {
            return DropdownMenuItem(value: a, child: Text(a.name));
          }).toList(),
          onChanged: (v) => setState(() => _actionType = v!),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _actionValueCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Value (e.g. Food)'.tr(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () {
                final val = _actionValueCtrl.text.trim();
                if (val.isEmpty) return;
                setState(() {
                  _actions.add(RuleAction(type: _actionType, value: val));
                  _actionValueCtrl.clear();
                });
              },
              icon: const Icon(CupertinoIcons.add, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    if (_conditions.isEmpty) return;
    if (_actions.isEmpty) return;

    final rule = SmartRule(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: name,
      type: _ruleType,
      conditions: _conditions,
      actions: _actions,
      priority: widget.existing?.priority ?? 0,
      isActive: widget.existing?.isActive ?? true,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    Navigator.pop(context, rule);
  }

  String _ruleTypeName(RuleType type) {
    switch (type) {
      case RuleType.categorization:
        return 'Categorization';
      case RuleType.tagging:
        return 'Tagging';
      case RuleType.walletAssignment:
        return 'Wallet Assignment';
      case RuleType.typeAssignment:
        return 'Type Assignment';
      case RuleType.notification:
        return 'Notification';
    }
  }
}

// ─── Auto-Transfer Dialog ─────────────────────────────────────────────────────

class _AutoTransferDialog extends StatefulWidget {
  final List<Wallet> wallets;
  const _AutoTransferDialog({required this.wallets});

  @override
  State<_AutoTransferDialog> createState() => _AutoTransferDialogState();
}

class _AutoTransferDialogState extends State<_AutoTransferDialog> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _sourceId;
  String? _destId;
  CalculationType _calcType = CalculationType.fixedAmount;
  TriggerType _triggerType = TriggerType.incomeReceived;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FlowMascotAvatar(size: 36, showGlow: false),
                    const SizedBox(width: 12),
                    Text('Add Auto-Transfer'.tr(), style: AppTypography.titleSmall()),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Rule Name'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _sourceId,
                  decoration: InputDecoration(
                    labelText: 'From Wallet'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: widget.wallets.map((w) {
                    return DropdownMenuItem(value: w.id, child: Text(w.name));
                  }).toList(),
                  onChanged: (v) => setState(() => _sourceId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _destId,
                  decoration: InputDecoration(
                    labelText: 'To Wallet'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: widget.wallets.map((w) {
                    return DropdownMenuItem(value: w.id, child: Text(w.name));
                  }).toList(),
                  onChanged: (v) => setState(() => _destId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TriggerType>(
                  value: _triggerType,
                  decoration: InputDecoration(
                    labelText: 'Trigger'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: TriggerType.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.name));
                  }).toList(),
                  onChanged: (v) => setState(() => _triggerType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CalculationType>(
                  value: _calcType,
                  decoration: InputDecoration(
                    labelText: 'Calculation'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: CalculationType.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.name));
                  }).toList(),
                  onChanged: (v) => setState(() => _calcType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        _calcType == CalculationType.percentage ? 'Percentage (%)'.tr() : 'Amount'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context), child: Text('Cancel'.tr())),
                    const SizedBox(width: 12),
                    AppButton.primary(label: 'Save'.tr(), onPressed: _save, size: AppButtonSize.small),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty ||
        _sourceId == null ||
        _destId == null ||
        _amountCtrl.text.trim().isEmpty) {
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) return;

    final rule = AutoTransferRule(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      trigger: TransferTrigger(type: _triggerType),
      sourceWalletId: _sourceId!,
      destinationWalletId: _destId!,
      calculationType: _calcType,
      amount: amount,
      createdAt: DateTime.now(),
    );
    Navigator.pop(context, rule);
  }
}

// ─── Round-Up Dialog ──────────────────────────────────────────────────────────

class _RoundUpDialog extends StatefulWidget {
  final List<Wallet> wallets;
  const _RoundUpDialog({required this.wallets});

  @override
  State<_RoundUpDialog> createState() => _RoundUpDialogState();
}

class _RoundUpDialogState extends State<_RoundUpDialog> {
  final _nameCtrl = TextEditingController();
  final _customAmtCtrl = TextEditingController();
  String? _sourceId;
  String? _savingsId;
  RoundUpTo _roundUpTo = RoundUpTo.nearestDollar;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _customAmtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FlowMascotAvatar(size: 36, showGlow: false),
                    const SizedBox(width: 12),
                    Text('Add Round-Up Rule'.tr(), style: AppTypography.titleSmall()),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Rule Name'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _sourceId,
                  decoration: InputDecoration(
                    labelText: 'Spending Wallet'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: widget.wallets.map((w) {
                    return DropdownMenuItem(value: w.id, child: Text(w.name));
                  }).toList(),
                  onChanged: (v) => setState(() => _sourceId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _savingsId,
                  decoration: InputDecoration(
                    labelText: 'Savings Wallet'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: widget.wallets.map((w) {
                    return DropdownMenuItem(value: w.id, child: Text(w.name));
                  }).toList(),
                  onChanged: (v) => setState(() => _savingsId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RoundUpTo>(
                  value: _roundUpTo,
                  decoration: InputDecoration(
                    labelText: 'Round Up To'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: RoundUpTo.values.map((t) {
                    String label;
                    switch (t) {
                      case RoundUpTo.nearestDollar:
                        label = 'Nearest \$1';
                        break;
                      case RoundUpTo.nearestFive:
                        label = 'Nearest \$5';
                        break;
                      case RoundUpTo.nearestTen:
                        label = 'Nearest \$10';
                        break;
                      case RoundUpTo.custom:
                        label = 'Custom Amount';
                        break;
                    }
                    return DropdownMenuItem(value: t, child: Text(label));
                  }).toList(),
                  onChanged: (v) => setState(() => _roundUpTo = v!),
                ),
                if (_roundUpTo == RoundUpTo.custom) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customAmtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Custom Amount'.tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context), child: Text('Cancel'.tr())),
                    const SizedBox(width: 12),
                    AppButton.primary(label: 'Save'.tr(), onPressed: _save, size: AppButtonSize.small),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty || _sourceId == null || _savingsId == null) return;

    double? customAmount;
    if (_roundUpTo == RoundUpTo.custom) {
      customAmount = double.tryParse(_customAmtCtrl.text.trim());
      if (customAmount == null || customAmount <= 0) return;
    }

    final rule = RoundUpRule(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      roundUpTo: _roundUpTo,
      customAmount: customAmount,
      sourceWalletId: _sourceId!,
      savingsWalletId: _savingsId!,
      createdAt: DateTime.now(),
    );
    Navigator.pop(context, rule);
  }
}
