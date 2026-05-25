import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/repositories/goal_repository.dart';

/// Goals screen for managing financial goals
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await context.read<GoalRepository>().getGoals();
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _isLoading = false;
    });
  }

  Future<void> _showGoalEditor([Goal? goal]) async {
    final nameController = TextEditingController(text: goal?.name ?? '');
    final descriptionController =
        TextEditingController(text: goal?.description ?? '');
    final targetController = TextEditingController(
      text: goal?.targetAmount.toStringAsFixed(0) ?? '',
    );
    final currentController = TextEditingController(
      text: goal?.currentAmount.toStringAsFixed(0) ?? '',
    );
    GoalCategory selectedCategory = goal != null
        ? GoalRepository.categoryFromLabel(goal.category)
        : GoalCategory.savings;
    DateTime selectedDate =
        goal?.targetDate ?? DateTime.now().add(const Duration(days: 90));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                goal == null ? 'Create Goal'.tr() : 'Update Goal'.tr(),
                style: AppTypography.headlineSmall(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Goal name'.tr()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'.tr()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GoalCategory>(
                value: selectedCategory,
                items: GoalCategory.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => selectedCategory = value);
                  }
                },
                decoration: InputDecoration(labelText: 'Category'.tr()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: currentController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(labelText: 'Current amount'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: targetController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(labelText: 'Target amount'.tr()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Target date'.tr()),
                subtitle: Text(selectedDate.toLongDate()),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDate: selectedDate,
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              AppButton.primary(
                label: goal == null ? 'Save Goal'.tr() : 'Update Goal'.tr(),
                expanded: true,
                onPressed: () async {
                  final target = double.tryParse(targetController.text);
                  final current = double.tryParse(currentController.text) ?? 0;
                  if (nameController.text.trim().isEmpty ||
                      target == null ||
                      target <= 0) {
                    context.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Enter a valid goal name and target amount'.tr(),
                        ),
                      ),
                    );
                    return;
                  }

                  final newGoal = Goal(
                    id: goal?.id ?? const Uuid().v4(),
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    targetAmount: target,
                    currentAmount: current,
                    targetDate: selectedDate,
                    createdAt: goal?.createdAt ?? DateTime.now(),
                    color: GoalRepository.colorForCategory(selectedCategory),
                    icon: selectedCategory.icon,
                    category: selectedCategory.displayName,
                    isCompleted: current >= target,
                  );

                  if (goal == null) {
                    await context.read<GoalRepository>().addGoal(newGoal);
                  } else {
                    await context.read<GoalRepository>().updateGoal(newGoal);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    await _loadGoals();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Goals'.tr(),
      actions: [
        AppIconButton(
          icon: Icons.add,
          onPressed: () => _showGoalEditor(),
          variant: AppIconButtonVariant.filled,
        ),
        const SizedBox(width: 16),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: FlowMascotBubble(
                    message: 'Let\'s make one goal feel exciting.'.tr(),
                    subtitle: 'I\'ll celebrate when you get close.'.tr(),
                    actionLabel: 'Create Goal'.tr(),
                    onAction: () => _showGoalEditor(),
                  ),
                ),
                Expanded(
                  child: _goals.isEmpty
                      ? Center(
                          child: AppEmptyState(
                            icon: Icons.flag,
                            title: 'No goals yet'.tr(),
                            subtitle: 'Create your first financial goal'.tr(),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _goals.length,
                          itemBuilder: (context, index) {
                            final goal = _goals[index];
                            return _GoalCard(
                              goal: goal,
                              onRefresh: _loadGoals,
                              onEdit: () => _showGoalEditor(goal),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/// Goal card widget
class _GoalCard extends StatelessWidget {
  final Goal goal;
  final Future<void> Function() onRefresh;
  final VoidCallback onEdit;

  const _GoalCard({
    required this.goal,
    required this.onRefresh,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      onTap: () {
        _showGoalDetails(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: goal.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  goal.icon,
                  color: goal.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: AppTypography.titleMedium(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.category,
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: goal.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${goal.progress.toStringAsFixed(0)}%',
                  style: AppTypography.labelMedium(color: goal.color),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progress / 100,
              minHeight: 8,
              backgroundColor: goal.color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
            ),
          ),

          const SizedBox(height: 16),

          // Amount info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current'.tr(),
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${goal.currentAmount.toStringAsFixed(0)}',
                    style: AppTypography.titleSmall(),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Target'.tr(),
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${goal.targetAmount.toStringAsFixed(0)}',
                    style: AppTypography.titleSmall(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Days remaining
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.textSecondary(context),
              ),
              const SizedBox(width: 8),
              Text(
                '${goal.daysRemaining} ${'days remaining'.tr()}',
                style: AppTypography.bodySmall(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGoalDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.name, style: AppTypography.headlineSmall(), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(
                '${goal.currentAmount.toCurrency()} of ${goal.targetAmount.toCurrency()}',
                style: AppTypography.titleLarge(color: goal.color),
              ),
              const SizedBox(height: 16),
              Text(goal.description.isEmpty
                  ? 'No description added.'.tr()
                  : goal.description),
              const SizedBox(height: 16),
              Text('${'Category'.tr()}: ${goal.category}'),
              const SizedBox(height: 8),
              Text('${'Target date'.tr()}: ${goal.targetDate.toLongDate()}'),
              const SizedBox(height: 8),
              Text('${'Remaining'.tr()}: ${goal.remainingAmount.toCurrency()}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: 'Edit'.tr(),
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.danger(
                      label: 'Delete'.tr(),
                      onPressed: () async {
                        await context
                            .read<GoalRepository>()
                            .deleteGoal(goal.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          await onRefresh();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
