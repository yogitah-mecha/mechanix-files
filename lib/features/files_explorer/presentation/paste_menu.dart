import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/core/widgets/menu_row.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_boc.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_event.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_state.dart';
import 'package:mechanix_files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PasteActionsMenu extends StatelessWidget {
  final FileManagerController controller;
  final FileExplorerPageState? state;
  final VoidCallback closePasteActionsSheet;
  final bool isHomePage;

  const PasteActionsMenu({
    super.key,
    required this.controller,
    this.state,
    required this.closePasteActionsSheet,
    this.isHomePage = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      FilesBloc,
      FilesState,
      ({
        bool isCopyMode,
        bool isMoveMode,
        List<String> copiedPaths,
        List<String> movedPaths,
      })
    >(
      selector:
          (state) => (
            isCopyMode: state.isCopyMode,
            isMoveMode: state.isMoveMode,
            copiedPaths: state.copiedPaths,
            movedPaths: state.movedPaths,
          ),
      builder: (context, filesState) {
        final itemCount =
            filesState.isCopyMode
                ? filesState.copiedPaths.length
                : filesState.movedPaths.length;
        final isMoveMode = filesState.isMoveMode;

        return Material(
          color: const Color(0xFF1F1F1F),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CustomIconButton.icon(
                  iconData: Icons.close,
                  onPressed: closePasteActionsSheet,
                ),
              ),

              MenuRow(
                iconPath: FileIcons.createFolder,
                title: AppLocalizations.of(
                  context,
                )!.pasteInNewFolder(itemCount),
                onTap: () {
                  closePasteActionsSheet();
                  state?.handleCreateFolderWithItems();
                  state?.modeNotifier.value = ExplorerMode.browsing;
                },
                enabled: isMoveMode && !isHomePage,
              ),

              MenuRow(
                iconPath: FileIcons.paste,
                title: AppLocalizations.of(context)!.paste,
                onTap: () {
                  closePasteActionsSheet();
                  state?.handlePaste();
                  state?.modeNotifier.value = ExplorerMode.browsing;
                },
                enabled: !isHomePage,
              ),

              MenuRow(
                iconPath: FileIcons.close,
                title: AppLocalizations.of(context)!.cancel,
                onTap: () {
                  closePasteActionsSheet();

                  final bloc = context.read<FilesBloc>();

                  if (filesState.isCopyMode) {
                    bloc.add(CancelCopyMode());
                  }

                  if (filesState.isMoveMode) {
                    bloc.add(CancelMoveMode());
                  }

                  state?.modeNotifier.value = ExplorerMode.browsing;
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
