import 'package:flutter/material.dart';
import 'package:temperature_upload/constants/app_colors.dart';
import 'package:temperature_upload/constants/app_sizes.dart';

class GradientTextButton extends StatelessWidget {

  final String text;
  final VoidCallback? onPressed;
  final double width, height;

  const GradientTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = double.infinity,
    this.height = AppSizes.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.gradientEnd,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 2, 
          shadowColor: Colors.black.withValues(alpha: 0.2),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
        ),
        child: onPressed != null
            ? ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                blendMode: BlendMode.srcIn, 
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, 
                  ),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
      ),
    );
  }
}