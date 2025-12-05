import 'package:flutter/material.dart';

import 'package:temperature_upload/constants/app_sizes.dart';
import 'package:temperature_upload/constants/app_colors.dart';

class GradientBgButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double borderRadius;
  final double width, height;

  const GradientBgButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderRadius = AppSizes.borderRadius,
    this.width = double.infinity,
    this.height = AppSizes.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight
            )
            : null,
        color: isEnabled ? null : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: isEnabled
          ? [
              BoxShadow(
                color: AppColors.gradientEnd.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
          : []
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,

          foregroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius)
          ),

          padding: EdgeInsets.zero
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: AppSizes.mediumFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),
        )
      ),
    );
  }
}