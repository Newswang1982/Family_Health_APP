import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:family_health/core/providers/auth_provider.dart';
import 'package:family_health/core/providers/family_provider.dart';
import 'package:family_health/core/providers/profile_provider.dart';
import 'package:family_health/core/models/family.dart';
import 'package:family_health/core/models/profile.dart';
import 'package:family_health/core/models/user.dart';
import 'package:family_health/core/theme/app_theme.dart';
import 'package:family_health/core/api/api_client.dart';

/// Settings page with user profile, family management, member management,
/// health reference ranges, notification settings, data backup/restore, and logout.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyProvider.notifier).loadFamilies();
    });
  }

  void _createFamily() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建家庭'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Family Name',
                hintText: 'e.g. Smith Family',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              ref.read(familyProvider.notifier).createFamily(
                    name: name,
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                  );
              Navigator.of(ctx).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _joinFamily() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Family'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Invite Code',
            hintText: 'Enter the invite code',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Joining family with code: $code'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.of(ctx).pop();
              // TODO: Implement joining via API
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _addFamilyMember() {
    final nameController = TextEditingController();
    final relationController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加家庭成员'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'e.g. Mom, Dad, Child',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(
                labelText: 'Relation',
                hintText: 'e.g. spouse, child, parent',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final familyState = ref.read(familyProvider);
              final familyId =
                  familyState.selectedFamily?.id ?? familyState.families.firstOrNull?.id;
              if (familyId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select or create a family first'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.of(ctx).pop();
                return;
              }
              ref.read(profileProvider.notifier).createProfile(
                    familyId: familyId,
                    displayName: name,
                    relation: relationController.text.trim().isEmpty
                        ? null
                        : relationController.text.trim(),
                  );
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeMember(MemberProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${profile.displayName} from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(profileProvider.notifier).deleteProfile(profile.id);
    }
  }

  void _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final familyState = ref.watch(familyProvider);
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── User Profile Section ──
          _buildUserProfileSection(currentUser),

          const SizedBox(height: 8),

          // ── Family Management ──
          _buildSectionHeader('家庭管理'),
          _buildFamilyManagementSection(familyState),

          const SizedBox(height: 8),

          // ── Family Members ──
          _buildSectionHeader('家庭成员'),
          _buildFamilyMembersSection(profileState),

          const SizedBox(height: 8),

          // ── Health Reference Ranges ──
          _buildSectionHeader('健康参考值'),
          _buildMenuTile(
            icon: Icons.tune,
            title: '编辑参考值',
            subtitle: 'Customize normal ranges for health metrics',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('参考值编辑功能即将上线'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // ── Notification Settings ──
          _buildSectionHeader('通知设置'),
          _buildMenuTile(
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            subtitle: 'Manage alert preferences',
            trailing: Switch(
              value: true,
              onChanged: (val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val ? 'Notifications enabled' : 'Notifications disabled',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            onTap: () {},
          ),
          _buildMenuTile(
            icon: Icons.notifications_off_outlined,
            title: 'Quiet Hours',
            subtitle: 'Set do-not-disturb schedule',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quiet hours settings — coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // ── Data Management ──
          _buildSectionHeader('数据管理'),
          _buildMenuTile(
            icon: Icons.backup_outlined,
            title: '备份数据',
            subtitle: 'Backup health records to cloud',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup Started — coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.restore_outlined,
            title: '恢复数据',
            subtitle: 'Restore from a previous backup',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restore — coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Account Binding ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionHeader('账号关联'),
          ),
          // WeChat Binding
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF07C160).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wechat, color: Color(0xFF07C160), size: 22),
              ),
              title: const Text('微信'),
              subtitle: Text('未绑定', style: TextStyle(color: Colors.grey[500])),
              trailing: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请在登录页点击「微信登录」进行绑定'), behavior: SnackBarBehavior.floating),
                  );
                },
                child: const Text('绑定', style: TextStyle(color: Color(0xFF07C160))),
              ),
            ),
          ),
          // QQ Binding
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF12B7F5).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_bubble, color: Color(0xFF12B7F5), size: 22),
              ),
              title: const Text('QQ'),
              subtitle: Text('未绑定', style: TextStyle(color: Colors.grey[500])),
              trailing: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请在登录页点击「QQ登录」进行绑定'), behavior: SnackBarBehavior.floating),
                  );
                },
                child: const Text('绑定', style: TextStyle(color: Color(0xFF12B7F5))),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Server Settings ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionHeader('服务器设置'),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.blueLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_outlined, color: AppTheme.blue, size: 22),
              ),
              title: const Text('服务器地址'),
              subtitle: Text(ApiClient.instance.baseUrl, style: const TextStyle(fontSize: 12)),
              trailing: TextButton(
                onPressed: _showServerDialog,
                child: const Text('切换'),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Logout ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: const Text(
                'Logout',
                style: TextStyle(color: AppTheme.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(User? currentUser) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.healthGreen.withValues(alpha: 0.1),
              backgroundImage: currentUser?.avatarUrl != null
                  ? NetworkImage(currentUser!.avatarUrl!)
                  : null,
              child: currentUser?.avatarUrl == null
                  ? Text(
                      (currentUser?.username.isNotEmpty == true
                              ? currentUser!.username[0].toUpperCase()
                              : '?'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.healthGreen,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser?.username ?? 'User',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (currentUser?.phone != null)
                    Text(
                      currentUser!.phone!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  Text(
                    currentUser?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit profile — coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyManagementSection(FamilyState familyState) {
    return Column(
      children: [
        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _createFamily,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _joinFamily,
                  icon: const Icon(Icons.group_add, size: 18),
                  label: const Text('Join'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Family list
        if (familyState.families.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No families yet. Create or join one!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
          )
        else
          ...familyState.families.map(
            (family) => _buildFamilyTile(family, familyState),
          ),
      ],
    );
  }

  Widget _buildFamilyTile(Family family, FamilyState familyState) {
    final isSelected = family.id == familyState.selectedFamily?.id;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? AppTheme.healthGreen.withValues(alpha: 0.15)
              : Colors.grey.shade100,
          child: Icon(
            Icons.home,
            color: isSelected ? AppTheme.healthGreen : Colors.grey,
          ),
        ),
        title: Text(
          family.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
        subtitle: Text(
          '${family.memberCount} members · ${family.role}${family.inviteCode != null ? ' · Code: ${family.inviteCode}' : ''}',
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: AppTheme.healthGreen, size: 20)
            : null,
        onTap: () {
          ref.read(familyProvider.notifier).selectFamily(family);
          ref.read(profileProvider.notifier).loadProfiles(family.id);
        },
      ),
    );
  }

  Widget _buildFamilyMembersSection(ProfileState profileState) {
    final members = profileState.profiles;

    return Column(
      children: [
        // Add member button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addFamilyMember,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Member'),
            ),
          ),
        ),

        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No members added yet.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
          )
        else
          ...members.map((member) => _buildMemberTile(member)),
      ],
    );
  }

  Widget _buildMemberTile(MemberProfile profile) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.healthGreen.withValues(alpha: 0.1),
          backgroundImage: profile.avatarUrl != null
              ? NetworkImage(profile.avatarUrl!)
              : null,
          child: profile.avatarUrl == null
              ? Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.healthGreen,
                  ),
                )
              : null,
        ),
        title: Text(profile.displayName),
        subtitle: Text(
          [
            if (profile.relation != null) profile.relation!,
            if (profile.age != null) '${profile.age} yrs',
            if (profile.gender != null) profile.gender!,
            if (profile.bloodType != null) 'Blood: ${profile.bloodType}',
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(Icons.remove_circle_outline, color: AppTheme.error),
          onPressed: () => _removeMember(profile),
          tooltip: 'Remove member',
        ),
        onTap: () {
          ref.read(profileProvider.notifier).selectProfile(profile);
        },
      ),
    );
  }

  void _showServerDialog() {
    final controller = TextEditingController(text: ApiClient.instance.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('服务器地址'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('切换服务器地址以连接本地或云端后端', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API 地址',
                hintText: 'http://your-server:8080/api/v1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('本地'),
                  onPressed: () {
                    controller.text = 'http://localhost:8080/api/v1';
                  },
                ),
                ActionChip(
                  label: const Text('云端'),
                  onPressed: () {
                    controller.text = 'https://your-api.com/api/v1';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              ApiClient.instance.setBaseUrl(controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已切换至: ${controller.text.trim()}'), behavior: SnackBarBehavior.floating),
              );
              setState(() {});
            },
            child: const Text('切换'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.healthGreen),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
