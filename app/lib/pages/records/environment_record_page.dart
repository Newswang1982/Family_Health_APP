import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:family_health/core/api/record_api.dart';

class EnvironmentRecordPage extends ConsumerStatefulWidget {
  final int pid;
  const EnvironmentRecordPage({super.key, required this.pid});

  @override
  ConsumerState<EnvironmentRecordPage> createState() => _EnvironmentRecordPageState();
}

class _EnvironmentRecordPageState extends ConsumerState<EnvironmentRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  // Checkbox states: false = 无, true = 有
  bool _dust = false;
  bool _noise = false;
  bool _chemicalFumes = false;
  bool _highTemp = false;
  bool _damp = false;
  bool _radiation = false;

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
      await ref.read(recordApiProvider).createEnvironmentHazardRecord(
        memberProfileId: widget.pid.toString(),
        recordDate: DateFormat('yyyy-MM-dd').format(_recordDate),
        dust: _dust ? 1 : 0,
        noise: _noise ? 1 : 0,
        chemicalFumes: _chemicalFumes ? 1 : 0,
        highTemp: _highTemp ? 1 : 0,
        damp: _damp ? 1 : 0,
        radiation: _radiation ? 1 : 0,
        note: _noteCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('环境记录已保存'), behavior: SnackBarBehavior.floating),
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
      appBar: AppBar(title: const Text('环境危害记录')),
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

              // Hazard checkboxes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('环境危害暴露', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('勾选今日暴露的危害因素', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        secondary: Icon(Icons.blur_on, color: _dust ? Colors.brown : Colors.grey),
                        title: const Text('粉尘'),
                        value: _dust,
                        onChanged: (v) => setState(() => _dust = v ?? false),
                        dense: true,
                      ),
                      CheckboxListTile(
                        secondary: Icon(Icons.volume_up, color: _noise ? Colors.orange : Colors.grey),
                        title: const Text('噪音'),
                        value: _noise,
                        onChanged: (v) => setState(() => _noise = v ?? false),
                        dense: true,
                      ),
                      CheckboxListTile(
                        secondary: Icon(Icons.air, color: _chemicalFumes ? Colors.purple : Colors.grey),
                        title: const Text('有害气体/化学异味'),
                        value: _chemicalFumes,
                        onChanged: (v) => setState(() => _chemicalFumes = v ?? false),
                        dense: true,
                      ),
                      CheckboxListTile(
                        secondary: Icon(Icons.thermostat, color: _highTemp ? Colors.red : Colors.grey),
                        title: const Text('高温'),
                        value: _highTemp,
                        onChanged: (v) => setState(() => _highTemp = v ?? false),
                        dense: true,
                      ),
                      CheckboxListTile(
                        secondary: Icon(Icons.water_drop, color: _damp ? Colors.blue : Colors.grey),
                        title: const Text('潮湿阴冷'),
                        value: _damp,
                        onChanged: (v) => setState(() => _damp = v ?? false),
                        dense: true,
                      ),
                      CheckboxListTile(
                        secondary: Icon(Icons.wb_sunny, color: _radiation ? Colors.yellow.shade700 : Colors.grey),
                        title: const Text('强光辐射'),
                        value: _radiation,
                        onChanged: (v) => setState(() => _radiation = v ?? false),
                        dense: true,
                      ),
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
}
