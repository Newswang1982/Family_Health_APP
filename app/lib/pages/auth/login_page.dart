// @dart=3.6
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:family_health/core/providers/auth_provider.dart';
import 'package:family_health/core/api/auth_api.dart';
import 'package:family_health/core/theme/app_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isEmail = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateAccount(String? value) {
    if (value == null || value.isEmpty) return '请输入手机号或邮箱';
    if (_isEmail) {
      if (!value.contains('@')) return '邮箱格式不正确';
    } else {
      if (value.length != 11) return '手机号格式不正确';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return '请输入密码';
    if (value.length < 6) return '密码至少6位';
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final account = _accountController.text.trim();
      await ref.read(authProvider.notifier).login(username: account, password: _passwordController.text);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('登录失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _weChatLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authApiProvider).getWeChatAuthUrl();
      if (result['auth_url'] == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('微信登录暂未配置')));
        return;
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('微信登录'),
            content: const Text('请在微信中打开链接完成授权\n\n（接入微信开放平台后可直接唤起微信）'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('知道了'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('微信登录失败: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _qqLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authApiProvider).getQQAuthUrl();
      if (result['auth_url'] == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QQ登录暂未配置')));
        return;
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('QQ登录'),
            content: const Text('请使用浏览器打开链接完成授权\n\n（接入QQ互联后可直接唤起QQ）'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('知道了'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QQ登录失败: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 80),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.favorite, size: 44, color: AppTheme.healthGreen),
              ),
              const SizedBox(height: 24),
              Text('家庭健康', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('登录以管理您的家庭健康', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 40),

              // Account field (phone or email)
              TextFormField(
                controller: _accountController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: '手机号 / 邮箱',
                  prefixIcon: Icon(_isEmail ? Icons.email_outlined : Icons.phone_android),
                  suffixIcon: IconButton(
                    icon: Icon(_isEmail ? Icons.phone_android : Icons.email_outlined, size: 20),
                    onPressed: () => setState(() => _isEmail = !_isEmail),
                    tooltip: _isEmail ? '切换手机号' : '切换邮箱',
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: _validateAccount,
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '密码', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(),
                  suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 24),

              // Login button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('登 录', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: () => context.push('/auth/register'), child: const Text('还没有账号？立即注册')),
              const SizedBox(height: 28),

              // Divider: 其他登录方式
              Row(children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('其他登录方式', style: TextStyle(color: Colors.grey[500], fontSize: 13))),
                Expanded(child: Divider(color: Colors.grey[300])),
              ]),
              const SizedBox(height: 20),

              // Three social login buttons in a row
              Row(children: [
                Expanded(child: _socialBtn(Icons.wechat, '微信', const Color(0xFF07C160), _weChatLogin)),
                const SizedBox(width: 12),
                Expanded(child: _socialBtn(Icons.chat_bubble, 'QQ', const Color(0xFF12B7F5), _qqLogin)),
                const SizedBox(width: 12),
                Expanded(child: _socialBtn(Icons.email_outlined, '邮箱', Colors.grey[600]!, _switchToEmail)),
              ]),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _socialBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  void _switchToEmail() {
    setState(() {
      _isEmail = true;
      _accountController.text = '';
    });
    _accountController.text.isNotEmpty
        ? _accountController.selection = TextSelection(baseOffset: 0, extentOffset: _accountController.text.length)
        : null;
  }
}
