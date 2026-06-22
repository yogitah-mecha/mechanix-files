import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CustomCircleCheckbox extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onTap;

  const CustomCircleCheckbox({
    super.key,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 20.75,
        height: 20.75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isChecked ? AppColors.onSurface : Colors.transparent,
          border: Border.all(
            color: isChecked ? AppColors.onSurface : AppColors.onSurfaceVariant,
            width: 2.5,
          ),
        ),
        child:
            isChecked
                ? const Center(
                  child: Icon(Icons.check, size: 16, color: AppColors.surface),
                )
                : null,
      ),
    );
  }
}
