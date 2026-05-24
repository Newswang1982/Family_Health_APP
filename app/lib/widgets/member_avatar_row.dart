import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_health/core/providers/profile_provider.dart';
import 'package:family_health/core/models/profile.dart';
import 'package:family_health/core/theme/app_theme.dart';

/// Horizontal scrolling row of member avatars with names.
///
/// Features:
/// - Horizontal scrolling row of circular avatars with names
/// - First item is a "+ 添加" (Add) button
/// - Selected member highlighted with a colored border
/// - Uses [profileProvider] to read profiles and selection state
/// - Calls [onAddTap] and [onProfileTap] callbacks for actions
class MemberAvatarRow extends ConsumerWidget {
  /// Called when the "+ Add" button is tapped.
  final VoidCallback? onAddTap;

  /// Called when a profile avatar is tapped.
  /// Defaults to selecting the profile via [ProfileNotifier.selectProfile].
  final void Function(MemberProfile profile)? onProfileTap;

  /// Optional custom list of profiles (defaults to [ProfileState.profiles]).
  final List<MemberProfile>? profiles;

  /// Optional custom selected profile (defaults to [ProfileState.selectedProfile]).
  final MemberProfile? selectedProfile;

  const MemberAvatarRow({
    super.key,
    this.onAddTap,
    this.onProfileTap,
    this.profiles,
    this.selectedProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final displayProfiles = profiles ?? profileState.profiles;
    final displaySelected = selectedProfile ?? profileState.selectedProfile;

    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: displayProfiles.length + 1, // +1 for the Add button
        itemBuilder: (context, index) {
          // First item: Add button
          if (index == 0) {
            return _AddMemberButton(
              onTap: onAddTap ?? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('添加家庭成员 - 请前往设置页面'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          }

          final profile = displayProfiles[index - 1];
          final isSelected = profile.id == displaySelected?.id;

          return _MemberAvatar(
            profile: profile,
            isSelected: isSelected,
            onTap: () {
              if (onProfileTap != null) {
                onProfileTap!(profile);
              } else {
                ref.read(profileProvider.notifier).selectProfile(profile);
              }
            },
          );
        },
      ),
    );
  }
}

/// The "+ Add" member button shown as the first item.
class _AddMemberButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMemberButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.healthGreen.withValues(alpha: 0.1),
              child: const Icon(
                Icons.add,
                color: AppTheme.healthGreen,
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '添加',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.healthGreen,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single member avatar with name.
class _MemberAvatar extends StatelessWidget {
  final MemberProfile profile;
  final bool isSelected;
  final VoidCallback onTap;

  const _MemberAvatar({
    required this.profile,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.healthGreen : Colors.transparent,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: isSelected ? 22 : 24,
                backgroundColor: isSelected
                    ? AppTheme.healthGreen.withValues(alpha: 0.15)
                    : Colors.grey.shade200,
                child: profile.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          profile.avatarUrl!,
                          fit: BoxFit.cover,
                          width: 48,
                          height: 48,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.person),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 24,
                        color: isSelected
                            ? AppTheme.healthGreen
                            : Colors.grey.shade500,
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.healthGreen : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
