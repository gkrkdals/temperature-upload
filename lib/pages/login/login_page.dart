import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:temperature_upload/pages/login/widgets/login_text_field.dart';
import 'package:temperature_upload/utils/client.dart';

import 'package:temperature_upload/constants/app_sizes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState()  => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController? _idController;
  TextEditingController? _passwordController;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 초기화 코드 작성
    _idController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _idController?.dispose();
    _passwordController?.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final body = {
      'id': _idController?.text,
      'pwd': _passwordController?.text
    };

    try {
      final response = await Client.post('/api/auth/login-request', body: body);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['result'] == 'failed') {
          setState(() {
            _error = 'ID와 비밀번호를 확인해주세요.';
          });
        } else {
          final token = body['token'];
          await FlutterSecureStorage().write(key: 'jwt', value: token);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } else {
        print(response.body);
      }
    } catch (e) {
      setState(() {
        _error = '오류 발생: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover,)
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.contentSpacing),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoginTextField(controller: _idController, hintText: "아이디"),
                const SizedBox(height: AppSizes.smallSpacing),
                LoginTextField(controller: _passwordController, hintText: "비밀번호"),
                const SizedBox(height: AppSizes.mediumSpacing),
                if (_isLoading) const CircularProgressIndicator(),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: const Text('로그인'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}