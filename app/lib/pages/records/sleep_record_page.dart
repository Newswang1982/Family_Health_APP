import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:family_health/core/api/record_api.dart';
import 'package:family_health/core/theme/app_theme.dart';

class SleepRecordPage extends ConsumerStatefulWidget {
  final int pid;
  const SleepRecordPage({super.key, required this.pid});

  @override
  ConsumerState<SleepRecordPage> createState() => _SleepRecordPageState();
}

class _SleepRecordPageState extends ConsumerState<SleepRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;
  late TimeOfDay _sleepTime;
  late TimeOfDay _wakeTime;
  final _napHoursCtrl = TextEditingController();
  int _quality = 3; // default: 良好
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  static const _qualityLabels = ['很差', '一般', '良好', '很好'];
  static const _qualityValues = [1, 2, 3, 4];

  @override
  void initState() {
    super.initState();
    _recordDate = DateTime.now();
    _sleepTime = const TimeOfDay(hour: 23, minute: 0);
    _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  }

  @override
  void dispose() {
    _napHoursCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Duration get _sleepDuration {
    final sleepMin = _sleepTime.hour * 60 + _sleepTime.minute;
    final wakeMin = _wakeTime.hour * 60 + _wakeTime.minute;
    if (wakeMin >= sleepMin) {
      return Duration(minutes: wakeMin - sleepMin);
    } else {
      return Duration(minutes: (24 * 60 - sleepMin) + wakeMin);
    }
  }

  bool get _isStayingUpLate => _sleepTime.hour >= 0 && _sleepTime.hour < 6;

  String _formatTimeOfDay(TimeOfDay t) {
    final dt = DateTime(2000, 1, 1, t.hour, t.minute);
    return DateFormat('HH:mm').format(dt);
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

  Future<void> _pickSleepTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _sleepTime,
      helpText: '选择入睡时间',
    );
    if (picked != null) setState(() => _sleepTime = picked);
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
      helpText: '选择起床时间',
    );
    if (picked != null) setState(() => _wakeTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(recordApiProvider).createSleepRecord(
        memberProfileId: widget.pid.toString(),
        recordDate: DateFormat('yyyy-MM-dd').format(_recordDate),
        sleepTime: _formatTimeOfDay(_sleepTime),
        wakeTime: _formatTimeOfDay(_wakeTime),
        napHours: _napHoursCtrl.text.isNotEmpty ? double.parse(_napHoursCtrl.text) : null,
        quality: _quality,
        note: _noteCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('睡眠记录已保存'), behavior: SnackBarBehavior.floating),
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
    final dur = _sleepDuration;
    final hours = dur.inMinutes ~/ 60;
    final minutes = dur.inMinutes % 60;

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠记录')),
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

              // Sleep & Wake times
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('睡眠时间', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.bedtime),
                        title: const Text('入睡时间'),
                        trailing: Text(_formatTimeOfDay(_sleepTime), style: theme.textTheme.titleMedium),
                        onTap: _pickSleepTime,
                      ),
                      ListTile(
                        leading: const Icon(Icons.wb_sunny),
                        title: const Text('起床时间'),
                        trailing: Text(_formatTimeOfDay(_wakeTime), style: theme.textTheme.titleMedium),
                        onTap: _pickWakeTime,
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('睡眠时长: $hours小时$minutes分钟',
                              style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.healthGreen)),
                          const Spacer(),
                          if (_isStayingUpLate)
                            Chip(
                              avatar: const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                              label: const Text('熬夜', style: TextStyle(fontSize: 12)),
                              backgroundColor: Colors.orange.withValues(alpha: 0.1),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _napHoursCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '午睡时长 (小时)',
                          hintText: '如 0.5',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quality radio buttons
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('睡眠质量', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(_qualityLabels.length, (i) {
                          final val = _qualityValues[i];
                          return ChoiceChip(
                            label: Text(_qualityLabels[i]),
                            selected: _quality == val,
                            selectedColor: AppTheme.healthGreen.withValues(alpha: 0.2),
                            onSelected: (selected) {
                              if (selected) setState(() => _quality = val);
                            },
                          );
                        }),
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
