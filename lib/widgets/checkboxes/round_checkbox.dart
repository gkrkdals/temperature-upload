import 'package:flutter/material.dart';
import 'package:temperature_upload/constants/app_colors.dart';

class RoundCheckbox extends StatelessWidget {

  final String label;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const RoundCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      behavior: HitTestBehavior.translucent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.white : Colors.transparent,
              border: value
                  ? null
                  : Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1.5,
                  )
            ),
            child: value
                ? ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        colors: [AppColors.gradientStart, AppColors.gradientEnd],
                        begin: Alignment.centerLeft, // 좌
                        end: Alignment.centerRight,  // 우
                        // 아이콘이 작아서 대각선(topLeft -> bottomRight)으로 해도 예쁩니다.
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn, // 아이콘 모양대로 색 입히기
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      // ⚠️ 중요: 마스크를 씌울 때는 아이콘을 반드시 흰색으로 설정해야 색이 정확히 나옵니다.
                      color: Colors.white, 
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      )
    );
  }
}