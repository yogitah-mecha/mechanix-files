import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/core/widgets/menu_row.dart';
import 'package:mechanix_files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class MultiselectActionsMenu extends StatelessWidget {
  final FileManagerController controller;
  final FileExplorerPageState state;
  final VoidCallback closeMultiselectActionsSheet;

  const MultiselectActionsMenu({
    super.key,
    required this.controller,
    required this.state,
    required this.closeMultiselectActionsSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1F1F1F),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: CustomIconButton.icon(
              iconData: Icons.close,
              onPressed: () => closeMultiselectActionsSheet(),
            ),
          ),

          MenuRow(
            iconPath: FileIcons.checkCircle,
            title: AppLocalizations.of(context)!.selectAll,
            onTap: () {
              closeMultiselectActionsSheet();
              state.handleSelectAll();
            },
          ),

          MenuRow(
            iconPath: FileIcons.copy,
            title: AppLocalizations.of(context)!.copyTo,
            onTap: () {
              closeMultiselectActionsSheet();
              state.handleCopy();
            },
            enabled: state.selectedPathsNotifier.value.isNotEmpty,
          ),

          MenuRow(
            iconPath: FileIcons.move,
            title: AppLocalizations.of(context)!.moveTo,
            onTap: () {
              closeMultiselectActionsSheet();
              state.handleMove();
            },
            enabled: state.selectedPathsNotifier.value.isNotEmpty,
          ),

          MenuRow(
            iconPath: FileIcons.delete,
            title: AppLocalizations.of(context)!.moveToTrash,
            onTap: () {
              closeMultiselectActionsSheet();
              state.handleMoveToTrash();
            },
            enabled: state.selectedPathsNotifier.value.isNotEmpty,
          ),
        ],
      ),
    );
  }
}
