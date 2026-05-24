import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:family_health/core/api/record_api.dart';

class WorkPostureRecordPage extends ConsumerStatefulWidget {
  final int pid;
  const WorkPostureRecordPage({super.key, required this.pid});

  @override
  ConsumerState<WorkPostureRecordPage> createState() => _WorkPostureRecordPageState();
}

class _WorkPostureRecordPageState extends ConsumerState<WorkPostureRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;
  final _totalHoursCtrl = TextEditingController();
  final _sittingPctCtrl = TextEditingController();
  final _standingPctCtrl = TextEditingController();
  final _walkingPctCtrl = TextEditingController();
  final _heavyPctCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _recordDate = DateTime.now();
  }

  @override
  void dispose() {
    _totalHoursCtrl.dispose();
    _sittingPctCtrl.dispose();
    _standingPctCtrl.dispose();
    _walkingPctCtrl.dispose();
    _heavyPctCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _currentSum {
    double sum = 0;
    for (final ctrl in [_sittingPctCtrl, _standingPctCtrl, _walkingPctCtrl, _heavyPctCtrl]) {
      sum += double.tryParse(ctrl.text) ?? 0;
    }
    return sum;
  }

  bool get _sumIsValid {
    if (_sittingPctCtrl.text.isEmpty &&
        _standingPctCtrl.text.isEmpty &&
        _walkingPctCtrl.text.isEmpty &&
        _heavyPctCtrl.text.isEmpty) {
      return false;
    }
    return (_currentSum - 100).abs() < 0.01;
  }

  void _onPctChanged(String _) => setState(() {});

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
    if (!_sumIsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('各项比例之和必须等于100%'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(recordApiProvider).createWorkPostureRecord(
        memberProfileId: widget.pid.toString(),
        recordDate: DateFormat('yyyy-MM-dd').format(_recordDate),
        totalHours: double.parse(_totalHoursCtrl.text),
        sittingPct: double.parse(_sittingPctCtrl.text),
        standingPct: double.parse(_standingPctCtrl.text),
        walkingPct: double.parse(_walkingPctCtrl.text),
        heavyPct: double.parse(_heavyPctCtrl.text),
        note: _noteCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('工作姿势记录已保存'), behavior: SnackBarBehavior.floating),
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
    final sum = _currentSum;
    final valid = _sumIsValid;

    return Scaffold(
      appBar: AppBar(title: const Text('工作姿势记录')),
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

              // Total hours
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _totalHoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '总工作时长 (小时)',
                      hintText: '如 8',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '请输入总工作时长';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0 || n > 24) return '请输入1-24之间的小时数';
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Posture percentages
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('姿势比例', style: theme.textTheme.titleMedium),
                          const Spacer(),
                          // Sum indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: valid ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  valid ? Icons.check_circle : Icons.cancel,
                                  size: 16,
                                  color: valid ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '合计: ${sum.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: valid ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sittingPctCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '坐姿 (%)',
                          hintText: '如 40',
                        ),
                        onChanged: _onPctChanged,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _standingPctCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '站立 (%)',
                          hintText: '如 30',
                        ),
                        onChanged: _onPctChanged,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _walkingPctCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '走动 (%)',
                          hintText: '如 20',
                        ),
                        onChanged: _onPctChanged,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _heavyPctCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '重体力 (%)',
                          hintText: '如 10',
                        ),
                        onChanged: _onPctChanged,
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
