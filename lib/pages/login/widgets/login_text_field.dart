import 'package:flutter/material.dart';

class LoginTextField extends StatelessWidget {

  final TextEditingController? controller;
  final String hintText;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  const LoginTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.isPassword = false,              // 입력 안 하면 기본은 일반 텍스트
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      cursorColor: Colors.white,

      style: const TextStyle(
        color: Colors.white,
        fontSize: 16
      ),

      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.white54,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white70, width: 1.0)
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2.0)
        )
      ),
    );
  }
}