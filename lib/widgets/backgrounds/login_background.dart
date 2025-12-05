import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class LoginBackground extends StatelessWidget {

  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover,)
        ),
        SafeArea(
          
          child: Align(
            alignment: Alignment.bottomCenter,
            child: KeyboardVisibilityBuilder(
              builder: (context, isKeyboardVisible) => 
                AnimatedPadding(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: isKeyboardVisible ? 20.0 : 50.0),
                  child: SizedBox(
                    width: screenWidth * 0.2,
                    child: Image.asset(
                      'assets/images/signature_white.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                )
            )
          )
        )
      ],
    );
  }
}