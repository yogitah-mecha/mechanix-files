import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/constants/path_constants.dart';
import 'package:mechanix_files/core/widgets/section_list/section_item.dart';
import 'package:mechanix_files/core/widgets/section_list/section_list.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_boc.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_state.dart';
import 'package:mechanix_files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/files_explorer/presentation/paste_menu.dart';
import 'package:mechanix_files/features/files_home/data/models/file_item.dart';
import 'package:mechanix_files/features/files_home/presentation/bottom_bar_widgets.dart';
import 'package:mechanix_files/features/recents/presentation/recent_files.dart';
import 'package:mechanix_files/features/trash/presentation/trash.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileHomePage extends StatefulWidget {
  final String title;
  final List<FileItem> path;

  const FileHomePage({super.key, this.title = "", this.path = const []});

  @override
  FileHomePageState createState() => FileHomePageState();
}

class FileHomePageState extends State<FileHomePage> {
  final downloadsDir = AppPaths.downloadsDir;
  final documentsDir = AppPaths.documentsDir;
  final homeDir = AppPaths.homeDir;
  final recentDir = AppPaths.recentDir;

  @override
  void initState() {
    super.initState();
    _handleAutoNavigation();
  }

  void _handleAutoNavigation() {
    if (widget.path.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => FileExplorerPage(
                startPath: "/${widget.path.map((e) => e.name).join("/")}",
                path: widget.path,
              ),
        ),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      FilesBloc,
      FilesState,
      ({
        bool isCopyMode,
        bool isMoveMode,
        List<String> copiedPaths,
        List<String> movePaths,
      })
    >(
      selector:
          (state) => (
            isCopyMode: state.isCopyMode,
            isMoveMode: state.isMoveMode,
            copiedPaths: state.copiedPaths,
            movePaths: state.movedPaths,
          ),
      builder: (context, selectionState) {
        final isPickingDestination =
            selectionState.isCopyMode || selectionState.isMoveMode;
        final title =
            isPickingDestination
                ? (selectionState.isCopyMode
                    ? AppLocalizations.of(
                      context,
                    )!.copyItems(selectionState.copiedPaths.length)
                    : AppLocalizations.of(
                      context,
                    )!.moveItems(selectionState.movePaths.length))
                : AppLocalizations.of(context)!.filesHomeTitle;

        return Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),

          body: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Divider(height: 1, color: AppColors.backgroundVariant),

                  SectionList(
                    items: [
                      SectionItem(
                        title: AppLocalizations.of(context)!.homeDirectory,
                        titleStyle: Theme.of(context).textTheme.bodyLarge,
                        leading: Image.asset(
                          height: 24,
                          width: 24,
                          FileIcons.home,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onTap:
                            () => onTap(
                              context,
                              homeDir,
                              AppLocalizations.of(context)!.homeDirectory,
                            ),
                      ),

                      SectionItem(
                        title: AppLocalizations.of(context)!.recent,
                        titleStyle: Theme.of(context).textTheme.bodyLarge,
                        leading: Image.asset(
                          height: 24,
                          width: 24,
                          FileIcons.recent,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onTap:
                            () => onTap(
                              context,
                              recentDir,
                              AppLocalizations.of(context)!.recent,
                            ),
                      ),

                      SectionItem(
                        title: AppLocalizations.of(context)!.downloads,
                        titleStyle: Theme.of(context).textTheme.bodyLarge,
                        leading: Image.asset(
                          height: 24,
                          width: 24,
                          FileIcons.downloads,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onTap:
                            () => onTap(
                              context,
                              downloadsDir,
                              AppLocalizations.of(context)!.downloads,
                            ),
                      ),

                      SectionItem(
                        title: AppLocalizations.of(context)!.documents,
                        titleStyle: Theme.of(context).textTheme.bodyLarge,
                        leading: Image.asset(
                          height: 24,
                          width: 24,
                          FileIcons.homeDocuments,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onTap:
                            () => onTap(
                              context,
                              documentsDir,
                              AppLocalizations.of(context)!.documents,
                            ),
                      ),

                      SectionItem(
                        title: AppLocalizations.of(context)!.trash,
                        titleStyle: Theme.of(context).textTheme.bodyLarge,
                        leading: Image.asset(
                          height: 24,
                          width: 24,
                          FileIcons.delete,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TrashPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const Divider(height: 1, color: AppColors.backgroundVariant),

                  SectionList(
                    title: AppLocalizations.of(context)!.hardDriveTitle,
                    items: [
                      SectionItem(
                        title: AppLocalizations.of(context)!.root,
                        titleStyle: Theme.of(context).textTheme.bodyLarge,
                        leading: Image.asset(
                          height: 24,
                          width: 24,
                          FileIcons.hardDrive,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onTap:
                            () => onTap(
                              context,
                              "/",
                              AppLocalizations.of(context)!.root,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          bottomNavigationBar:
              isPickingDestination
                  ? PasteDestinationBottomBar(
                    onBack: () => Navigator.pop(context),
                    onMenu: () {
                      showModalBottomSheet(
                        context: context,
                        builder:
                            (_) => PasteActionsMenu(
                              controller: FileManagerController(),
                              closePasteActionsSheet:
                                  () => Navigator.pop(context),
                              isHomePage: true,
                            ),
                      );
                    },
                  )
                  : const NormalBottomBar(),
        );
      },
    );
  }

  void onTap(BuildContext context, String path, String title) {
    if (path == recentDir) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RecentFilesExplorerPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FileExplorerPage(startPath: path)),
      );
    }
  }
}

List<FileItem> pathToSegments(String fullPath) {
  // Remove leading/trailing slashes, then split
  final segments =
      fullPath.split('/').where((segment) => segment.isNotEmpty).toList();

  return segments.map((name) {
    return FileItem(name: name, type: 'dir', children: null);
  }).toList();
}
