import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';

// ── Profile State ──

/// Represents the profile management state.
class ProfileState {
  final List<MemberProfile> profiles;
  final MemberProfile? selectedProfile;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profiles = const [],
    this.selectedProfile,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    List<MemberProfile>? profiles,
    MemberProfile? selectedProfile,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      profiles: profiles ?? this.profiles,
      selectedProfile: selectedProfile ?? this.selectedProfile,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileState &&
          profiles == other.profiles &&
          selectedProfile == other.selectedProfile &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode =>
      Object.hash(profiles, selectedProfile, isLoading, error);
}

// ── Profile Notifier ──

/// Manages CRUD operations for member profiles within the selected family.
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState());

  /// Load all profiles for a given family.
  Future<void> loadProfiles(int familyId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      // final response = await dio.get('/families/$familyId/profiles');
      // final profiles = (response.data as List)
      //     .map((e) => MemberProfile.fromJson(e as Map<String, dynamic>))
      //     .toList();

      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(profiles: [], isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profiles: $e',
      );
    }
  }

  /// Create a new profile in the given family.
  Future<void> createProfile({
    required int familyId,
    required String displayName,
    String? relation,
    DateTime? birthDate,
    String? gender,
    double? heightCm,
    double? weightKg,
    List<String>? chronicConditions,
    List<String>? allergies,
    String? bloodType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      final newProfile = MemberProfile(
        id: DateTime.now().millisecondsSinceEpoch,
        familyId: familyId,
        displayName: displayName,
        relation: relation,
        birthDate: birthDate,
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
        chronicConditions: chronicConditions,
        allergies: allergies,
        bloodType: bloodType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        profiles: [...state.profiles, newProfile],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create profile: $e',
      );
    }
  }

  /// Update an existing profile.
  Future<void> updateProfile({
    required int profileId,
    String? displayName,
    String? relation,
    DateTime? birthDate,
    String? gender,
    double? heightCm,
    double? weightKg,
    List<String>? chronicConditions,
    List<String>? allergies,
    String? bloodType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(
        profiles: state.profiles.map((p) {
          if (p.id == profileId) {
            return p.copyWith(
              displayName: displayName,
              relation: relation,
              birthDate: birthDate,
              gender: gender,
              heightCm: heightCm,
              weightKg: weightKg,
              chronicConditions: chronicConditions,
              allergies: allergies,
              bloodType: bloodType,
              updatedAt: DateTime.now(),
            );
          }
          return p;
        }).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile: $e',
      );
    }
  }

  /// Delete a profile.
  Future<void> deleteProfile(int profileId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(
        profiles: state.profiles.where((p) => p.id != profileId).toList(),
        selectedProfile: state.selectedProfile?.id == profileId
            ? null
            : state.selectedProfile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete profile: $e',
      );
    }
  }

  /// Select a profile as the current active profile.
  void selectProfile(MemberProfile profile) {
    state = state.copyWith(selectedProfile: profile);
  }

  /// Clear any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ── Provider ──

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
