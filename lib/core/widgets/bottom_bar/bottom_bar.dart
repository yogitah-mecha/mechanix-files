import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  final Widget? leading;
  final List<Widget>? center;
  final List<Widget>? trailing;
  final double height;
  final EdgeInsets padding;
  final Color? backgroundColor;

  const BottomBar({
    super.key,
    this.leading,
    this.center,
    this.trailing,
    this.height = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 0),
    this.backgroundColor = AppColors.backgroundVariantDark,
  });

  Widget _wrap(Widget? child) {
    if (child == null) {
      return const SizedBox(width: 48, height: 48);
    }

    return SizedBox(width: 48, height: 48, child: Center(child: child));
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: backgroundColor,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              /// Leading
              _wrap(leading),

              /// Center
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: center ?? [],
                  ),
                ),
              ),

              /// Trailing
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < (trailing?.length ?? 0); i++) ...[
                    _wrap(trailing![i]),
                    if (i != trailing!.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
