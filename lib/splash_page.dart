import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<StatefulWidget> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }


  Future<String?> readWithAutoDeleteOnError(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      // 복호화 실패 시 키 삭제
      await _storage.delete(key: key);
      debugPrint('🔐 [SecureStorage] 읽기 실패 → 키 삭제됨: $key\n오류: $e');
      return null;
    }
  }


  Future<void> _checkLogin() async {
    final token = await readWithAutoDeleteOnError('jwt');

    final isValid = token != null && token.isNotEmpty;

    if (!mounted) return;
    if (isValid) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(),),
    );
  }
}