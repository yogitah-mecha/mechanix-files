import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_details_dialog.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_boc.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreviewActionBar extends StatelessWidget {
  final String path;
  final FileExplorerPageState? state;
  final BuildContext rootContext;

  const PreviewActionBar({
    super.key,
    required this.path,
    this.state,
    required this.rootContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundVariant,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),

      child: BottomBar(
        /// BACK
        leading: CustomIconButton.asset(
          assetPath: FileIcons.back,
          onPressed: () => Navigator.pop(context),
        ),

        /// COPY / ACTION
        center: [
          CustomIconButton.asset(
            assetPath: FileIcons.copy,
            onPressed: () {
              state?.selectedPathsNotifier.value = {path};
              state?.handleCopy();
            },
          ),
        ],

        /// INFO
        trailing: [
          CustomIconButton.asset(
            assetPath: FileIcons.info,
            onPressed: () {
              rootContext.read<FilesBloc>().add(FetchFileDetails(path));

              showModalBottomSheet(
                context: rootContext,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) {
                  return FileDetailsDialog(
                    path: path,
                    onClose: () => Navigator.pop(context),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
