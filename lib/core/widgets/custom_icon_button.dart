import 'package:flutter/material.dart';
import 'package:mechanix_files/core/theme/app_theme.dart';

class CustomIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;

  final bool enabled;

  final double iconSize;
  final double minSize;

  final EdgeInsetsGeometry padding;

  final Color? activeColor;
  final Color? disabledColor;
  final Color? backgroundColor;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.iconSize = 24,
    this.minSize = 48,
    this.padding = const EdgeInsets.all(8),
    this.activeColor,
    this.disabledColor,
    this.backgroundColor,
  });

  /// Asset image constructor
  factory CustomIconButton.asset({
    Key? key,
    required String assetPath,
    required VoidCallback? onPressed,
    bool enabled = true,
    double iconSize = 24,
    double minSize = 48,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    Color? activeColor,
    Color? disabledColor,
    Color? backgroundColor,
  }) {
    return CustomIconButton(
      key: key,
      onPressed: onPressed,
      enabled: enabled,
      iconSize: iconSize,
      minSize: minSize,
      padding: padding,
      activeColor: activeColor,
      disabledColor: disabledColor,
      backgroundColor: backgroundColor,
      icon: Image.asset(assetPath, width: iconSize, height: iconSize),
    );
  }

  /// Material icon constructor
  factory CustomIconButton.icon({
    Key? key,
    required IconData iconData,
    required VoidCallback? onPressed,
    bool enabled = true,
    double iconSize = 24,
    double minSize = 48,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    Color? activeColor,
    Color? disabledColor,
    Color? backgroundColor,
  }) {
    return CustomIconButton(
      key: key,
      onPressed: onPressed,
      enabled: enabled,
      iconSize: iconSize,
      minSize: minSize,
      padding: padding,
      activeColor: activeColor,
      disabledColor: disabledColor,
      backgroundColor: backgroundColor,
      icon: Icon(iconData, size: iconSize),
    );
  }
  @override
  Widget build(BuildContext context) {
    final color =
        enabled
            ? (activeColor ?? AppColors.onSurface)
            : (disabledColor ?? AppColors.onSurfaceVariantDark);

    return SizedBox(
      width: minSize,
      height: minSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: padding,
            alignment: Alignment.center,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: SizedBox(width: iconSize, height: iconSize, child: icon),
            ),
          ),
        ),
      ),
    );
  }
}
