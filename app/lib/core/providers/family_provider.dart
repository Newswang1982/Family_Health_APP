import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import '../models/family.dart';

// ── Family State ──

/// Represents the family management state.
class FamilyState {
  final List<Family> families;
  final Family? selectedFamily;
  final bool isLoading;
  final String? error;

  const FamilyState({
    this.families = const [],
    this.selectedFamily,
    this.isLoading = false,
    this.error,
  });

  FamilyState copyWith({
    List<Family>? families,
    Family? selectedFamily,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FamilyState(
      families: families ?? this.families,
      selectedFamily: selectedFamily ?? this.selectedFamily,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyState &&
          families == other.families &&
          selectedFamily == other.selectedFamily &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => Object.hash(families, selectedFamily, isLoading, error);
}

// ── Family Notifier ──

/// Manages CRUD operations for families.
class FamilyNotifier extends StateNotifier<FamilyState> {
  FamilyNotifier() : super(const FamilyState());

  /// Load all families for the current user.
  Future<void> loadFamilies() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      // final response = await dio.get('/families');
      // final families = (response.data as List)
      //     .map((e) => Family.fromJson(e as Map<String, dynamic>))
      //     .toList();

      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
        families: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load families: $e',
      );
    }
  }

  /// Create a new family.
  Future<void> createFamily({
    required String name,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      // final response = await dio.post('/families', data: { ... });
      // final family = Family.fromJson(response.data);

      await Future.delayed(const Duration(milliseconds: 300));

      final newFamily = Family(
        id: DateTime.now().millisecondsSinceEpoch,
        name: name,
        description: description,
        memberCount: 1,
        role: 'owner',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        families: [...state.families, newFamily],
        selectedFamily: state.selectedFamily ?? newFamily,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create family: $e',
      );
    }
  }

  /// Update a family's details.
  Future<void> updateFamily({
    required int familyId,
    String? name,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedFamilies = state.families.map((f) {
        if (f.id == familyId) {
          return f.copyWith(
            name: name ?? f.name,
            description: description ?? f.description,
          );
        }
        return f;
      }).toList();

      state = state.copyWith(
        families: updatedFamilies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update family: $e',
      );
    }
  }

  /// Delete a family.
  Future<void> deleteFamily(int familyId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(
        families: state.families.where((f) => f.id != familyId).toList(),
        selectedFamily:
            state.selectedFamily?.id == familyId ? null : state.selectedFamily,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete family: $e',
      );
    }
  }

  /// Select a family as the current active family.
  void selectFamily(Family family) {
    state = state.copyWith(selectedFamily: family);
  }

  /// Clear any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ── Provider ──

final familyProvider =
    StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  return FamilyNotifier();
});
