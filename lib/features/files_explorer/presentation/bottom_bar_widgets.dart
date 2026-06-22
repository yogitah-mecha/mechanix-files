import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_details_dialog.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/files_explorer/presentation/folder_actions_menu.dart';
import 'package:mechanix_files/features/files_explorer/presentation/multiselect_actions_menu.dart';
import 'package:mechanix_files/features/files_explorer/presentation/paste_menu.dart';
import 'package:flutter/material.dart';

class BottomPanel extends StatelessWidget {
  final ExplorerBottomPanel activePanel;
  final FileManagerController controller;
  final FileExplorerPageState state;
  final VoidCallback closePanel;
  final String? infoPath;
  final String? selectedItemPath;

  const BottomPanel({
    super.key,
    required this.activePanel,
    required this.controller,
    required this.state,
    required this.closePanel,
    this.infoPath,
    this.selectedItemPath,
  });

  @override
  Widget build(BuildContext context) {
    switch (activePanel) {
      case ExplorerBottomPanel.menu:
        return FolderActionsMenu(
          key: const ValueKey('menu'),
          controller: controller,
          state: state,
          closeFolderActionsSheet: closePanel,
        );

      case ExplorerBottomPanel.info:
        return infoPath != null
            ? FileDetailsDialog(
              key: const ValueKey('info'),
              path: infoPath!,
              onClose: closePanel,
            )
            : const SizedBox.shrink();

      case ExplorerBottomPanel.selectMenu:
        return MultiselectActionsMenu(
          key: const ValueKey('selectMenu'),
          controller: controller,
          state: state,
          closeMultiselectActionsSheet: closePanel,
        );

      case ExplorerBottomPanel.pasteMenu:
        return PasteActionsMenu(
          key: const ValueKey('pasteMenu'),
          controller: controller,
          state: state,
          closePasteActionsSheet: closePanel,
        );

      case ExplorerBottomPanel.none:
        return const SizedBox.shrink();
    }
  }
}

class ExplorerBottomBar extends StatelessWidget {
  final ExplorerMode mode;
  final BuildContext rootContext;

  const ExplorerBottomBar({
    super.key,
    required this.mode,
    required this.rootContext,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case ExplorerMode.browsing:
        return NormalBottomBar(rootContext: rootContext);

      case ExplorerMode.selecting:
        return SelectionBottomBar(rootContext: rootContext);

      case ExplorerMode.moving:
        return PasteDestinationBottomBar(
          isCopyMode: false,
          rootContext: rootContext,
        );

      case ExplorerMode.copying:
        return PasteDestinationBottomBar(
          isCopyMode: true,
          rootContext: rootContext,
        );
    }
  }
}

class SelectionBottomBar extends StatelessWidget {
  final BuildContext rootContext;
  const SelectionBottomBar({super.key, required this.rootContext});

  @override
  Widget build(BuildContext context) {
    final state = rootContext.findAncestorStateOfType<FileExplorerPageState>();

    if (state == null) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<Set<String>>(
      valueListenable: state.selectedPathsNotifier,
      builder: (context, selectedPaths, _) {
        final hasSelection = selectedPaths.isNotEmpty;

        return BottomBar(
          key: const ValueKey('selection_bottom_bar'),

          leading: CustomIconButton.icon(
            iconData: Icons.close,
            onPressed: state.clearSelection,
          ),

          center: [
            CustomIconButton.asset(
              assetPath: FileIcons.checkCircle,
              onPressed: state.handleSelectAll,
            ),

            CustomIconButton.asset(
              assetPath: FileIcons.copy,
              enabled: hasSelection,
              onPressed: state.handleCopy,
            ),

            CustomIconButton.asset(
              assetPath: FileIcons.move,
              enabled: hasSelection,
              onPressed: state.handleMove,
            ),
          ],
          trailing: [
            CustomIconButton.asset(
              assetPath: FileIcons.moreVert,
              onPressed: state.openMenu,
            ),
          ],
        );
      },
    );
  }
}

class NormalBottomBar extends StatelessWidget {
  final BuildContext rootContext;
  const NormalBottomBar({super.key, required this.rootContext});

  @override
  Widget build(BuildContext context) {
    final state = rootContext.findAncestorStateOfType<FileExplorerPageState>();

    return BottomBar(
      key: const ValueKey('normal_bottom_bar'),
      leading: CustomIconButton.asset(
        assetPath: FileIcons.back,
        onPressed: () {
          if (state?.isHomePageDir == true) {
            state?.homeNavigation();
          } else {
            state?.handleBack();
          }
        },
      ),

      trailing: [
        CustomIconButton.asset(
          assetPath: FileIcons.search,
          onPressed: state?.onSearchPressed,
        ),
        CustomIconButton.asset(
          assetPath: FileIcons.moreVert,
          onPressed: state?.openMenu,
        ),
      ],
    );
  }
}

class PasteDestinationBottomBar extends StatelessWidget {
  final BuildContext rootContext;
  final bool isCopyMode;

  const PasteDestinationBottomBar({
    super.key,
    required this.isCopyMode,
    required this.rootContext,
  });

  @override
  Widget build(BuildContext context) {
    final state = rootContext.findAncestorStateOfType<FileExplorerPageState>();

    return BottomBar(
      leading: CustomIconButton.asset(
        assetPath: FileIcons.back,
        onPressed: () {
          if (state?.isHomePageDir == true) {
            state?.homeNavigation();
          } else {
            state?.handleBack();
          }
        },
      ),

      trailing: [
        CustomIconButton.asset(
          assetPath: FileIcons.check,
          onPressed: () {
            state?.handlePaste();
            state?.modeNotifier.value = ExplorerMode.browsing;
          },
        ),

        CustomIconButton.asset(
          assetPath: FileIcons.moreVert,
          onPressed: state?.openMenu,
        ),
      ],
    );
  }
}
