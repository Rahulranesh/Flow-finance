/// Member role in a family group
enum FamilyRole {
  owner,
  admin,
  member,
  viewer,
}

/// Permission level for family members
enum PermissionLevel {
  full,      // Can do everything including manage members
  edit,      // Can add/edit transactions
  view,      // Can only view
  none,      // No access
}

extension FamilyRoleExtension on FamilyRole {
  String get displayName {
    switch (this) {
      case FamilyRole.owner:
        return 'Owner';
      case FamilyRole.admin:
        return 'Admin';
      case FamilyRole.member:
        return 'Member';
      case FamilyRole.viewer:
        return 'Viewer';
    }
  }

  PermissionLevel get permissions {
    switch (this) {
      case FamilyRole.owner:
        return PermissionLevel.full;
      case FamilyRole.admin:
        return PermissionLevel.edit;
      case FamilyRole.member:
        return PermissionLevel.edit;
      case FamilyRole.viewer:
        return PermissionLevel.view;
    }
  }
}

/// Family member model
class FamilyMember {
  final String id;
  final String userId;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final FamilyRole role;
  final DateTime joinedAt;
  final bool isActive;

  const FamilyMember({
    required this.id,
    required this.userId,
    required this.displayName,
    this.email,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
  });

  FamilyMember copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? email,
    String? avatarUrl,
    FamilyRole? role,
    DateTime? joinedAt,
    bool? isActive,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: FamilyRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => FamilyRole.member,
      ),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Budget allocation for a family
class FamilyBudget {
  final String category;
  final double allocatedAmount;
  final double spentAmount;
  final String? assignedTo; // User ID of member responsible

  const FamilyBudget({
    required this.category,
    required this.allocatedAmount,
    this.spentAmount = 0,
    this.assignedTo,
  });

  double get remainingAmount => allocatedAmount - spentAmount;
  double get percentageUsed => allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0;
  bool get isOverBudget => spentAmount > allocatedAmount;

  FamilyBudget copyWith({
    String? category,
    double? allocatedAmount,
    double? spentAmount,
    String? assignedTo,
  }) {
    return FamilyBudget(
      category: category ?? this.category,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      'assignedTo': assignedTo,
    };
  }

  factory FamilyBudget.fromJson(Map<String, dynamic> json) {
    return FamilyBudget(
      category: json['category'] as String,
      allocatedAmount: (json['allocatedAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0,
      assignedTo: json['assignedTo'] as String?,
    );
  }
}

/// Family/Shared budget group model
class Family {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String createdBy;
  final DateTime createdAt;
  final List<FamilyMember> members;
  final List<FamilyBudget> budgets;
  final bool isActive;
  final bool shareAllTransactions;
  final bool requireApproval;
  final double? monthlyBudgetLimit;

  const Family({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.createdBy,
    required this.createdAt,
    required this.members,
    this.budgets = const [],
    this.isActive = true,
    this.shareAllTransactions = true,
    this.requireApproval = false,
    this.monthlyBudgetLimit,
  });

  /// Get total allocated budget
  double get totalAllocatedBudget {
    return budgets.fold(0, (sum, b) => sum + b.allocatedAmount);
  }

  /// Get total spent amount
  double get totalSpent {
    return budgets.fold(0, (sum, b) => sum + b.spentAmount);
  }

  /// Get remaining budget
  double get remainingBudget => totalAllocatedBudget - totalSpent;

  /// Get owner of the family
  FamilyMember? get owner {
    try {
      return members.firstWhere((m) => m.role == FamilyRole.owner);
    } catch (_) {
      return null;
    }
  }

  /// Get active members only
  List<FamilyMember> get activeMembers {
    return members.where((m) => m.isActive).toList();
  }

  /// Check if user is a member
  bool isMember(String userId) {
    return members.any((m) => m.userId == userId && m.isActive);
  }

  /// Get member by user ID
  FamilyMember? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Check if user has specific permission
  bool hasPermission(String userId, PermissionLevel requiredLevel) {
    final member = getMember(userId);
    if (member == null || !member.isActive) return false;

    final userPermission = member.role.permissions;
    switch (requiredLevel) {
      case PermissionLevel.full:
        return userPermission == PermissionLevel.full;
      case PermissionLevel.edit:
        return userPermission == PermissionLevel.full ||
               userPermission == PermissionLevel.edit;
      case PermissionLevel.view:
        return userPermission != PermissionLevel.none;
      case PermissionLevel.none:
        return true;
    }
  }

  Family copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    String? createdBy,
    DateTime? createdAt,
    List<FamilyMember>? members,
    List<FamilyBudget>? budgets,
    bool? isActive,
    bool? shareAllTransactions,
    bool? requireApproval,
    double? monthlyBudgetLimit,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      budgets: budgets ?? this.budgets,
      isActive: isActive ?? this.isActive,
      shareAllTransactions: shareAllTransactions ?? this.shareAllTransactions,
      requireApproval: requireApproval ?? this.requireApproval,
      monthlyBudgetLimit: monthlyBudgetLimit ?? this.monthlyBudgetLimit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'members': members.map((m) => m.toJson()).toList(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
      'isActive': isActive,
      'shareAllTransactions': shareAllTransactions,
      'requireApproval': requireApproval,
      'monthlyBudgetLimit': monthlyBudgetLimit,
    };
  }

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      members: (json['members'] as List)
          .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      budgets: (json['budgets'] as List?)
          ?.map((b) => FamilyBudget.fromJson(b as Map<String, dynamic>))
          .toList() ?? [],
      isActive: json['isActive'] as bool? ?? true,
      shareAllTransactions: json['shareAllTransactions'] as bool? ?? true,
      requireApproval: json['requireApproval'] as bool? ?? false,
      monthlyBudgetLimit: (json['monthlyBudgetLimit'] as num?)?.toDouble(),
    );
  }
}

/// Invitation to join a family
class FamilyInvitation {
  final String id;
  final String familyId;
  final String familyName;
  final String invitedBy;
  final String invitedByName;
  final String email;
  final FamilyRole role;
  final DateTime sentAt;
  final DateTime expiresAt;
  final bool isAccepted;
  final bool isDeclined;

  const FamilyInvitation({
    required this.id,
    required this.familyId,
    required this.familyName,
    required this.invitedBy,
    required this.invitedByName,
    required this.email,
    required this.role,
    required this.sentAt,
    required this.expiresAt,
    this.isAccepted = false,
    this.isDeclined = false,
  });

  bool get isPending => !isAccepted && !isDeclined && DateTime.now().isBefore(expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  FamilyInvitation copyWith({
    String? id,
    String? familyId,
    String? familyName,
    String? invitedBy,
    String? invitedByName,
    String? email,
    FamilyRole? role,
    DateTime? sentAt,
    DateTime? expiresAt,
    bool? isAccepted,
    bool? isDeclined,
  }) {
    return FamilyInvitation(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedByName: invitedByName ?? this.invitedByName,
      email: email ?? this.email,
      role: role ?? this.role,
      sentAt: sentAt ?? this.sentAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isAccepted: isAccepted ?? this.isAccepted,
      isDeclined: isDeclined ?? this.isDeclined,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'familyName': familyName,
      'invitedBy': invitedBy,
      'invitedByName': invitedByName,
      'email': email,
      'role': role.name,
      'sentAt': sentAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isAccepted': isAccepted,
      'isDeclined': isDeclined,
    };
  }

  factory FamilyInvitation.fromJson(Map<String, dynamic> json) {
    return FamilyInvitation(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      familyName: json['familyName'] as String,
      invitedBy: json['invitedBy'] as String,
      invitedByName: json['invitedByName'] as String,
      email: json['email'] as String,
      role: FamilyRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => FamilyRole.member,
      ),
      sentAt: DateTime.parse(json['sentAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isAccepted: json['isAccepted'] as bool? ?? false,
      isDeclined: json['isDeclined'] as bool? ?? false,
    );
  }
}
