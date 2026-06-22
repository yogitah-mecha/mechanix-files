import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/core/widgets/menu_row.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_boc.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_event.dart';
import 'package:mechanix_files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FolderActionsMenu extends StatelessWidget {
  final FileManagerController controller;
  final FileExplorerPageState state;
  final VoidCallback closeFolderActionsSheet;

  const FolderActionsMenu({
    super.key,
    required this.controller,
    required this.state,
    required this.closeFolderActionsSheet,
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
              onPressed: () => closeFolderActionsSheet(),
            ),
          ),

          MenuRow(
            iconPath: FileIcons.checkCircle,
            title: AppLocalizations.of(context)!.select,
            onTap: () {
              closeFolderActionsSheet();
              state.enableSelect();
            },
          ),

          MenuRow(
            iconPath: FileIcons.createFolder,
            title: AppLocalizations.of(context)!.newFolder,
            onTap: () async {
              final folderName = await state.createFolder();
              closeFolderActionsSheet();

              if (!context.mounted) return;
              state.showRenameSheet(initialName: folderName);
            },
          ),
          MenuRow(
            iconPath:
                controller.showHiddenFiles ? FileIcons.eye : FileIcons.eyeSlash,
            title:
                controller.showHiddenFiles
                    ? AppLocalizations.of(context)!.hideFiles
                    : AppLocalizations.of(context)!.showFiles,
            onTap: () {
              closeFolderActionsSheet();
              state.toggleHiddenFiles();
            },
          ),

          MenuRow(
            iconPath: FileIcons.info,
            title: AppLocalizations.of(context)!.fileInfo,
            onTap: () {
              final path = controller.getCurrentPath;

              context.read<FilesBloc>().add(FetchFileDetails(path));

              state.showInfo(path);
            },
          ),
        ],
      ),
    );
  }
}
