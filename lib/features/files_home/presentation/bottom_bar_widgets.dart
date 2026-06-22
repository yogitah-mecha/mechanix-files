import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:flutter/material.dart';

class NormalBottomBar extends StatelessWidget {
  const NormalBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomBar(
      key: const ValueKey('normal_bottom_bar'),

      leading: CustomIconButton.asset(
        assetPath: FileIcons.back,
        onPressed: () {
          // TODO: Handle close app
        },
      ),
    );
  }
}

class PasteDestinationBottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onMenu;
  final VoidCallback? onConfirm;

  const PasteDestinationBottomBar({
    super.key,
    required this.onBack,
    required this.onMenu,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return BottomBar(
      leading: CustomIconButton.asset(
        assetPath: FileIcons.back,
        enabled: false,
        onPressed: () {},
      ),

      trailing: [
        CustomIconButton.asset(
          assetPath: FileIcons.check,
          onPressed: () {},
          enabled: false,
        ),
        CustomIconButton.asset(
          assetPath: FileIcons.moreVert,
          onPressed: onMenu,
        ),
      ],
    );
  }
}
