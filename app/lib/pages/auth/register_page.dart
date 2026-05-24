// @dart=3.6
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:family_health/core/providers/auth_provider.dart';
import 'package:family_health/core/theme/app_theme.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return '请输入手机号';
    final regex = RegExp(r'^1[3-9]\d{9}$');
    if (!regex.hasMatch(value)) return '手机号格式不正确';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return '请输入密码';
    if (value.length < 6) return '密码至少6位';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return '请确认密码';
    if (value != _passwordController.text) return '两次密码不一致';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).register(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('注册成功！')));
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('注册失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('注册'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 32),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person_add_alt_1, size: 32, color: AppTheme.healthGreen),
            ),
            const SizedBox(height: 24),
            Text('创建账号', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('注册后即可管理您的家庭健康', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 40),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '昵称', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: '手机号', prefixIcon: Icon(Icons.phone_android), border: OutlineInputBorder()),
              validator: _validatePhone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '密码', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
              ),
              validator: _validatePassword,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: '确认密码', prefixIcon: const Icon(Icons.lock), border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
              ),
              validator: _validateConfirm,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('注 册', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('已有账号？', style: TextStyle(color: Colors.grey[600])),
              TextButton(onPressed: () => context.pop(), child: const Text('立即登录')),
            ]),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}
