import 'package:flutter/material.dart';
import 'package:files/core/constants/icons.dart';
import 'package:files/core/theme/app_theme.dart';
import 'package:files/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:files/features/files_explorer/presentation/file_details_dialog.dart';
import 'package:files/features/files_explorer/presentation/file_explorer.dart';
import 'package:files/features/files_explorer/blocs/file_boc.dart';
import 'package:files/features/files_explorer/blocs/file_event.dart';
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
        leading: IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Image.asset(
            FileIcons.back,
            width: 24,
            height: 24,
            color: AppColors.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        /// COPY / ACTION
        center: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Image.asset(
              FileIcons.copy,
              width: 24,
              height: 24,
              color: AppColors.onSurface,
            ),
            onPressed: () {
              state?.selectedPathsNotifier.value = {path};
              state?.handleCopy();
            },
          ),
        ],

        /// INFO
        trailing: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Image.asset(
              FileIcons.info,
              width: 24,
              height: 24,
              color: AppColors.onSurface,
            ),
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
