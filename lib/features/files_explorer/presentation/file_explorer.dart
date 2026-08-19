import 'dart:async';
import 'package:ellipsized_text/ellipsized_text.dart';
import 'package:file/file.dart';
import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/constants/path_constants.dart';
import 'package:mechanix_files/core/utils/commons.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/core/widgets/toast/custom_app_toast.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_boc.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_event.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_state.dart';
import 'package:mechanix_files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:mechanix_files/features/files_explorer/data/models/conflict_resolution_strategy.dart';
import 'package:mechanix_files/features/files_explorer/presentation/bottom_bar_widgets.dart';
import 'package:mechanix_files/features/files_explorer/presentation/breadcrumbs.dart';
import 'package:mechanix_files/features/files_explorer/presentation/commons.dart';
import 'package:mechanix_files/features/files_explorer/presentation/trash_confirmation_dialog.dart';
import 'package:mechanix_files/features/files_explorer/presentation/list_view.dart';
import 'package:mechanix_files/features/files_explorer/presentation/paste_handler.dart';
import 'package:mechanix_files/features/files_explorer/presentation/search_dialog.dart';
import 'package:mechanix_files/features/files_home/data/models/file_item.dart';
import 'package:mechanix_files/features/trash/bloc/trash_bloc.dart';
import 'package:mechanix_files/features/trash/bloc/trash_event.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

enum ExplorerBottomPanel { none, menu, info, selectMenu, pasteMenu }

enum ExplorerMode {
  browsing, // normal explorer
  selecting, // multi-select mode
  moving, // move-to mode
  copying, // copy-to mode
}

int? totalMovedCount;
int? totalCopiedCount;

class FileExplorerPage extends StatefulWidget {
  final String? startPath;
  final List<FileItem> path;

  const FileExplorerPage({super.key, this.startPath, this.path = const []});

  @override
  State<FileExplorerPage> createState() => FileExplorerPageState();
}

class FileExplorerPageState extends State<FileExplorerPage> {
  final FileManagerController controller = FileManagerController();
  List<FileSystemEntity> files = [];
  String currentPath = '';
  final ValueNotifier<bool> selectionModeNotifier = ValueNotifier(false);

  final ValueNotifier<Set<String>> selectedPathsNotifier = ValueNotifier({});

  final ValueNotifier<String> searchQuery = ValueNotifier('');
  bool isSearching = false;
  final ValueNotifier<bool> hasSelectionNotifier = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  final downloadsDir = AppPaths.downloadsDir;
  final documentsDir = AppPaths.documentsDir;
  final homeDir = AppPaths.homeDir;
  final recentDir = AppPaths.recentDir;
  bool isHomePageDir = false;
  bool _copyConflictDialogOpen = false;

  final ValueNotifier<ExplorerBottomPanel> activePanelNotifier = ValueNotifier(
    ExplorerBottomPanel.none,
  );
  final ValueNotifier<String?> infoPathNotifier = ValueNotifier(null);
  final ValueNotifier<ExplorerMode> modeNotifier = ValueNotifier(
    ExplorerMode.browsing,
  );
  final ValueNotifier<String?> selectedItemPathNotifier = ValueNotifier(null);
  final ScrollController breadcrumbScrollController = ScrollController();
  final searchOverlayController = SearchOverlayController();
  final _focusNode = FocusNode();

  final Map<String, double> _scrollPositions = {};
  bool _shouldRestoreScroll = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    controller.getPathNotifier.addListener(_onPathChanged);
    controller.paginatedEntities.addListener(_onEntitiesChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeExplorer();
    });

    _openKeyboardAfterLoad();
  }

  void _onPathChanged() {
    final oldPath = currentPath;
    final newPath = controller.getPathNotifier.value;

    if (oldPath.isNotEmpty && _scrollController.hasClients) {
      _scrollPositions[oldPath] = _scrollController.offset;
    }

    _scrollPositions.removeWhere(
      (savedPath, _) => p.isWithin(newPath, savedPath),
    );

    setState(() {
      currentPath = newPath;
      _shouldRestoreScroll = true;
    });
  }

  void _onEntitiesChanged() {
    if (_shouldRestoreScroll) {
      _shouldRestoreScroll = false;
      final targetOffset = _scrollPositions[currentPath] ?? 0.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(targetOffset);
        }
      });
    }
  }

  Future<void> _initializeExplorer() async {
    if (!mounted) return;

    controller.syncSettings(
      showHidden: context.read<FilesBloc>().state.showHiddenFiles,
    );

    final initialPath = widget.startPath;

    // No external path: open Home normally.
    if (initialPath == null || initialPath.isEmpty) {
      await controller.openDirectory(AppFileSystem.instance.directory(homeDir));
      return;
    }

    final type = AppFileSystem.instance.typeSync(initialPath);

    if (type == FileSystemEntityType.file) {
      final file = AppFileSystem.instance.file(initialPath);

      // Open the parent directory directly.
      await controller.openDirectory(file.parent);

      if (!mounted) return;

      // Then open the file.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        handleFileTap(
          context,
          file,
          initialPath,
          false,
          this,
          controller,
          disableTransition: true,
        );
      });

      return;
    }

    if (type == FileSystemEntityType.directory) {
      await controller.openDirectory(
        AppFileSystem.instance.directory(initialPath),
      );
      return;
    }

    // Invalid/non-existing path: fall back to Home.
    await controller.openDirectory(AppFileSystem.instance.directory(homeDir));
  }

  void _openKeyboardAfterLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 300));
      _focusNode.requestFocus();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasPixels || !position.hasContentDimensions) return;

    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // Trigger near bottom
    if (currentScroll >= 0.8 * maxScroll) {
      controller.loadNextChunk();
    }
  }

  @override
  void dispose() {
    searchQuery.dispose();
    searchOverlayController.dispose();

    controller.getPathNotifier.removeListener(_onPathChanged);
    controller.paginatedEntities.removeListener(_onEntitiesChanged);

    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    breadcrumbScrollController.dispose();

    super.dispose();
  }

  Future<void> handleBack() async {
    // 1. Exit selection mode first
    if (selectionModeNotifier.value) {
      clearSelection();
      return;
    }

    // 2. Close bottom menu if open
    if (activePanelNotifier.value != ExplorerBottomPanel.none) {
      closePanel();
      return;
    }

    // 3. Normal navigation logic
    if (controller.getCurrentPath.isEmpty) return;

    final current = AppFileSystem.instance.directory(controller.getCurrentPath);
    final parent = current.parent;

    if (parent.path == current.path || await controller.isRootDirectory()) {
      homeNavigation();
      return;
    }

    await controller.goToParentDirectory();
  }

  void homeNavigation() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isAtRoot = currentPath == '/' || currentPath.isEmpty;

    final isDocumentsDir = currentPath == documentsDir;
    final isDownloadsDir = currentPath == downloadsDir;
    final isHomeDir = currentPath == homeDir;
    final isRecentDir = currentPath == recentDir;
    isHomePageDir =
        isHomeDir ||
        isDownloadsDir ||
        isDocumentsDir ||
        isAtRoot ||
        isRecentDir;

    return MultiBlocListener(
      listeners: [
        // Global error message handler
        BlocListener<FilesBloc, FilesState>(
          listenWhen:
              (previous, current) =>
                  previous.error != current.error && current.error != null,
          listener: (context, state) {
            CustomAppToast.show(
              context: context,
              message: AppLocalizations.of(
                context,
              )!.errorMessage(state.error ?? ''),
              type: ToastType.error,
            );
          },
        ),

        // Move: Show conflict resolution dialog
        BlocListener<FilesBloc, FilesState>(
          listenWhen:
              (prev, curr) => prev.conflictingPaths != curr.conflictingPaths,
          listener: (context, state) async {
            if (!mounted) return;

            if (!_copyConflictDialogOpen &&
                !state.loading &&
                state.conflictingPaths.isNotEmpty &&
                state.isMoveMode) {
              final conflicts =
                  state.conflictingPaths.map((path) {
                    return FileConflict(
                      path: path,
                      fileName: p.basename(path),
                      destination: state.conflictDestinationPath,
                    );
                  }).toList();

              totalMovedCount ??= state.movedPaths.length;
              _copyConflictDialogOpen = true;

              await PasteHandler.handleConflictsSequentially(
                context,
                conflicts,
              );

              if (!mounted) return;

              final folderName = p.basename(state.conflictDestinationPath);

              if (totalMovedCount != null && totalMovedCount! > 0) {
                CustomAppToast.show(
                  context: context,
                  type: ToastType.success,
                  message: AppLocalizations.of(
                    context,
                  )!.movedItemsToFolder(totalMovedCount!, folderName),
                );
              } else {
                CustomAppToast.show(
                  context: context,
                  type: ToastType.info,
                  message: AppLocalizations.of(context)!.noItemsMoved,
                );
              }

              context.read<FilesBloc>().add(CancelMoveMode());
              totalMovedCount = null;

              reload();

              _copyConflictDialogOpen = false;
            }
          },
        ),

        //Copy: Show conflict resolution dialog
        BlocListener<FilesBloc, FilesState>(
          listenWhen:
              (prev, curr) =>
                  prev.conflictingPaths != curr.conflictingPaths ||
                  prev.isCopyMode != curr.isCopyMode,
          listener: (context, state) {
            if (!state.loading &&
                state.conflictingPaths.isNotEmpty &&
                state.isCopyMode) {
              totalCopiedCount ??= state.copiedPaths.length;

              showModalBottomSheet<ConflictResolutionStrategy>(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                isDismissible: false,
                enableDrag: false,
                backgroundColor: Colors.transparent,
                builder: (sheetContext) {
                  return ConflictResolutionBottomSheet(
                    conflictingPaths: state.conflictingPaths,
                    destinationPath: state.conflictDestinationPath,
                    controller: controller,
                  );
                },
              );
            } else if (!state.loading &&
                state.conflictingPaths.isEmpty &&
                !state.isCopyMode &&
                totalCopiedCount != null) {
              final folderName = p.basename(
                state.conflictDestinationPath.isNotEmpty
                    ? state.conflictDestinationPath
                    : currentPath,
              );

              if (totalCopiedCount! > 0) {
                CustomAppToast.show(
                  context: context,
                  type: ToastType.success,
                  message: AppLocalizations.of(
                    context,
                  )!.copiedItemsToFolder(totalCopiedCount!, folderName),
                );
              } else {
                CustomAppToast.show(
                  context: context,
                  type: ToastType.info,
                  message: AppLocalizations.of(context)!.noItemsCopied,
                );
              }

              context.read<FilesBloc>().add(CancelCopyMode());
              totalCopiedCount = null;
              closePanel();
              modeNotifier.value = ExplorerMode.browsing;
              reload();
            }
          },
        ),

        // Controller settings sync
        BlocListener<FilesBloc, FilesState>(
          listenWhen:
              (prev, curr) => prev.showHiddenFiles != curr.showHiddenFiles,
          listener: (context, state) {
            controller.syncSettings(showHidden: state.showHiddenFiles);
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: BlocSelector<
            FilesBloc,
            FilesState,
            ({
              bool isCopy,
              bool isMove,
              int copiedItemCount,
              int movedItemCount,
            })
          >(
            selector:
                (state) => (
                  isCopy: state.isCopyMode,
                  isMove: state.isMoveMode,
                  copiedItemCount: state.copiedPaths.length,
                  movedItemCount: state.movedPaths.length,
                ),
            builder: (context, mode) {
              return ValueListenableBuilder<Set<String>>(
                valueListenable: selectedPathsNotifier,
                builder: (context, selectedPaths, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: selectionModeNotifier,
                    builder: (context, isSelectionMode, _) {
                      return ValueListenableBuilder<List<FileSystemEntity>>(
                        valueListenable: controller.paginatedEntities,
                        builder: (context, entities, _) {
                          return ExplorerBreadcrumbs(
                            isCopyMode: mode.isCopy,
                            isMoveMode: mode.isMove,
                            copiedItemCount: mode.copiedItemCount,
                            movedItemCount: mode.movedItemCount,

                            parentContext: context,
                            currentPath: currentPath,
                            controller: controller,
                            scrollController: breadcrumbScrollController,

                            /// selection
                            selectionCount: selectedPaths.length,
                            isSelectionMode: isSelectionMode,

                            /// search mode
                            isSearching: isSearching,
                            searchCount: controller.filteredEntities.length,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),

        body: Stack(
          children: [
            Column(
              children: [
                const Divider(height: 1, color: AppColors.backgroundVariant),
                Expanded(
                  child: ExplorerListSection(
                    controller: controller,
                    scrollController: _scrollController,
                    selectionModeNotifier: selectionModeNotifier,
                    selectedPathsNotifier: selectedPathsNotifier,
                    onToggleSelection: toggleSelection,
                  ),
                ),
              ],
            ),
            ValueListenableBuilder(
              valueListenable: activePanelNotifier,
              builder: (context, activePanel, _) {
                if (activePanel == ExplorerBottomPanel.none) {
                  return const SizedBox.shrink();
                }

                return Positioned.fill(
                  child: GestureDetector(
                    onTap: closePanel,
                    child: Container(color: Colors.black54),
                  ),
                );
              },
            ),
          ],
        ),

        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder(
              valueListenable: activePanelNotifier,
              builder: (context, activePanel, _) {
                return ValueListenableBuilder(
                  valueListenable: infoPathNotifier,
                  builder: (context, infoPath, _) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: BottomPanel(
                        activePanel: activePanel,
                        controller: controller,
                        state: this,
                        closePanel: closePanel,
                        infoPath: infoPath,
                        selectedItemPath: selectedItemPathNotifier.value,
                      ),
                    );
                  },
                );
              },
            ),

            BlocBuilder<FilesBloc, FilesState>(
              builder: (context, filesState) {
                final isDestinationMode =
                    filesState.isCopyMode || filesState.isMoveMode;

                if (isDestinationMode) {
                  return PasteDestinationBottomBar(
                    rootContext: context,
                    isCopyMode: filesState.isCopyMode,
                  );
                }

                return ValueListenableBuilder<bool>(
                  valueListenable: selectionModeNotifier,
                  builder: (_, selecting, __) {
                    return selecting
                        ? SelectionBottomBar(rootContext: context)
                        : NormalBottomBar(rootContext: context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void onSearchPressed() {
    setState(() {
      isSearching = true;
    });

    searchOverlayController.show(
      context,
      searchQuery: searchQuery,
      onClear: () {
        clearSearch();
      },

      onSearch: (query) {
        if (query.trim().length > 2) {
          controller.search(query.trim());
        } else if (query.isEmpty) {
          controller.reload();
        }
      },
    );
  }

  void clearSearch() {
    setState(() {
      isSearching = false;
      searchQuery.value = '';
    });

    // safely remove overlay if still mounted
    searchOverlayController.hide();

    // Reload directory content when clearing search
    controller.search('');
  }

  void toggleBottomPanel(ExplorerBottomPanel panel) {
    activePanelNotifier.value =
        activePanelNotifier.value == panel ? ExplorerBottomPanel.none : panel;
  }

  void closePanel() {
    activePanelNotifier.value = ExplorerBottomPanel.none;
    infoPathNotifier.value = null;
  }

  void showInfo(String path) {
    infoPathNotifier.value = path;
    activePanelNotifier.value = ExplorerBottomPanel.info;
  }

  void showMultiselectActions() {
    activePanelNotifier.value = ExplorerBottomPanel.selectMenu;
  }

  bool isSelected(String path) => selectedPathsNotifier.value.contains(path);

  void setHasSelection(bool value) {
    if (hasSelectionNotifier.value != value) {
      hasSelectionNotifier.value = value;
    }
  }

  void toggleSelection(String path) {
    final current = Set<String>.from(selectedPathsNotifier.value);

    if (current.contains(path)) {
      current.remove(path);
    } else {
      current.add(path);
    }

    selectedPathsNotifier.value = current;

    final hasSelection = current.isNotEmpty;

    selectionModeNotifier.value = hasSelection;
    setHasSelection(hasSelection);

    // sync mode with selection state
    modeNotifier.value =
        hasSelection ? ExplorerMode.selecting : ExplorerMode.browsing;
  }

  void clearSelection() {
    selectedPathsNotifier.value = {};
    selectionModeNotifier.value = false;
    hasSelectionNotifier.value = false;

    if (activePanelNotifier.value == ExplorerBottomPanel.selectMenu) {
      closePanel();
    }
  }

  void enableSelect() {
    selectionModeNotifier.value = true;
    selectedPathsNotifier.value = {};
    modeNotifier.value = ExplorerMode.selecting;
  }

  void openMenu() {
    final filesState = context.read<FilesBloc>().state;
    final isDestinationMode = filesState.isCopyMode || filesState.isMoveMode;

    if (selectionModeNotifier.value) {
      toggleBottomPanel(ExplorerBottomPanel.selectMenu);
    } else if (isDestinationMode) {
      toggleBottomPanel(ExplorerBottomPanel.pasteMenu);
    } else {
      toggleBottomPanel(ExplorerBottomPanel.menu);
    }
  }

  void handleSelectAll() {
    // final files = controller.paginatedEntities.value;
    final files = controller.filteredEntities;
    final allPaths = {for (final file in files) file.path};
    selectedPathsNotifier.value = allPaths;

    final hasSelection = allPaths.isNotEmpty;
    selectionModeNotifier.value = hasSelection;

    setHasSelection(hasSelection);
  }

  void handleCopy() {
    modeNotifier.value = ExplorerMode.copying;
    context.read<FilesBloc>().add(
      StartCopyMode(selectedPathsNotifier.value.toList()),
    );

    clearSelection();
    Navigator.pop(context);
  }

  void handleMove() {
    modeNotifier.value = ExplorerMode.moving;
    context.read<FilesBloc>().add(
      StartMoveMode(selectedPathsNotifier.value.toList()),
    );

    clearSelection();
    Navigator.pop(context);
  }

  void handleSingleItemMove(String moveFilepath) {
    modeNotifier.value = ExplorerMode.moving;
    context.read<FilesBloc>().add(StartMoveMode([moveFilepath]));
  }

  void reload() {
    controller.reload();
  }

  Future<void> handlePaste() async {
    await PasteHandler.handlePaste(
      context: context,
      state: context.read<FilesBloc>().state,
      controller: controller,
      reload: reload,
    );
  }

  Future<void> handleCreateFolderWithItems([String moveFilepath = '']) async {
    final filesState = context.read<FilesBloc>().state;

    final hasSinglePath = moveFilepath.isNotEmpty;
    final hasMoveItems = filesState.movedPaths.isNotEmpty;

    if (!hasSinglePath && !hasMoveItems) {
      return;
    }

    // Create folder
    var folderName = await createFolder();

    final renamedPath = await showRenameSheet(initialName: folderName);

    if (renamedPath == null || renamedPath.isEmpty) {
      return;
    }

    final folderPath = p.join(currentPath, renamedPath);

    final previousPath = controller.getCurrentPath;

    // Open newly created folder
    await controller.openDirectory(
      AppFileSystem.instance.directory(folderPath),
    );

    // Paste inside it
    await PasteHandler.handlePaste(
      context: context,
      state: filesState,
      controller: controller,
      reload: reload,
      moveFilepath: moveFilepath,
    );

    // Restore previous location
    await controller.openDirectory(
      AppFileSystem.instance.directory(previousPath),
    );

    reload();

    if (!mounted) return;

    final bloc = context.read<FilesBloc>();

    if (filesState.isMoveMode) {
      bloc.add(CancelMoveMode());
    }

    modeNotifier.value = ExplorerMode.browsing;
  }

  Future<String> createFolder() async {
    final bloc = context.read<FilesBloc>();
    final path = controller.getCurrentPath;

    final folderName = await generateUniqueFolderName(context, path);

    bloc.add(
      CreateFolder(path: path, folderName: folderName, controller: controller),
    );

    return folderName;
  }

  Future<String?> showRenameSheet({required String initialName}) async {
    final controllerText = TextEditingController(text: initialName);

    final oldPath = p.join(controller.getCurrentPath, initialName);
    controller.markNewFolder(oldPath);

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final text = controllerText.text.trim();
            final isEmpty = text.isEmpty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundVariantDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(
                      height: 1,
                      color: AppColors.backgroundVariant,
                    ),

                    const SizedBox(height: 12),

                    /// header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: EllipsizedText(
                            AppLocalizations.of(ctx)!.renameItem(initialName),
                            type: EllipsisType.middle,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        CustomIconButton.icon(
                          iconData: Icons.close,
                          onPressed: () {
                            controller.clearLiveRename();
                            controller.clearNewFolder();
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const Divider(
                      height: 1,
                      color: AppColors.backgroundVariant,
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: controllerText,
                      focusNode: _focusNode,
                      autofocus: false,
                      onChanged: (v) {
                        setState(() {});
                        controller.setLiveRename(oldPath, v);
                      },
                      onSubmitted: (_) {
                        _submitRename(
                          ctx,
                          oldPath,
                          controllerText.text.trim(),
                          initialName,
                        );
                      },
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(ctx)!.enterName,
                        errorText:
                            isEmpty
                                ? AppLocalizations.of(ctx)!.nameCannotBeEmpty
                                : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        suffixIcon: CustomIconButton.asset(
                          assetPath: FileIcons.clear,
                          onPressed: controllerText.clear,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(
                      height: 1,
                      color: AppColors.backgroundVariant,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitRename(
    BuildContext ctx,
    String oldPath,
    String newName,
    String initialName,
  ) async {
    if (newName.isEmpty) return;

    // If unchanged, just close sheet and return current path
    if (newName == initialName.trim()) {
      controller.clearLiveRename();
      controller.clearNewFolder();

      Navigator.pop(ctx, newName);
      return;
    }

    final newPath = p.join(p.dirname(oldPath), newName);

    final exists =
        await AppFileSystem.instance.file(newPath).exists() ||
        await AppFileSystem.instance.directory(newPath).exists();

    if (exists) {
      if (!ctx.mounted) return;
      CustomAppToast.show(
        context: ctx,
        message: AppLocalizations.of(ctx)!.itemAlreadyExists,
        type: ToastType.error,
      );
      return;
    }

    ctx.read<FilesBloc>().add(
      Rename(oldPath: oldPath, newName: newName, controller: controller),
    );

    controller.clearLiveRename();
    controller.clearNewFolder();

    Navigator.pop(ctx, newPath);
  }

  void toggleHiddenFiles() {
    controller.toggleShowHiddenFiles();

    context.read<FilesBloc>().add(ToggleHiddenFiles());
  }

  Future<void> handleMoveToTrash() async {
    final paths = selectedPathsNotifier.value.toList();

    if (paths.isEmpty) return;

    final confirmed = await showMoveToTrashConfirmationSheet(
      context: context,
      itemCount: paths.length,
    );

    if (confirmed != true) return;
    final completer = Completer<void>();
    context.read<TrashBloc>().add(MoveToTrash(paths, completer: completer));

    clearSelection();
    await completer.future;
    await controller.reload();
  }
}
