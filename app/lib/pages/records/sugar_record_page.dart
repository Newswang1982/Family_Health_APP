import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:family_health/core/api/record_api.dart';

class SugarRecordPage extends ConsumerStatefulWidget {
  final int pid;
  const SugarRecordPage({super.key, required this.pid});

  @override
  ConsumerState<SugarRecordPage> createState() => _SugarRecordPageState();
}

class _SugarRecordPageState extends ConsumerState<SugarRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  // Toggle states: false = 无, true = 有
  bool _soda = false;
  bool _juice = false;
  bool _milkTea = false;
  bool _cake = false;
  bool _candy = false;

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
      await ref.read(recordApiProvider).createSugarRecord(
        memberProfileId: widget.pid.toString(),
        recordDate: DateFormat('yyyy-MM-dd').format(_recordDate),
        soda: _soda ? 1 : 0,
        juice: _juice ? 1 : 0,
        milkTea: _milkTea ? 1 : 0,
        cake: _cake ? 1 : 0,
        candy: _candy ? 1 : 0,
        note: _noteCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('糖分记录已保存'), behavior: SnackBarBehavior.floating),
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
      appBar: AppBar(title: const Text('糖分摄入记录')),
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

              // Sugar toggle buttons
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('含糖食物摄入', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('点击切换 无/有', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 12),
                      _buildSugarToggle(Icons.local_drink, '可乐汽水', _soda, (v) => setState(() => _soda = v)),
                      const Divider(height: 4),
                      _buildSugarToggle(Icons.blender, '果汁', _juice, (v) => setState(() => _juice = v)),
                      const Divider(height: 4),
                      _buildSugarToggle(Icons.coffee, '奶茶果茶', _milkTea, (v) => setState(() => _milkTea = v)),
                      const Divider(height: 4),
                      _buildSugarToggle(Icons.cake, '甜品蛋糕', _cake, (v) => setState(() => _cake = v)),
                      const Divider(height: 4),
                      _buildSugarToggle(Icons.auto_awesome, '糖果零食', _candy, (v) => setState(() => _candy = v)),
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

  Widget _buildSugarToggle(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      secondary: Icon(icon, color: value ? Colors.pink : Colors.grey),
      title: Text(label),
      value: value,
      onChanged: onChanged,
      dense: true,
      activeColor: Colors.pink,
    );
  }
}
