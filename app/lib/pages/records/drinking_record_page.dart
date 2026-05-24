import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:family_health/core/api/record_api.dart';
import 'package:family_health/core/theme/app_theme.dart';

class DrinkingRecordPage extends ConsumerStatefulWidget {
  final int pid;
  const DrinkingRecordPage({super.key, required this.pid});

  @override
  ConsumerState<DrinkingRecordPage> createState() => _DrinkingRecordPageState();
}

class _DrinkingRecordPageState extends ConsumerState<DrinkingRecordPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordDate;
  bool _noDrinkingToday = false;
  String _liquorType = '白酒';
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  static const _liquorTypes = ['白酒', '红酒', '黄酒', '啤酒', '其他'];

  String get _unit {
    switch (_liquorType) {
      case '啤酒':
        return '瓶/罐';
      default:
        return '两';
    }
  }

  String get _hint {
    switch (_liquorType) {
      case '啤酒':
        return '请输入几瓶/罐';
      default:
        return '请输入几两';
    }
  }

  @override
  void initState() {
    super.initState();
    _recordDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
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
      if (_noDrinkingToday) {
        await ref.read(recordApiProvider).createDrinkingRecord(
          memberProfileId: widget.pid.toString(),
          recordDate: DateFormat('yyyy-MM-dd').format(_recordDate),
          liquorType: '无',
          amount: 0,
          unit: '',
          note: '今天没喝酒',
        );
      } else {
        await ref.read(recordApiProvider).createDrinkingRecord(
          memberProfileId: widget.pid.toString(),
          recordDate: DateFormat('yyyy-MM-dd').format(_recordDate),
          liquorType: _liquorType,
          amount: double.parse(_amountCtrl.text),
          unit: _unit,
          note: _noteCtrl.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('饮酒记录已保存'), behavior: SnackBarBehavior.floating),
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
      appBar: AppBar(title: const Text('饮酒记录')),
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

              // No drinking toggle
              Card(
                child: SwitchListTile(
                  secondary: Icon(
                    _noDrinkingToday ? Icons.check_circle : Icons.local_bar,
                    color: _noDrinkingToday ? AppTheme.healthGreen : Colors.orange,
                  ),
                  title: const Text('今天没喝酒'),
                  subtitle: Text(_noDrinkingToday ? '已标记为无饮酒日' : '关闭开关以记录饮酒量'),
                  value: _noDrinkingToday,
                  onChanged: (val) => setState(() => _noDrinkingToday = val),
                ),
              ),

              if (!_noDrinkingToday) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('饮酒详情', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),

                        // Liquor type dropdown
                        DropdownButtonFormField<String>(
                          value: _liquorType,
                          decoration: const InputDecoration(
                            labelText: '酒的种类',
                            prefixIcon: Icon(Icons.local_bar),
                          ),
                          items: _liquorTypes.map((type) {
                            return DropdownMenuItem(value: type, child: Text(type));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _liquorType = val);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Amount input
                        TextFormField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: '饮酒量 ($_unit)',
                            hintText: _hint,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return '请输入饮酒量';
                            final n = double.tryParse(v);
                            if (n == null || n < 0) return '请输入有效数字';
                            return null;
                          },
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
