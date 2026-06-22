import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MenuRow extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback? onTap;
  final bool enabled;

  const MenuRow({
    super.key,
    required this.iconPath,
    required this.title,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color:
                  enabled
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariantDark,
            ),
            const SizedBox(width: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color:
                    enabled
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariantDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
