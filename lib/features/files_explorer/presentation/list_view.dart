import 'dart:io' as io;
import 'dart:ui';

import 'package:ellipsized_text/ellipsized_text.dart';
import 'package:files/core/theme/app_theme.dart';
import 'package:files/core/utils/commons.dart';
import 'package:files/core/widgets/check_box/circular_checkbox.dart';
import 'package:files/features/files_explorer/controllers/file_manager.dart';
import 'package:files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:files/features/files_explorer/presentation/commons.dart';
import 'package:files/features/files_explorer/presentation/file_explorer.dart';
import 'package:files/features/files_explorer/presentation/single_select_action_menu.dart';
import 'package:files/features/files_home/data/models/file_item.dart';
import 'package:files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Widget buildListView(
  BuildContext context,
  ScrollController scrollController,
  FileManagerController controller,
  ValueNotifier<bool> selectionModeNotifier,
  ValueNotifier<Set<String>> selectedPathsNotifier,
  Function(String path) onToggleSelection,
) {
  final state = context.findAncestorStateOfType<FileExplorerPageState>();
  final isSearching = state?.isSearching ?? false;

  return ValueListenableBuilder<bool>(
    valueListenable: selectionModeNotifier,
    builder: (context, isSelectionMode, _) {
      return ValueListenableBuilder<Set<String>>(
        valueListenable: selectedPathsNotifier,
        builder: (context, selectedPaths, _) {
          return ValueListenableBuilder<List<io.FileSystemEntity>>(
            valueListenable: controller.paginatedEntities,
            builder: (context, entities, _) {
              if (entities.isEmpty) {
                // Show message if folder is empty
                return Center(
                  child: Text(
                    isSearching
                        ? AppLocalizations.of(
                          context,
                        )!.emptySearchResultsMessage
                        : AppLocalizations.of(context)!.emptyFolderMessage,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                );
              }

              // Move newly created folder to top
              if (controller.newFolderPath != null) {
                entities.sort((a, b) {
                  if (a.path == controller.newFolderPath) return -1;
                  if (b.path == controller.newFolderPath) return 1;
                  return 0;
                });
              }

              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: entities.length,
                  itemBuilder: (context, index) {
                    final entity = entities[index];
                    final title = controller.getDisplayName(entity);

                    final modified = entity.statSync().modified;
                    final isSelected = selectedPaths.contains(entity.path);
                    final isNew = entity.path == controller.newFolderPath;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 1,
                      ), // spacing between items
                      child: GestureDetector(
                        onSecondaryTap: () {
                          showSingleSelectActionsSheet(
                            context,
                            path: entity.path,
                            controller: controller,
                            state: state!,
                          );
                        },
                        onLongPress: () {
                          showSingleSelectActionsSheet(
                            context,
                            path: entity.path,
                            controller: controller,
                            state: state!,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isNew
                                    ? AppColors.backgroundVariant
                                    : isSelected
                                    ? AppColors.backgroundVariant
                                    : Colors.transparent,
                          ),
                          child: ListTile(
                            minTileHeight: 64,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),

                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelectionMode)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: CustomCircleCheckbox(
                                      isChecked: isSelected,
                                      onTap:
                                          () => state?.toggleSelection(
                                            entity.path,
                                          ),
                                    ),
                                  ),

                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Image.asset(
                                    entity.iconPath,
                                    fit: BoxFit.contain,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),

                            /// Title + Date
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                EllipsizedText(
                                  title,
                                  type: EllipsisType.middle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                Text(
                                  formatModifiedTime(modified),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),

                            trailing:
                                FileManager.isDirectory(entity)
                                    ? const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.onSurfaceVariant,
                                      size: 24,
                                    )
                                    : null,

                            onTap: () async {
                              if (isSelectionMode) {
                                state?.toggleSelection(entity.path);
                                return;
                              }

                              if (isSearching) {
                                state?.clearSearch();
                              }

                              if (FileManager.isDirectory(entity)) {
                                await controller.openDirectory(entity);
                                scrollController.jumpTo(0);
                              } else {
                                handleFileTap(
                                  context,
                                  entity,
                                  entity.path,
                                  isSelectionMode,
                                  state,
                                  controller,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );
    },
  );
}

class ExplorerListSection extends StatelessWidget {
  final FileManagerController controller;
  final ScrollController scrollController;
  final ValueNotifier<bool> selectionModeNotifier;
  final ValueNotifier<Set<String>> selectedPathsNotifier;
  final Function(String path) onToggleSelection;

  const ExplorerListSection({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.selectionModeNotifier,
    required this.selectedPathsNotifier,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return buildListView(
      context,
      scrollController,
      controller,
      selectionModeNotifier,
      selectedPathsNotifier,
      onToggleSelection,
    );
  }
}
