import 'package:flutter/material.dart';
import 'package:mechanix_files/core/theme/app_theme.dart';

class TimeBubble extends StatelessWidget {
  final String text;

  const TimeBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
