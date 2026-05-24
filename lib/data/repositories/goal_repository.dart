import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import 'settings_repository.dart';

/// Goal persistence backed by the shared settings key-value store.
class GoalRepository {
  GoalRepository(this._settingsRepository);

  static const _storageKey = 'financial_goals';

  final SettingsRepository _settingsRepository;

  Future<List<Goal>> getGoals() async {
    final raw = await _settingsRepository.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Goal.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  }

  Future<void> saveGoals(List<Goal> goals) async {
    final json = jsonEncode(goals.map((goal) => goal.toJson()).toList());
    await _settingsRepository.setString(_storageKey, json);
  }

  Future<void> addGoal(Goal goal) async {
    final goals = await getGoals();
    goals.add(goal);
    await saveGoals(goals);
  }

  Future<void> updateGoal(Goal goal) async {
    final goals = await getGoals();
    final index = goals.indexWhere((item) => item.id == goal.id);
    if (index == -1) {
      goals.add(goal);
    } else {
      goals[index] = goal;
    }
    await saveGoals(goals);
  }

  Future<void> deleteGoal(String id) async {
    final goals = await getGoals();
    goals.removeWhere((goal) => goal.id == id);
    await saveGoals(goals);
  }

  static GoalCategory categoryFromLabel(String label) {
    return GoalCategory.values.firstWhere(
      (item) => item.displayName == label,
      orElse: () => GoalCategory.other,
    );
  }

  static Color colorForCategory(GoalCategory category) {
    switch (category) {
      case GoalCategory.savings:
        return const Color(0xFF22C55E);
      case GoalCategory.investment:
        return const Color(0xFF3B82F6);
      case GoalCategory.purchase:
        return const Color(0xFFF59E0B);
      case GoalCategory.travel:
        return const Color(0xFF8B5CF6);
      case GoalCategory.education:
        return const Color(0xFF14B8A6);
      case GoalCategory.emergency:
        return const Color(0xFFEF4444);
      case GoalCategory.retirement:
        return const Color(0xFF6366F1);
      case GoalCategory.other:
        return const Color(0xFF64748B);
    }
  }
}
