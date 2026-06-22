import 'dart:ui';

import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/core/constants/path_constants.dart';
import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ExplorerBreadcrumbs extends StatelessWidget {
  final bool isCopyMode;
  final bool isMoveMode;
  final int copiedItemCount;
  final int movedItemCount;
  final BuildContext parentContext;
  final String currentPath;
  final FileManagerController controller;
  final ScrollController scrollController;
  final int selectionCount;
  final bool isSelectionMode;
  final bool isSearching;
  final int searchCount;

  const ExplorerBreadcrumbs({
    super.key,
    required this.isCopyMode,
    required this.isMoveMode,
    required this.copiedItemCount,
    required this.movedItemCount,
    required this.parentContext,
    required this.currentPath,
    required this.controller,
    required this.scrollController,
    required this.selectionCount,
    required this.isSelectionMode,
    required this.isSearching,
    required this.searchCount,
  });

  @override
  Widget build(BuildContext context) {
    _scrollToEnd();

    /// ---------------- COPY / MOVE MODE HEADER ----------------
    if (isCopyMode || isMoveMode) {
      final count = isCopyMode ? copiedItemCount : movedItemCount;
      final label =
          isCopyMode
              ? AppLocalizations.of(context)!.copy
              : AppLocalizations.of(context)!.move;
      final pathBreadcrumbs = _buildBreadcrumbs(context);

      return SizedBox(
        width: double.infinity,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ---------------- STATIC LABEL ----------------
                Text(
                  count == 1
                      ? AppLocalizations.of(context)!.copyMoveSingleItem(label)
                      : AppLocalizations.of(
                        context,
                      )!.copyMoveMultipleItems(label, count),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(">"),
                ),

                /// ---------------- BREADCRUMBS ----------------
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(pathBreadcrumbs.length, (index) {
                    final item = pathBreadcrumbs[index];
                    final isLast = index == pathBreadcrumbs.length - 1;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap:
                                isLast
                                    ? null
                                    : () async {
                                      await controller.openDirectory(
                                        AppFileSystem.instance.directory(
                                          item['path']!,
                                        ),
                                      );

                                      if (scrollController.hasClients) {
                                        scrollController.jumpTo(
                                          scrollController
                                              .position
                                              .maxScrollExtent,
                                        );
                                      }
                                    },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              child: Text(
                                item['label']!,
                                style: Theme.of(
                                  context,
                                ).textTheme.labelLarge?.copyWith(
                                  fontWeight:
                                      isLast
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                  color:
                                      isLast
                                          ? AppColors.onSurface
                                          : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (!isLast)
                          const Icon(
                            Icons.chevron_right,
                            size: 28,
                            color: AppColors.onSurfaceVariant,
                          ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    }

    /// ---------------- SELECTION MODE HEADER ----------------
    if (isSelectionMode) {
      if (selectionCount > 0) {
        return Text(
          AppLocalizations.of(context)!.selectedItems(selectionCount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium,
        );
      }

      if (selectionCount == 0 && isCopyMode == false && isMoveMode == false) {
        return Text(
          AppLocalizations.of(context)!.noSelection,
          style: Theme.of(context).textTheme.headlineMedium,
        );
      }
    }

    /// ---------------- SEARCH MODE HEADER ----------------
    if (isSearching) {
      return Text(
        AppLocalizations.of(context)!.searchResults(searchCount),
        style: Theme.of(context).textTheme.headlineMedium,
      );
    }

    /// ---------------- NORMAL BREADCRUMB ----------------
    final breadcrumbs = _buildBreadcrumbs(context);

    return SizedBox(
      width: double.infinity,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(breadcrumbs.length, (index) {
              final item = breadcrumbs[index];
              final isLast = index == breadcrumbs.length - 1;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap:
                          isLast
                              ? null
                              : () async {
                                await controller.openDirectory(
                                  AppFileSystem.instance.directory(
                                    item['path']!,
                                  ),
                                );
                                if (scrollController.hasClients) {
                                  scrollController.jumpTo(0);
                                }
                              },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Text(
                          item['label']!,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            fontWeight:
                                isLast ? FontWeight.w600 : FontWeight.w400,
                            color:
                                isLast
                                    ? AppColors.onSurface
                                    : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Icon(
                      Icons.chevron_right,
                      size: 28,
                      color: AppColors.onSurfaceVariant,
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _buildBreadcrumbs(BuildContext context) {
    final breadcrumbs = <Map<String, String>>[];

    final homeDir = AppPaths.homeDir;
    final downloadsDir = AppPaths.downloadsDir;
    final documentsDir = AppPaths.documentsDir;
    final recentDir = AppPaths.recentDir;
    final trashDir = AppPaths.trashDir;

    if (currentPath == '/' || currentPath.isEmpty) {
      return [
        {'label': AppLocalizations.of(context)!.root, 'path': '/'},
      ];
    }

    /// Recent
    if (currentPath == recentDir) {
      return [
        {'label': AppLocalizations.of(context)!.recent, 'path': recentDir},
      ];
    }

    /// Trash
    if (currentPath == trashDir) {
      return [
        {'label': AppLocalizations.of(context)!.trash, 'path': trashDir},
      ];
    }

    /// Inside Trash
    if (currentPath.startsWith(trashDir)) {
      breadcrumbs.add({
        'label': AppLocalizations.of(context)!.trash,
        'path': trashDir,
      });

      final relative = currentPath.substring(trashDir.length);

      final segments = relative.split('/').where((e) => e.isNotEmpty).toList();

      String accumulated = trashDir;

      for (final segment in segments) {
        accumulated = '$accumulated/$segment';

        breadcrumbs.add({'label': segment, 'path': accumulated});
      }

      return breadcrumbs;
    }

    /// Home hierarchy
    if (currentPath.startsWith(homeDir)) {
      breadcrumbs.add({
        'label': AppLocalizations.of(context)!.home,
        'path': homeDir,
      });

      final relative = currentPath.substring(homeDir.length);

      final segments = relative.split('/').where((e) => e.isNotEmpty).toList();

      String accumulated = homeDir;

      for (final segment in segments) {
        accumulated = '$accumulated/$segment';

        breadcrumbs.add({
          'label': _format(
            segment,
            downloadsDir,
            documentsDir,
            trashDir,
            context,
          ),
          'path': accumulated,
        });
      }

      return breadcrumbs;
    }

    /// Root hierarchy
    breadcrumbs.add({'label': AppLocalizations.of(context)!.root, 'path': '/'});

    final segments = currentPath.split('/').where((e) => e.isNotEmpty).toList();

    String accumulated = '';

    for (final segment in segments) {
      accumulated += '/$segment';

      breadcrumbs.add({'label': segment, 'path': accumulated});
    }

    return breadcrumbs;
  }

  String _format(
    String segment,
    String downloadsDir,
    String documentsDir,
    String trashDir,
    BuildContext context,
  ) {
    final lower = segment.toLowerCase();

    if (downloadsDir.toLowerCase().endsWith(lower)) {
      return AppLocalizations.of(context)!.downloads;
    }

    if (documentsDir.toLowerCase().endsWith(lower)) {
      return AppLocalizations.of(context)!.documents;
    }

    if (trashDir.toLowerCase().endsWith(lower)) {
      return AppLocalizations.of(context)!.trash;
    }

    return segment;
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }
}
