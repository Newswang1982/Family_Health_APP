import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_health/core/api/api_client.dart';
import 'package:family_health/pages/auth/login_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  // 强制设置 API 地址
  ApiClient(baseUrl: 'http://192.168.100.200:8080/api/v1');
  runApp(const ProviderScope(child: FamilyHealthApp()));
}

class FamilyHealthApp extends StatelessWidget {
  const FamilyHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '家庭健康',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4CAF50),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
