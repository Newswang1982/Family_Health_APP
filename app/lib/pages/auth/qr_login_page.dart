// @dart=3.6
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:family_health/core/api/api_client.dart';
import 'package:family_health/core/theme/app_theme.dart';

/// QR Code login page displayed on the computer/app.
/// Shows a QR code, the user scans it with their phone to log in.
class QRLoginPage extends ConsumerStatefulWidget {
  const QRLoginPage({super.key});

  @override
  ConsumerState<QRLoginPage> createState() => _QRLoginPageState();
}

class _QRLoginPageState extends ConsumerState<QRLoginPage> {
  String? _qrToken;
  String _status = 'pending'; // pending / scanned / confirmed / expired
  Timer? _pollTimer;
  bool _loading = true;
  int _expireSeconds = 300;

  @override
  void initState() {
    super.initState();
    _generateQR();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQR() async {
    setState(() => _loading = true);
    try {
      final dio = ApiClient.instance.dio;
      final resp = await dio.get('/auth/qr/generate');
      final data = resp.data as Map<String, dynamic>;
      setState(() {
        _qrToken = data['qr_token'] as String?;
        _expireSeconds = (data['expire_in'] as int?) ?? 300;
        _status = 'pending';
        _loading = false;
      });
      _startPolling();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成二维码失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_qrToken == null) return;
      try {
        final dio = ApiClient.instance.dio;
        final resp = await dio.get('/auth/qr/status/$_qrToken');
        final data = resp.data as Map<String, dynamic>;
        final status = data['status'] as String? ?? 'pending';

        if (status == 'confirmed') {
          timer.cancel();
          final token = data['token'] as String?;
          if (token != null) {
            // Save token and navigate to home
            final storage = const FlutterSecureStorage();
            await storage.write(key: 'auth_token', value: token);
            if (mounted) context.go('/home');
          }
        } else if (status == 'expired') {
          timer.cancel();
          setState(() => _status = 'expired');
        } else {
          setState(() => _status = status);
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // App icon
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.healthGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppTheme.healthGreen.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  '扫码登录',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '打开手机上的家庭健康 App\n扫描二维码即可登录',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                ),

                const SizedBox(height: 48),

                // QR code area
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )
                else if (_status == 'expired')
                  _buildExpiredCard()
                else
                  _buildQRCard(),

                const SizedBox(height: 32),

                // Status indicator
                if (!_loading && _status != 'expired')
                  _buildStatusRow(),

                const SizedBox(height: 24),

                // Back to login
                TextButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('返回登录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQRCard() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // QR code placeholder (in production, use qr_flutter package)
          Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code, size: 100, color: AppTheme.healthGreen),
                  const SizedBox(height: 8),
                  Text(
                    '用手机扫描',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '二维码有效 ${_expireSeconds ~/ 60} 分钟',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredCard() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.timer_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('二维码已过期', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generateQR,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.healthGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('重新生成'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    IconData icon;
    String text;
    Color color;

    switch (_status) {
      case 'scanned':
        icon = Icons.smartphone;
        text = '手机已扫码，确认中...';
        color = Colors.orange;
        break;
      case 'confirmed':
        icon = Icons.check_circle;
        text = '登录成功！';
        color = Colors.green;
        break;
      default:
        icon = Icons.qr_code_scanner;
        text = '等待扫码...';
        color = Colors.grey;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}
