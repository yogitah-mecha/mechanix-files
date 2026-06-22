import 'dart:async';

import 'package:mechanix_files/features/files_explorer/blocs/file_event.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_state.dart';
import 'package:mechanix_files/features/files_explorer/data/models/conflict_resolution_strategy.dart';
import 'package:mechanix_files/features/files_explorer/data/repositories/app_settings_repository.dart';
import 'package:mechanix_files/features/files_explorer/data/repositories/file_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

class FilesBloc extends Bloc<FilesEvent, FilesState> {
  final FileRepository fileRepository;
  final AppSettingsRepository appSettingsRepository;

  FilesBloc({required this.fileRepository, required this.appSettingsRepository})
    : super(
        const FilesState(
          fileSystemList: [],
          loading: false,
          error: null,
          conflictDestinationPath: '',
        ),
      ) {
    on<InitializeFiles>(_onInitializeFiles);
    on<CreateFolder>(_onCreateFolder);
    on<Rename>(_onRename);

    on<Copy>(_onCopy);
    on<StartCopyMode>(_onStartCopyMode);
    on<CancelCopyMode>(_onCancelCopyMode);
    on<ContinueCopyWithConflictResolution>(
      _onContinueCopyWithConflictResolution,
    );

    on<Move>(_onMove);
    on<StartMoveMode>(_onStartMoveMode);
    on<CancelMoveMode>(_onCancelMoveMode);
    on<ContinueMoveWithConflictResolution>(
      _onContinueMoveWithConflictResolution,
    );

    on<FetchFileDetails>(_onFetchFileDetails);
    on<ToggleHiddenFiles>(_onToggleHiddenFiles);

    on<SearchFilesInDirectory>(_onSearchFilesInDirectory);
    on<ClearSearchResults>((event, emit) {
      emit(state.copyWith(fileSystemList: [], loading: false));
    });
  }

  Future<void> _onInitializeFiles(
    InitializeFiles event,
    Emitter<FilesState> emit,
  ) async {
    emit(state.copyWith(loading: true));

    final settings = await appSettingsRepository.getSettings();

    emit(
      state.copyWith(loading: false, showHiddenFiles: settings.showHiddenFiles),
    );
  }

  Future<void> _onCreateFolder(
    CreateFolder event,
    Emitter<FilesState> emit,
  ) async {
    try {
      emit(state.copyWith(loading: true));

      // Create folder
      await fileRepository.createFolder(event.path, event.folderName);

      // Mark this folder as new (important!)
      final newFolderPath = "${event.path}/${event.folderName}";
      event.controller.markNewFolder(newFolderPath);

      // Reload file list AFTER tagging the new folder
      await event.controller.reload();

      emit(state.copyWith(loading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }

  Future<void> _onRename(Rename event, Emitter<FilesState> emit) async {
    try {
      emit(state.copyWith(loading: true));
      await fileRepository.renameEntity(event.oldPath, event.newName);
      await event.controller.reload();
      emit(state.copyWith(loading: false));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to rename item: $e', loading: false));
    }
  }

  Future<void> _onCopy(Copy event, Emitter<FilesState> emit) async {
    try {
      emit(state.copyWith(loading: true, error: null));

      final conflicts = <String>[];
      final nonConflicts = <String>[];

      for (final sourcePath in event.sourcePaths) {
        final fileName = p.basename(sourcePath);
        final destination = p.join(event.destinationPath, fileName);

        final exists = await fileRepository.entityExists(destination);

        if (exists) {
          conflicts.add(sourcePath);
        } else {
          nonConflicts.add(sourcePath);
        }
      }

      // First: copy non-conflicting files
      if (nonConflicts.isNotEmpty) {
        await fileRepository.copyEntities(
          nonConflicts,
          event.destinationPath,
          strategy: ConflictResolutionStrategy.replace,
        );
      }

      // Then: handle conflicts
      if (conflicts.isNotEmpty) {
        emit(
          state.copyWith(
            loading: false,
            conflictingPaths: conflicts,
            conflictDestinationPath: event.destinationPath,
            isCopyMode: true,
            copiedPaths: conflicts,
          ),
        );
      } else {
        // No conflicts, all done
        event.completer?.complete();
        emit(state.copyWith(loading: false, copiedPaths: []));
      }
    } catch (e) {
      emit(state.copyWith(error: 'Failed to copy: $e', loading: false));
    }
  }

  Future<void> _onContinueCopyWithConflictResolution(
    ContinueCopyWithConflictResolution event,
    Emitter<FilesState> emit,
  ) async {
    try {
      emit(state.copyWith(loading: true, error: null));

      final resolvedPath = event.sourcePaths.first;

      await fileRepository.copyEntities(
        [resolvedPath],
        event.destinationPath,
        strategy: event.strategy,
      );

      final remainingConflicts = List<String>.from(state.conflictingPaths)
        ..remove(resolvedPath);
      final remainingCopied = List<String>.from(state.copiedPaths)
        ..remove(resolvedPath);

      if (remainingConflicts.isNotEmpty) {
        emit(
          state.copyWith(
            conflictingPaths: remainingConflicts,
            copiedPaths: remainingCopied,
            loading: false,
          ),
        );
      } else {
        // All conflicts resolved
        await event.controller!.reload();

        emit(
          state.copyWith(
            conflictingPaths: [],
            conflictDestinationPath: '',
            isCopyMode: false,
            copiedPaths: [],
            loading: false,
          ),
        );
      }
    } catch (e) {
      final remainingConflicts = List<String>.from(state.conflictingPaths);
      if (remainingConflicts.isNotEmpty) {
        remainingConflicts.remove(event.sourcePaths.first);
      }
      final remainingCopied = List<String>.from(state.copiedPaths);
      if (remainingCopied.isNotEmpty) {
        remainingCopied.remove(event.sourcePaths.first);
      }
      emit(
        state.copyWith(
          error: 'Failed to copy: $e',
          conflictingPaths: remainingConflicts,
          copiedPaths: remainingCopied,
          isCopyMode: remainingConflicts.isNotEmpty,
          loading: false,
        ),
      );
    }
  }

  Future<void> _onMove(Move event, Emitter<FilesState> emit) async {
    try {
      emit(state.copyWith(loading: true, error: null));

      final conflicts = <String>[];
      final nonConflicts = <String>[];

      for (final sourcePath in event.sourcePaths) {
        final fileName = p.basename(sourcePath);
        final destination = p.join(event.destinationPath, fileName);

        final exists = await fileRepository.entityExists(destination);

        if (exists) {
          conflicts.add(sourcePath);
        } else {
          nonConflicts.add(sourcePath);
        }
      }

      // Move non-conflicting files immediately
      if (nonConflicts.isNotEmpty) {
        await fileRepository.moveEntities(
          nonConflicts,
          event.destinationPath,
          strategy: ConflictResolutionStrategy.replace,
        );
      }

      if (conflicts.isNotEmpty) {
        emit(
          state.copyWith(
            loading: false,
            conflictingPaths: conflicts,
            conflictDestinationPath: event.destinationPath,
            isMoveMode: true,
            movedPaths: conflicts,
          ),
        );
      } else {
        event.completer?.complete();
        emit(state.copyWith(loading: false, movedPaths: []));
      }
    } catch (e) {
      emit(state.copyWith(error: 'Failed to move: $e', loading: false));
    }
  }

  Future<void> _onContinueMoveWithConflictResolution(
    ContinueMoveWithConflictResolution event,
    Emitter<FilesState> emit,
  ) async {
    try {
      emit(state.copyWith(loading: true, error: null));

      final resolvedPath = event.sourcePaths.first;

      await fileRepository.moveEntities(
        [resolvedPath], // One at a time
        event.destinationPath,
        strategy: event.strategy,
      );

      final remainingConflicts = List<String>.from(state.conflictingPaths)
        ..remove(resolvedPath);
      final remainingMoved = List<String>.from(state.movedPaths)
        ..remove(resolvedPath);

      if (remainingConflicts.isNotEmpty) {
        emit(
          state.copyWith(
            conflictingPaths: remainingConflicts,
            movedPaths: remainingMoved,
            loading: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            conflictingPaths: [],
            conflictDestinationPath: '',
            isMoveMode: false,
            movedPaths: [],
            loading: false,
          ),
        );
      }
    } catch (e) {
      final remainingConflicts = List<String>.from(state.conflictingPaths);
      if (remainingConflicts.isNotEmpty) {
        remainingConflicts.remove(event.sourcePaths.first);
      }
      final remainingMoved = List<String>.from(state.movedPaths);
      if (remainingMoved.isNotEmpty) {
        remainingMoved.remove(event.sourcePaths.first);
      }
      emit(
        state.copyWith(
          error: 'Failed to move: $e',
          conflictingPaths: remainingConflicts,
          movedPaths: remainingMoved,
          isMoveMode: remainingConflicts.isNotEmpty,
          loading: false,
        ),
      );
    }
  }

  void _onStartCopyMode(StartCopyMode event, Emitter<FilesState> emit) {
    emit(
      state.copyWith(
        isCopyMode: true,
        copiedPaths: event.copiedPaths,
        isMoveMode: false,
        movedPaths: [],
      ),
    );
  }

  void _onCancelCopyMode(CancelCopyMode event, Emitter<FilesState> emit) {
    emit(state.copyWith(isCopyMode: false, copiedPaths: []));
  }

  void _onStartMoveMode(StartMoveMode event, Emitter<FilesState> emit) {
    emit(
      state.copyWith(
        isMoveMode: true,
        movedPaths: event.movedPaths,
        isCopyMode: false,
        copiedPaths: [],
      ),
    );
  }

  void _onCancelMoveMode(CancelMoveMode event, Emitter<FilesState> emit) {
    emit(state.copyWith(isMoveMode: false, movedPaths: []));
  }

  Future<void> _onSearchFilesInDirectory(
    SearchFilesInDirectory event,
    Emitter<FilesState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));

    try {
      final results = await fileRepository.searchFiles(event.path, event.query);
      emit(state.copyWith(fileSystemList: results, loading: false));
    } catch (e) {
      emit(state.copyWith(error: 'Search failed: $e', loading: false));
    }
  }

  Future<void> _onFetchFileDetails(
    FetchFileDetails event,
    Emitter<FilesState> emit,
  ) async {
    emit(state.copyWith(loading: true));

    try {
      final stat = await fileRepository.getFileDetails(event.path);
      emit(state.copyWith(fileDetails: stat, loading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }

  Future<void> _onToggleHiddenFiles(
    ToggleHiddenFiles event,
    Emitter<FilesState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    try {
      final newShowHidden = !state.showHiddenFiles;
      emit(state.copyWith(showHiddenFiles: newShowHidden, loading: true));
      await appSettingsRepository.updateShowHidden(newShowHidden);

      emit(state.copyWith(loading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }
}
