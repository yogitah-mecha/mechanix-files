import 'dart:async';

import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/core/utils/app_logger.dart';
import 'package:mechanix_files/core/widgets/custom_button.dart';
import 'package:mechanix_files/core/widgets/middle_ellipsis_text.dart';
import 'package:mechanix_files/core/widgets/toast/custom_app_toast.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_boc.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_event.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_state.dart';
import 'package:mechanix_files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:mechanix_files/features/files_explorer/data/models/conflict_resolution_strategy.dart';
import 'package:mechanix_files/features/files_explorer/presentation/commons.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

class FileConflict {
  final String path;
  final String fileName;
  final String destination;

  const FileConflict({
    required this.path,
    required this.fileName,
    required this.destination,
  });
}

class PasteHandler {
  static Future<void> handlePaste({
    required BuildContext context,
    required FilesState state,
    required FileManagerController controller,
    required VoidCallback reload,
    String? moveFilepath,
  }) async {
    final bloc = context.read<FilesBloc>();
    final targetPath = controller.getPathNotifier.value;
    final folderName = targetPath.split('/').last;

    /// ---------------- Single item FLOW ----------------
    if (moveFilepath != null && moveFilepath.isNotEmpty) {
      final itemName = p.basename(moveFilepath);

      final completer = Completer<void>();

      totalMovedCount = 1;

      bloc.add(
        Move(
          sourcePaths: [moveFilepath],
          destinationPath: targetPath,
          completer: completer,
        ),
      );

      await completer.future;

      if (!context.mounted) return;

      if (totalMovedCount != null && totalMovedCount! > 0) {
        CustomAppToast.show(
          context: context,
          type: ToastType.success,
          message: AppLocalizations.of(
            context,
          )!.movedItemToFolder(itemName, folderName),
        );
      } else {
        CustomAppToast.show(
          context: context,
          type: ToastType.info,
          message: AppLocalizations.of(context)!.noItemsMoved,
        );
      }
      totalMovedCount = null;

      return;
    }

    /// ---------------- MOVE FLOW ----------------
    if (state.isMoveMode) {
      final movePathCount = state.movedPaths.length;
      final hasInvalidMove = state.movedPaths.any((sourcePath) {
        final normalizedSource = p.normalize(sourcePath);
        final normalizedTarget = p.normalize(targetPath);

        return normalizedSource == normalizedTarget ||
            p.dirname(normalizedSource) == normalizedTarget ||
            p.isWithin(normalizedSource, normalizedTarget);
      });

      if (hasInvalidMove) {
        await Future.delayed(const Duration(milliseconds: 200));

        if (!context.mounted) return;
        await showInvalidMoveSheet(
          context: context,
          movePathCount: movePathCount,
        );
        return;
      }

      totalMovedCount = movePathCount;
      final completer = Completer<void>();
      bloc.add(
        Move(
          sourcePaths: state.movedPaths,
          destinationPath: targetPath,
          completer: completer,
        ),
      );

      await completer.future;
      if (!context.mounted) return;

      bloc.add(CancelMoveMode());
      reload();

      CustomAppToast.show(
        context: context,
        type: ToastType.success,
        message: AppLocalizations.of(
          context,
        )!.movedItemsToFolder(movePathCount, folderName),
      );

      totalMovedCount = null;
      return;
    }

    /// ---------------- COPY FLOW ----------------
    if (state.isCopyMode) {
      final completer = Completer<void>();
      final copyPathCount = state.copiedPaths.length;
      totalCopiedCount = copyPathCount;

      bloc.add(
        Copy(
          sourcePaths: state.copiedPaths,
          destinationPath: targetPath,
          controller: controller,
          completer: completer,
        ),
      );

      await completer.future;

      if (!context.mounted) return;

      bloc.add(CancelCopyMode());

      reload();
      final explorerState =
          context.findAncestorStateOfType<FileExplorerPageState>();

      explorerState?.closePanel();
      explorerState?.modeNotifier.value = ExplorerMode.browsing;

      CustomAppToast.show(
        context: context,
        type: ToastType.success,
        message: AppLocalizations.of(
          context,
        )!.copiedItemsToFolder(copyPathCount, folderName),
      );

      totalCopiedCount = null;
      return;
    }
  }

  static Future<void> showInvalidMoveSheet({
    required BuildContext context,
    required int movePathCount,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(color: AppColors.backgroundVariant),
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
            top: 32,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.cannotMoveFileOverItself),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: AppLocalizations.of(context)!.cancel,
                        backgroundColor: AppColors.onSurfaceVariantDark,
                        textColor: AppColors.onSurface,
                        borderRadius: 0,
                        onPressed: () {
                          context.read<FilesBloc>().add(CancelMoveMode());

                          Navigator.pop(sheetContext);
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: CustomButton(
                        label:
                            movePathCount > 1
                                ? AppLocalizations.of(context)!.skipAll
                                : AppLocalizations.of(context)!.skip,
                        backgroundColor: AppColors.onSurface,
                        textColor: AppColors.surface,
                        borderRadius: 0,
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> handleConflictsSequentially(
    BuildContext context,
    List<FileConflict> conflicts,
  ) async {
    final filesBloc = context.read<FilesBloc>();

    for (final conflict in conflicts) {
      if (!context.mounted) return;

      final strategy = await showModalBottomSheet<ConflictResolutionStrategy>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return ClipPath(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundVariant,
              ),
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
                top: 32,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fileStyle =
                            Theme.of(context).textTheme.headlineLarge;
                        final suffixStyle =
                            Theme.of(context).textTheme.titleLarge;
                        const suffix = ' already exists';

                        // Measure suffix width
                        final suffixWidth = textWidth(suffix, suffixStyle!);

                        // Remaining width for filename
                        final availableWidth = (constraints.maxWidth -
                                suffixWidth)
                            .clamp(0.0, double.infinity);

                        final truncatedName = middleEllipsisString(
                          conflict.fileName,
                          availableWidth,
                          fileStyle!,
                        );

                        return RichText(
                          maxLines: 1,
                          text: TextSpan(
                            children: [
                              TextSpan(text: truncatedName, style: fileStyle),
                              TextSpan(text: suffix, style: suffixStyle),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.replaceQuestion,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            label: AppLocalizations.of(context)!.cancel,
                            backgroundColor: AppColors.onSurfaceVariantDark,
                            textColor: AppColors.onSurface,
                            borderRadius: 0,
                            onPressed: () {
                              if (totalMovedCount != null &&
                                  totalMovedCount! > 0) {
                                totalMovedCount = totalMovedCount! - 1;
                              }

                              Navigator.pop(
                                sheetContext,
                                ConflictResolutionStrategy.skip,
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: CustomButton(
                            label: AppLocalizations.of(context)!.replace,
                            backgroundColor: AppColors.onSurface,
                            textColor: AppColors.surface,
                            borderRadius: 0,
                            onPressed: () {
                              Navigator.pop(
                                sheetContext,
                                ConflictResolutionStrategy.replace,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (strategy == null) continue;

      filesBloc.add(
        ContinueMoveWithConflictResolution(
          sourcePaths: [conflict.path],
          destinationPath: conflict.destination,
          strategy: strategy,
        ),
      );

      try {
        await filesBloc.stream
            .firstWhere(
              (s) =>
                  (!s.conflictingPaths.contains(conflict.path) && !s.loading) ||
                  (!s.isMoveMode),
            )
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        AppLogger.i(
          'Warning: waiting for conflict resolution timed out for ${conflict.fileName}: $e',
        );
      }
    }
  }
}

class ConflictResolutionBottomSheet extends StatelessWidget {
  final List<String> conflictingPaths;
  final String destinationPath;
  final FileManagerController controller;

  const ConflictResolutionBottomSheet({
    super.key,
    required this.conflictingPaths,
    required this.destinationPath,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(conflictingPaths.first);
    final currentConflict = conflictingPaths.first;
    return ClipPath(
      child: Container(
        decoration: const BoxDecoration(color: AppColors.backgroundVariant),
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16,
          top: 32,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  const suffixText = ' already exists';
                  final suffixStyle = Theme.of(context).textTheme.titleLarge;
                  final nameStyle = Theme.of(context).textTheme.headlineLarge;
                  final suffixWidth = textWidth(suffixText, suffixStyle!);
                  final availableForName = constraints.maxWidth - suffixWidth;
                  final truncatedName = middleEllipsisString(
                    fileName,
                    availableForName,
                    nameStyle!,
                  );

                  return RichText(
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    text: TextSpan(
                      children: [
                        TextSpan(text: truncatedName, style: nameStyle),
                        TextSpan(text: suffixText, style: suffixStyle),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.replaceQuestion,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: AppLocalizations.of(context)!.cancel,
                      backgroundColor: AppColors.onSurfaceVariantDark,
                      textColor: AppColors.onSurface,
                      borderRadius: 0,
                      onPressed: () {
                        if (totalCopiedCount != null && totalCopiedCount! > 0) {
                          totalCopiedCount = totalCopiedCount! - 1;
                        }
                        context.read<FilesBloc>().add(
                          ContinueCopyWithConflictResolution(
                            sourcePaths: [currentConflict],
                            destinationPath: destinationPath,
                            strategy: ConflictResolutionStrategy.skip,
                            controller: controller,
                          ),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: CustomButton(
                      label: AppLocalizations.of(context)!.replace,
                      backgroundColor: AppColors.onSurface,
                      textColor: AppColors.surface,
                      borderRadius: 0,
                      onPressed: () {
                        context.read<FilesBloc>().add(
                          ContinueCopyWithConflictResolution(
                            sourcePaths: [currentConflict],
                            destinationPath: destinationPath,
                            strategy: ConflictResolutionStrategy.replace,
                            controller: controller,
                          ),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
