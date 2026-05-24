import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:family_health/core/api/record_api.dart';

class VitalsRecordPage extends ConsumerStatefulWidget {
  final int pid;
  const VitalsRecordPage({super.key, required this.pid});

  @override
  ConsumerState<VitalsRecordPage> createState() => _VitalsRecordPageState();
}

class _VitalsRecordPageState extends ConsumerState<VitalsRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;
  final _heartRateCtrl = TextEditingController();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _oxygenCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _bloodSugarCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _recordDate = DateTime.now();
  }

  @override
  void dispose() {
    _heartRateCtrl.dispose();
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _oxygenCtrl.dispose();
    _temperatureCtrl.dispose();
    _bloodSugarCtrl.dispose();
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
      final valueJson = <String, dynamic>{};
      if (_heartRateCtrl.text.isNotEmpty) {
        valueJson['heart_rate'] = int.parse(_heartRateCtrl.text);
      }
      if (_systolicCtrl.text.isNotEmpty) {
        valueJson['blood_pressure_systolic'] = int.parse(_systolicCtrl.text);
      }
      if (_diastolicCtrl.text.isNotEmpty) {
        valueJson['blood_pressure_diastolic'] = int.parse(_diastolicCtrl.text);
      }
      if (_oxygenCtrl.text.isNotEmpty) {
        valueJson['blood_oxygen'] = double.parse(_oxygenCtrl.text);
      }
      if (_temperatureCtrl.text.isNotEmpty) {
        valueJson['temperature'] = double.parse(_temperatureCtrl.text);
      }
      if (_bloodSugarCtrl.text.isNotEmpty) {
        valueJson['blood_sugar'] = double.parse(_bloodSugarCtrl.text);
      }

      await ref.read(recordApiProvider).createHealthRecord(
        memberProfileId: widget.pid.toString(),
        recordDate: DateFormat('yyyy-MM-dd').format(_recordDate),
        recordType: 'vitals',
        valueJson: valueJson,
        note: _noteCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('生命体征记录已保存'), behavior: SnackBarBehavior.floating),
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
      appBar: AppBar(title: const Text('生命体征记录')),
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
              const SizedBox(height: 16),

              // Vitals fields in a grid
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('体征数据', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heartRateCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '心率 (bpm)',
                                hintText: '如 72',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _oxygenCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '血氧 (%)',
                                hintText: '如 98',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _systolicCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '高压 (mmHg)',
                                hintText: '如 120',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _diastolicCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '低压 (mmHg)',
                                hintText: '如 80',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _temperatureCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '体温 (℃)',
                                hintText: '如 36.5',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _bloodSugarCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '血糖 (mmol/L)',
                                hintText: '如 5.6',
                              ),
                            ),
                          ),
                        ],
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
