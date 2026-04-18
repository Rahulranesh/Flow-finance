import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/family_model.dart';

/// Repository for managing family/shared budget groups
class FamilyRepository {
  static const String _familiesKey = 'families';
  static const String _invitationsKey = 'family_invitations';
  static const String _currentFamilyIdKey = 'current_family_id';

  final SharedPreferences _prefs;

  FamilyRepository(this._prefs);

  /// Get all families for the current user
  Future<List<Family>> getFamilies(String userId) async {
    final jsonString = _prefs.getString(_familiesKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final families = jsonList
          .map((json) => Family.fromJson(json as Map<String, dynamic>))
          .where((family) => family.isMember(userId))
          .toList();
      return families;
    } catch (e) {
      return [];
    }
  }

  /// Get a specific family by ID
  Future<Family?> getFamily(String familyId) async {
    final families = await getAllFamilies();
    try {
      return families.firstWhere((f) => f.id == familyId);
    } catch (_) {
      return null;
    }
  }

  /// Get all families (for admin purposes)
  Future<List<Family>> getAllFamilies() async {
    final jsonString = _prefs.getString(_familiesKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => Family.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Create a new family
  Future<Family> createFamily({
    required String id,
    required String name,
    String? description,
    required String createdBy,
    List<FamilyMember> members = const [],
  }) async {
    final family = Family(
      id: id,
      name: name,
      description: description,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      members: members,
    );

    final families = await getAllFamilies();
    families.add(family);
    await _saveFamilies(families);

    return family;
  }

  /// Update a family
  Future<Family> updateFamily(Family family) async {
    final families = await getAllFamilies();
    final index = families.indexWhere((f) => f.id == family.id);

    if (index >= 0) {
      families[index] = family;
      await _saveFamilies(families);
      return family;
    } else {
      throw Exception('Family not found');
    }
  }

  /// Delete a family
  Future<void> deleteFamily(String familyId) async {
    final families = await getAllFamilies();
    families.removeWhere((f) => f.id == familyId);
    await _saveFamilies(families);

    // Clear current family if it was deleted
    final currentId = _prefs.getString(_currentFamilyIdKey);
    if (currentId == familyId) {
      await _prefs.remove(_currentFamilyIdKey);
    }
  }

  /// Add a member to a family
  Future<Family> addMember(String familyId, FamilyMember member) async {
    final family = await getFamily(familyId);
    if (family == null) throw Exception('Family not found');

    final updatedMembers = [...family.members, member];
    final updatedFamily = family.copyWith(members: updatedMembers);

    return updateFamily(updatedFamily);
  }

  /// Remove a member from a family
  Future<Family> removeMember(String familyId, String userId) async {
    final family = await getFamily(familyId);
    if (family == null) throw Exception('Family not found');

    final updatedMembers = family.members
        .where((m) => m.userId != userId)
        .toList();

    final updatedFamily = family.copyWith(members: updatedMembers);
    return updateFamily(updatedFamily);
  }

  /// Update member role
  Future<Family> updateMemberRole(
    String familyId,
    String userId,
    FamilyRole newRole,
  ) async {
    final family = await getFamily(familyId);
    if (family == null) throw Exception('Family not found');

    final updatedMembers = family.members.map((m) {
      if (m.userId == userId) {
        return m.copyWith(role: newRole);
      }
      return m;
    }).toList();

    final updatedFamily = family.copyWith(members: updatedMembers);
    return updateFamily(updatedFamily);
  }

  /// Add or update a budget
  Future<Family> setBudget(String familyId, FamilyBudget budget) async {
    final family = await getFamily(familyId);
    if (family == null) throw Exception('Family not found');

    final existingIndex = family.budgets.indexWhere((b) => b.category == budget.category);
    List<FamilyBudget> updatedBudgets;

    if (existingIndex >= 0) {
      updatedBudgets = [...family.budgets];
      updatedBudgets[existingIndex] = budget;
    } else {
      updatedBudgets = [...family.budgets, budget];
    }

    final updatedFamily = family.copyWith(budgets: updatedBudgets);
    return updateFamily(updatedFamily);
  }

  /// Remove a budget
  Future<Family> removeBudget(String familyId, String category) async {
    final family = await getFamily(familyId);
    if (family == null) throw Exception('Family not found');

    final updatedBudgets = family.budgets
        .where((b) => b.category != category)
        .toList();

    final updatedFamily = family.copyWith(budgets: updatedBudgets);
    return updateFamily(updatedFamily);
  }

  /// Update budget spent amount
  Future<Family> updateBudgetSpent(
    String familyId,
    String category,
    double spentAmount,
  ) async {
    final family = await getFamily(familyId);
    if (family == null) throw Exception('Family not found');

    final updatedBudgets = family.budgets.map((b) {
      if (b.category == category) {
        return b.copyWith(spentAmount: spentAmount);
      }
      return b;
    }).toList();

    final updatedFamily = family.copyWith(budgets: updatedBudgets);
    return updateFamily(updatedFamily);
  }

  /// Set current active family
  Future<void> setCurrentFamily(String? familyId) async {
    if (familyId == null) {
      await _prefs.remove(_currentFamilyIdKey);
    } else {
      await _prefs.setString(_currentFamilyIdKey, familyId);
    }
  }

  /// Get current active family ID
  String? getCurrentFamilyId() {
    return _prefs.getString(_currentFamilyIdKey);
  }

  /// Get current active family
  Future<Family?> getCurrentFamily(String userId) async {
    final familyId = getCurrentFamilyId();
    if (familyId == null) return null;

    final family = await getFamily(familyId);
    if (family != null && family.isMember(userId)) {
      return family;
    }
    return null;
  }

  /// Create an invitation
  Future<FamilyInvitation> createInvitation({
    required String id,
    required String familyId,
    required String familyName,
    required String invitedBy,
    required String invitedByName,
    required String email,
    required FamilyRole role,
  }) async {
    final invitation = FamilyInvitation(
      id: id,
      familyId: familyId,
      familyName: familyName,
      invitedBy: invitedBy,
      invitedByName: invitedByName,
      email: email,
      role: role,
      sentAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    final invitations = await getAllInvitations();
    invitations.add(invitation);
    await _saveInvitations(invitations);

    return invitation;
  }

  /// Get invitations for an email
  Future<List<FamilyInvitation>> getInvitationsForEmail(String email) async {
    final allInvitations = await getAllInvitations();
    return allInvitations
        .where((i) => i.email.toLowerCase() == email.toLowerCase() && i.isPending)
        .toList();
  }

  /// Get all invitations
  Future<List<FamilyInvitation>> getAllInvitations() async {
    final jsonString = _prefs.getString(_invitationsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => FamilyInvitation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Accept an invitation
  Future<FamilyInvitation> acceptInvitation(String invitationId) async {
    final invitations = await getAllInvitations();
    final index = invitations.indexWhere((i) => i.id == invitationId);

    if (index >= 0) {
      invitations[index] = invitations[index].copyWith(isAccepted: true);
      await _saveInvitations(invitations);
      return invitations[index];
    } else {
      throw Exception('Invitation not found');
    }
  }

  /// Decline an invitation
  Future<FamilyInvitation> declineInvitation(String invitationId) async {
    final invitations = await getAllInvitations();
    final index = invitations.indexWhere((i) => i.id == invitationId);

    if (index >= 0) {
      invitations[index] = invitations[index].copyWith(isDeclined: true);
      await _saveInvitations(invitations);
      return invitations[index];
    } else {
      throw Exception('Invitation not found');
    }
  }

  /// Cancel an invitation
  Future<void> cancelInvitation(String invitationId) async {
    final invitations = await getAllInvitations();
    invitations.removeWhere((i) => i.id == invitationId);
    await _saveInvitations(invitations);
  }

  // Private helper methods

  Future<void> _saveFamilies(List<Family> families) async {
    final jsonList = families.map((f) => f.toJson()).toList();
    await _prefs.setString(_familiesKey, jsonEncode(jsonList));
  }

  Future<void> _saveInvitations(List<FamilyInvitation> invitations) async {
    final jsonList = invitations.map((i) => i.toJson()).toList();
    await _prefs.setString(_invitationsKey, jsonEncode(jsonList));
  }
}
