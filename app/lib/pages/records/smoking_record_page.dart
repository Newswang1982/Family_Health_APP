import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:family_health/core/api/record_api.dart';
import 'package:family_health/core/theme/app_theme.dart';

class SmokingRecordPage extends ConsumerStatefulWidget {
  final int pid;
  const SmokingRecordPage({super.key, required this.pid});

  @override
  ConsumerState<SmokingRecordPage> createState() => _SmokingRecordPageState();
}

class _SmokingRecordPageState extends ConsumerState<SmokingRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;
  bool _noSmokingToday = false;
  final _countCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _recordDate = DateTime.now();
  }

  @override
  void dispose() {
    _countCtrl.dispose();
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
      final count = _noSmokingToday ? 0 : int.parse(_countCtrl.text);
      await ref.read(recordApiProvider).createSmokingRecord(
        memberProfileId: widget.pid.toString(),
        recordDate: DateFormat('yyyy-MM-dd').format(_recordDate),
        count: count,
        note: _noSmokingToday ? '今天没抽烟' : '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('吸烟记录已保存'), behavior: SnackBarBehavior.floating),
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
    return Scaffold(
      appBar: AppBar(title: const Text('吸烟记录')),
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

              // No smoking toggle
              Card(
                child: SwitchListTile(
                  secondary: Icon(
                    _noSmokingToday ? Icons.smoke_free : Icons.smoking_rooms,
                    color: _noSmokingToday ? AppTheme.healthGreen : Colors.brown,
                  ),
                  title: const Text('今天没抽烟'),
                  subtitle: Text(_noSmokingToday ? '已标记为无吸烟日' : '关闭开关以记录吸烟量'),
                  value: _noSmokingToday,
                  onChanged: (val) => setState(() => _noSmokingToday = val),
                ),
              ),

              if (!_noSmokingToday) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _countCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '吸烟支数',
                        hintText: '请输入今天吸了多少支烟',
                        prefixIcon: Icon(Icons.smoking_rooms),
                      ),
                      validator: (v) {
                        if (_noSmokingToday) return null;
                        if (v == null || v.isEmpty) return '请输入吸烟支数';
                        final n = int.tryParse(v);
                        if (n == null || n < 0) return '请输入有效数字';
                        return null;
                      },
                    ),
                  ),
                ),
              ],
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
}
