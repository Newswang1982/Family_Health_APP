import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:core';
import 'package:family_health/core/api/record_api.dart';
import 'package:family_health/core/providers/auth_provider.dart';
import 'package:family_health/core/providers/profile_provider.dart';
import 'package:family_health/core/theme/app_theme.dart';
import 'package:family_health/core/models/profile.dart';
import 'package:family_health/core/api/api_client.dart';
import 'package:family_health/pages/auth/login_page.dart' as login;
import 'package:family_health/widgets/record_entry_grid.dart';
import 'package:family_health/widgets/member_avatar_row.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List<Map<String, dynamic>> _recentRecords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profileState = ref.read(profileProvider);
      final pid = profileState.selectedProfile?.id?.toString();
      if (pid != null) {
        final records = await ref.read(recordApiProvider).queryRecords(
          memberProfileId: pid,
          limit: 10,
        );
        if (mounted) setState(() => _recentRecords = records.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = ref.watch(currentUserProvider);
    final userDisplayName = user?.displayName ?? '用户';

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Gradient Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.healthGreen,
                      AppTheme.healthGreenDark.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: greeting + notification bell
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$userDisplayName，早上好 ☀️',
                                  style: const TextStyle(
                                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${DateTime.now().month}月${DateTime.now().day}日',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7), fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _SettingsPage())),
                                ),
                                Positioned(
                                  right: 8, top: 6,
                                  child: Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.orange, shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Today's quick stats row
                        Row(
                          children: [
                            _buildStatChip(Icons.favorite, '心率', '72', '次/分'),
                            const SizedBox(width: 12),
                            _buildStatChip(Icons.directions_walk, '步数', '6,842', '步'),
                            const SizedBox(width: 12),
                            _buildStatChip(Icons.bedtime, '睡眠', '7.5', '小时'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Body Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Family Members
                _sectionLabel('家庭成员'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: MemberAvatarRow(
                    profiles: profileState.profiles,
                    selectedProfile: profileState.selectedProfile,
                    onProfileTap: (p) => ref.read(profileProvider.notifier).selectProfile(p),
                    onAddTap: () => _showAddMemberDialog(context, ref),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Record Grid
                _sectionLabel('快速记录'),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: RecordEntryGrid(
                      selectedProfileId: profileState.selectedProfile?.id,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Device Status
                _sectionLabel('智能设备'),
                const SizedBox(height: 8),
                _deviceCard(),
                const SizedBox(height: 24),

                // Recent Records
                _sectionLabel('最近记录'),
                const SizedBox(height: 8),
                if (_loading)
                  const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                else if (_recentRecords.isEmpty)
                  _emptyRecordCard()
                else
                  ..._recentRecords.map((r) => _recordCard(r)),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.3));
  }

  Widget _deviceCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.healthGreenLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.watch_outlined, color: AppTheme.healthGreen, size: 24),
        ),
        title: const Text('智能手环', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('未连接 — 点击扫描设备', style: TextStyle(fontSize: 13)),
        trailing: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: AppTheme.healthGreenLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _SettingsPage())),
          child: const Text('连接', style: TextStyle(color: AppTheme.healthGreen)),
        ),
      ),
    );
  }

  Widget _emptyRecordCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.note_add_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text('暂无记录', style: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 15)),
            const SizedBox(height: 4),
            Text('点击上方「快速记录」添加', style: TextStyle(color: Colors.grey.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _recordCard(Map<String, dynamic> record) {
    final type = record['_type']?.toString() ?? '';
    final date = record['record_date']?.toString().substring(0, 10) ?? '';
    final color = _typeColor(type);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_typeIcon(type), color: color, size: 20),
        ),
        title: Text(_typeLabel(type), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(_recordSummary(record), style: const TextStyle(fontSize: 12)),
        trailing: Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'sleep': return Colors.indigo;
      case 'smoking': return Colors.brown;
      case 'drinking': return Colors.orange;
      case 'work_posture': return Colors.teal;
      case 'diet': return Colors.green;
      case 'sugar': return Colors.pink;
      case 'food_detail': return Colors.purple;
      case 'environment': return Colors.blueGrey;
      default: return AppTheme.healthGreen;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'sleep': return Icons.bed;
      case 'smoking': return Icons.smoke_free;
      case 'drinking': return Icons.local_bar;
      case 'work_posture': return Icons.accessibility_new;
      case 'diet': return Icons.restaurant;
      case 'sugar': return Icons.cake;
      case 'food_detail': return Icons.egg_alt;
      case 'environment': return Icons.cloud;
      default: return Icons.favorite;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'sleep': return '睡眠';
      case 'smoking': return '吸烟';
      case 'drinking': return '饮酒';
      case 'work_posture': return '工作姿态';
      case 'diet': return '饮食';
      case 'sugar': return '糖分';
      case 'food_detail': return '精细饮食';
      case 'environment': return '环境危害';
      default: return '体征';
    }
  }

  String _recordSummary(Map<String, dynamic> r) {
    final type = r['_type']?.toString() ?? '';
    if (type == 'sleep') {
      final st = r['sleep_time']?.toString() ?? '';
      final wt = r['wake_time']?.toString() ?? '';
      return '😴 ${st.length >= 5 ? st.substring(0, 5) : st} → ${wt.length >= 5 ? wt.substring(0, 5) : wt}';
    }
    if (type == 'smoking') return '🚬 ${r['count']} 支';
    if (type == 'drinking') return '🍷 ${r['amount']} ${r['unit']}';
    if (type == 'work_posture') return '💪 ${r['total_hours']}小时';
    return r['note']?.toString() ?? '';
  }

  /// 弹出添加家庭成员对话框
  Future<void> _showAddMemberDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    String? selectedGender = 'male';
    final emojis = ['👨', '👩', '👴', '👵', '👦', '👧', '👶', '👨‍🦳', '👩‍🦳'];
    String selectedEmoji = emojis[0];

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加家庭成员'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 头像选择
                    Wrap(
                      spacing: 8,
                      children: emojis.map((e) => GestureDetector(
                        onTap: () => setDialogState(() => selectedEmoji = e),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedEmoji == e ? AppTheme.healthGreen.withValues(alpha: 0.2) : null,
                            border: selectedEmoji == e ? Border.all(color: AppTheme.healthGreen, width: 2) : null,
                          ),
                          child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '称呼', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: relationController,
                      decoration: const InputDecoration(labelText: '关系（如：爸爸、妈妈）', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    // 性别选择
                    Row(
                      children: [
                        const Text('性别：'),
                        const SizedBox(width: 8),
                        ChoiceChip(label: const Text('男'), selected: selectedGender == 'male', onSelected: (_) => setDialogState(() => selectedGender = 'male')),
                        const SizedBox(width: 8),
                        ChoiceChip(label: const Text('女'), selected: selectedGender == 'female', onSelected: (_) => setDialogState(() => selectedGender = 'female')),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('取消')),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty) return;
                    Navigator.of(ctx).pop({
                      'name': nameController.text,
                      'relationship': relationController.text.isEmpty ? '其他' : relationController.text,
                      'gender': selectedGender ?? 'male',
                      'avatar_emoji': selectedEmoji,
                    });
                  },
                  child: const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    try {
      final profileState = ref.read(profileProvider);
      // 直接用 createProfile 方法
      final profile = MemberProfile(
        id: DateTime.now().millisecondsSinceEpoch,
        familyId: 0, // placeholder, 后面会替换
        displayName: result['name']!,
        relation: result['relationship']!,
        gender: result['gender']!,
        avatarUrl: result['avatar_emoji'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 直接添加到状态
      ref.read(profileProvider.notifier).selectProfile(profile);
      // 用现有的 createProfile 方法（它会自己管理状态）
      await ref.read(profileProvider.notifier).createProfile(
        familyId: 0,
        displayName: result['name']!,
        relation: result['relationship']!,
        gender: result['gender']!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加家庭成员：${result['name']}'), backgroundColor: AppTheme.healthGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e'), backgroundColor: Colors.red.shade400),
        );
      }
    }
  }
}

/// 简易设置页面
class _SettingsPage extends ConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: AppTheme.healthGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.displayName ?? '用户'),
            subtitle: Text(user?.phone ?? ''),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text('创建家庭'),
            onTap: () async {
              try {
                final token = ref.read(authTokenProvider);
                if (token == null) return;
                // 直接调用API创建家庭
                final client = ApiClient.instance;
                await client.dio.post('/families', data: {'name': '我的家庭'});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('家庭创建成功！')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败: $e')));
                }
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const login.LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
