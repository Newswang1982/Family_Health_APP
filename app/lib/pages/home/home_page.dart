import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:family_health/core/api/record_api.dart';
import 'package:family_health/core/providers/auth_provider.dart';
import 'package:family_health/core/providers/profile_provider.dart';
import 'package:family_health/core/theme/app_theme.dart';
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
                                  DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now()),
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
                                  onPressed: () => context.push('/home/settings'),
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
                    onAddTap: () => context.push('/home/settings'),
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
          onPressed: () => context.push('/home/devices'),
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
}
