// @dart=3.6
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:family_health/core/api/record_api.dart';
import 'package:family_health/core/providers/profile_provider.dart';
import 'package:family_health/core/theme/app_theme.dart';

class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({super.key});
  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends ConsumerState<RecordsPage> {
  String? _selectedType;
  DateTimeRange? _dateRange;

  final _recordTypes = [
    'sleep', 'smoking', 'drinking', 'work_posture',
    'diet', 'sugar', 'food_detail', 'environment', 'health',
  ];

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final selectedProfileId = profileState.selectedProfile?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('全部记录'), actions: [
        IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showFilterDialog()),
      ]),
      body: Column(children: [
        if (profileState.profiles.isNotEmpty)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: profileState.profiles.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('全部'),
                      selected: selectedProfileId == null,
                      onSelected: (_) {},
                    ),
                  );
                }
                final p = profileState.profiles[i - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(p.displayName),
                    selected: selectedProfileId == p.id,
                    onSelected: (_) => ref.read(profileProvider.notifier).selectProfile(p),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: ref.read(recordApiProvider).queryRecords(memberProfileId: selectedProfileId?.toString()),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('加载失败: ${snapshot.error}'));
              }
              final records = snapshot.data ?? [];
              if (records.isEmpty) {
                return const Center(child: Text('暂无记录'));
              }
              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) {
                    final record = records[i] as Map<String, dynamic>;
                    return Dismissible(
                      key: ValueKey(record['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('确认删除'),
                            content: const Text('确定要删除这条记录吗？'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          ref.read(recordApiProvider).deleteRecord(
                            record['id'].toString(), record['_type']?.toString() ?? 'health',
                          );
                        }
                        return false;
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getTypeColor(record['_type']?.toString() ?? ''),
                            child: Icon(_getTypeIcon(record['_type']?.toString() ?? ''), color: Colors.white),
                          ),
                          title: Text(_getTypeLabel(record['_type']?.toString() ?? '')),
                          subtitle: Text(_getRecordSummary(record)),
                          trailing: Text(
                            record['record_date']?.toString().substring(0, 10) ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddRecordSheet(context),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('筛选'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: '记录类型'),
            items: [
              const DropdownMenuItem(value: null, child: Text('全部')),
              ..._recordTypes.map((t) => DropdownMenuItem(value: t, child: Text(_getTypeLabel(t)))),
            ],
            onChanged: (v) => setState(() => _selectedType = v),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(
              _dateRange != null
                  ? '${DateFormat('MM/dd').format(_dateRange!.start)} - ${DateFormat('MM/dd').format(_dateRange!.end)}'
                  : '选择日期范围',
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: ctx,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (picked != null) setState(() => _dateRange = picked);
            },
          ),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定'))],
      ),
    );
  }

  void _showAddRecordSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (ctx2) => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: _recordTypes.map((type) {
          return InkWell(
            onTap: () {
              Navigator.pop(ctx2);
              context.push('/record/$type/${ref.read(profileProvider).selectedProfile?.id ?? ''}');
            },
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_getTypeIcon(type), size: 32, color: _getTypeColor(type)),
              const SizedBox(height: 4),
              Text(_getTypeLabel(type), style: const TextStyle(fontSize: 12)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  String _getRecordSummary(Map<String, dynamic> r) {
    final type = r['_type']?.toString() ?? r['record_type']?.toString() ?? '';
    switch (type) {
      case 'sleep':
        return '入睡: ${r['sleep_time']} 起床: ${r['wake_time']}';
      case 'smoking':
        return '${r['count']} 支';
      case 'drinking':
        return '${r['amount']} ${r['unit']} (${r['liquor_type'] ?? ''})';
      case 'work_posture':
        return '${r['total_hours']}小时';
      default:
        return r['note']?.toString() ?? '';
    }
  }

  IconData _getTypeIcon(String type) {
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

  Color _getTypeColor(String type) {
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'sleep': return '睡眠';
      case 'smoking': return '吸烟';
      case 'drinking': return '饮酒';
      case 'work_posture': return '工作姿态';
      case 'diet': return '饮食';
      case 'sugar': return '糖分';
      case 'food_detail': return '精细饮食';
      case 'environment': return '环境危害';
      case 'health': return '体征';
      default: return type;
    }
  }
}
