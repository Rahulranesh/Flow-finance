import 'package:flutter/material.dart';

/// Financial goal model
class Goal {
  final String id;
  final String name;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final Color color;
  final IconData icon;
  final String category;
  final bool isCompleted;

  Goal({
    required this.id,
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.createdAt,
    required this.color,
    required this.icon,
    required this.category,
    this.isCompleted = false,
  });

  /// Calculate progress percentage
  double get progress {
    if (targetAmount <= 0) return 0;
    final percentage = (currentAmount / targetAmount) * 100;
    return percentage.clamp(0, 100);
  }

  /// Calculate remaining amount
  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0, targetAmount);
  }

  /// Calculate days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (targetDate.isBefore(now)) return 0;
    return targetDate.difference(now).inDays;
  }

  /// Check if goal is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && !isCompleted;
  }

  /// Copy with method
  Goal copyWith({
    String? id,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    Color? color,
    IconData? icon,
    String? category,
    bool? isCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'colorValue': color.value,
      'iconCodePoint': icon.codePoint,
      'category': category,
      'isCompleted': isCompleted,
    };
  }

  /// Create from JSON
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      targetDate: DateTime.parse(json['targetDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      color: Color(json['colorValue'] as int),
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      category: json['category'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

/// Goal category enum
enum GoalCategory {
  savings,
  investment,
  purchase,
  travel,
  education,
  emergency,
  retirement,
  other;

  String get displayName {
    switch (this) {
      case GoalCategory.savings:
        return 'Savings';
      case GoalCategory.investment:
        return 'Investment';
      case GoalCategory.purchase:
        return 'Purchase';
      case GoalCategory.travel:
        return 'Travel';
      case GoalCategory.education:
        return 'Education';
      case GoalCategory.emergency:
        return 'Emergency Fund';
      case GoalCategory.retirement:
        return 'Retirement';
      case GoalCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalCategory.savings:
        return Icons.savings;
      case GoalCategory.investment:
        return Icons.trending_up;
      case GoalCategory.purchase:
        return Icons.shopping_bag;
      case GoalCategory.travel:
        return Icons.flight;
      case GoalCategory.education:
        return Icons.school;
      case GoalCategory.emergency:
        return Icons.emergency;
      case GoalCategory.retirement:
        return Icons.elderly;
      case GoalCategory.other:
        return Icons.flag;
    }
  }
}
