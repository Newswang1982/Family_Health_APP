import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:family_health/core/api/record_api.dart';

class FoodDetailRecordPage extends ConsumerStatefulWidget {
  final int pid;
  const FoodDetailRecordPage({super.key, required this.pid});

  @override
  ConsumerState<FoodDetailRecordPage> createState() => _FoodDetailRecordPageState();
}

class _FoodDetailRecordPageState extends ConsumerState<FoodDetailRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  // 0=无, 1=少量, 2=正常, 3=偏多
  int _leanMeat = 1;
  int _fattyMeat = 0;
  int _freshwaterFish = 1;
  int _seafood = 0;
  int _highCholesterol = 0;

  static const _foodLevels = ['无', '少量', '正常', '偏多'];

  @override
  void initState() {
    super.initState();
    _recordDate = DateTime.now();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: '选择日期',
    );
    if (picked != null) setState(() => _recordDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(recordApiProvider).createFoodDetailRecord(
        memberProfileId: widget.pid.toString(),
        recordDate: DateFormat('yyyy-MM-dd').format(_recordDate),
        leanMeat: _leanMeat,
        fattyMeat: _fattyMeat,
        freshwaterFish: _freshwaterFish,
        seafood: _seafood,
        highCholesterol: _highCholesterol,
        note: _noteCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('食物详情记录已保存'), behavior: SnackBarBehavior.floating),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('食物详情记录')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date picker
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('记录日期'),
                  trailing: Text(DateFormat('yyyy-MM-dd').format(_recordDate)),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 12),

              // Food type selectors
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('食物摄入详情', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _buildFoodSelector(Icons.restaurant, '瘦肉', _leanMeat, (v) => setState(() => _leanMeat = v)),
                      const Divider(height: 4),
                      _buildFoodSelector(Icons.restaurant, '肥肉', _fattyMeat, (v) => setState(() => _fattyMeat = v)),
                      const Divider(height: 4),
                      _buildFoodSelector(Icons.set_meal, '淡水鱼虾', _freshwaterFish, (v) => setState(() => _freshwaterFish = v)),
                      const Divider(height: 4),
                      _buildFoodSelector(Icons.set_meal, '海鲜蟹贝', _seafood, (v) => setState(() => _seafood = v)),
                      const Divider(height: 4),
                      _buildFoodSelector(Icons.egg, '高胆固醇食物(内脏/蛋黄/蟹黄)', _highCholesterol, (v) => setState(() => _highCholesterol = v)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Note
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '备注',
                      hintText: '可选填写备注信息',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_submitting ? '保存中...' : '保存记录'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodSelector(IconData icon, String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: List.generate(_foodLevels.length, (i) {
              return ButtonSegment(value: i, label: Text(_foodLevels[i], style: const TextStyle(fontSize: 12)));
            }),
            selected: {value},
            onSelectionChanged: (v) => onChanged(v.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
