import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:mechanix_files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:mechanix_files/features/files_explorer/data/models/conflict_resolution_strategy.dart';

abstract class FilesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitializeFiles extends FilesEvent {}

class CreateFolder extends FilesEvent {
  final String path;
  final String folderName;
  final FileManagerController controller;

  CreateFolder({
    required this.path,
    required this.folderName,
    required this.controller,
  });
}

class Rename extends FilesEvent {
  final String oldPath;
  final String newName;
  final FileManagerController controller;

  Rename({
    required this.oldPath,
    required this.newName,
    required this.controller,
  });
}

class Copy extends FilesEvent {
  final List<String> sourcePaths;
  final String destinationPath;
  final FileManagerController? controller;
  final Completer<void>? completer;

  Copy({
    required this.sourcePaths,
    required this.destinationPath,
    required this.controller,
    this.completer,
  });
}

class ContinueCopyWithConflictResolution extends FilesEvent {
  final List<String> sourcePaths;
  final String destinationPath;
  final ConflictResolutionStrategy strategy;
  final FileManagerController? controller;

  ContinueCopyWithConflictResolution({
    required this.sourcePaths,
    required this.destinationPath,
    required this.strategy,
    required this.controller,
  });
}

class StartCopyMode extends FilesEvent {
  final List<String> copiedPaths;
  StartCopyMode(this.copiedPaths);
}

class CancelCopyMode extends FilesEvent {}

class Move extends FilesEvent {
  final List<String> sourcePaths;
  final String destinationPath;
  final Completer<void>? completer;

  Move({
    required this.sourcePaths,
    required this.destinationPath,
    this.completer,
  });
}

class ContinueMoveWithConflictResolution extends FilesEvent {
  final List<String> sourcePaths;
  final String destinationPath;
  final ConflictResolutionStrategy strategy;

  ContinueMoveWithConflictResolution({
    required this.sourcePaths,
    required this.destinationPath,
    required this.strategy,
  });
}

class StartMoveMode extends FilesEvent {
  final List<String> movedPaths;
  StartMoveMode(this.movedPaths);
}

class CancelMoveMode extends FilesEvent {}

class FetchFileDetails extends FilesEvent {
  final String path;

  FetchFileDetails(this.path);
}

class ToggleHiddenFiles extends FilesEvent {
  ToggleHiddenFiles();
}

class CancelExtractMode extends FilesEvent {}

class SearchFilesInDirectory extends FilesEvent {
  final String path;
  final String query;

  SearchFilesInDirectory(this.path, this.query);
}

class ClearSearchResults extends FilesEvent {}
