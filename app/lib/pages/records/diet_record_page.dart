import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:family_health/core/api/record_api.dart';

class DietRecordPage extends ConsumerStatefulWidget {
  final int pid;
  const DietRecordPage({super.key, required this.pid});

  @override
  ConsumerState<DietRecordPage> createState() => _DietRecordPageState();
}

class _DietRecordPageState extends ConsumerState<DietRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;
  final _waterCtrl = TextEditingController();
  bool _breakfastOk = true;
  bool _lunchOk = true;
  bool _dinnerOk = true;
  bool _binge = false;
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _recordDate = DateTime.now();
  }

  @override
  void dispose() {
    _waterCtrl.dispose();
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
      await ref.read(recordApiProvider).createDietRecord(
        memberProfileId: widget.pid.toString(),
        recordDate: DateFormat('yyyy-MM-dd').format(_recordDate),
        waterMl: _waterCtrl.text.isNotEmpty ? int.parse(_waterCtrl.text) : 0,
        breakfastOk: _breakfastOk ? 1 : 0,
        lunchOk: _lunchOk ? 1 : 0,
        dinnerOk: _dinnerOk ? 1 : 0,
        binge: _binge ? 1 : 0,
        note: _noteCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('饮食记录已保存'), behavior: SnackBarBehavior.floating),
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
      appBar: AppBar(title: const Text('饮食记录')),
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

              // Water intake
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _waterCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '饮水量 (ml)',
                      hintText: '如 1500',
                      prefixIcon: Icon(Icons.water_drop),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Meal regularity toggles
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('三餐按时', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        secondary: const Icon(Icons.free_breakfast),
                        title: const Text('早餐按时'),
                        value: _breakfastOk,
                        onChanged: (val) => setState(() => _breakfastOk = val),
                        dense: true,
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.lunch_dining),
                        title: const Text('午餐按时'),
                        value: _lunchOk,
                        onChanged: (val) => setState(() => _lunchOk = val),
                        dense: true,
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.dinner_dining),
                        title: const Text('晚餐按时'),
                        value: _dinnerOk,
                        onChanged: (val) => setState(() => _dinnerOk = val),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Binge toggle
              Card(
                child: SwitchListTile(
                  secondary: Icon(
                    _binge ? Icons.warning : Icons.restaurant,
                    color: _binge ? Colors.red : null,
                  ),
                  title: const Text('暴饮暴食'),
                  subtitle: const Text('是否有暴饮暴食行为'),
                  value: _binge,
                  onChanged: (val) => setState(() => _binge = val),
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
}
