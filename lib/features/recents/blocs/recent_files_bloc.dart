import 'dart:async';

import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/features/files_explorer/data/repositories/app_settings_repository.dart';
import 'package:mechanix_files/features/recents/blocs/recent_file_state.dart';
import 'package:mechanix_files/features/recents/data/repositories/recent_files_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'recent_file_event.dart';

class RecentFilesBloc extends Bloc<RecentFilesEvent, RecentFileState> {
  final RecentFilesRepository recentFilesRepository;
  final AppSettingsRepository appSettingsRepository;

  RecentFilesBloc({
    required this.recentFilesRepository,
    required this.appSettingsRepository,
  }) : super(
         const RecentFileState(fileSystemList: [], loading: false, error: null),
       ) {
    on<LoadRecentFiles>(_onLoadRecentFiles);
    on<AddToRecentFiles>(_onAddToRecentFiles);
  }

  Future<void> _onLoadRecentFiles(
    LoadRecentFiles event,
    Emitter<RecentFileState> emit,
  ) async {
    try {
      final fileSystem = AppFileSystem.instance;
      final recentFiles = await recentFilesRepository.getRecentFiles();

      final visibleFiles =
          recentFiles
              .where((recent) => fileSystem.file(recent.path).existsSync())
              .map((recent) => fileSystem.file(recent.path))
              .toList();

      emit(state.copyWith(loading: false, fileSystemList: visibleFiles));
    } catch (e) {
      emit(state.copyWith(loading: false));
    }
  }

  Future<void> _onAddToRecentFiles(
    AddToRecentFiles event,
    Emitter<RecentFileState> emit,
  ) async {
    await recentFilesRepository.addRecentFile(event.path);
  }
}
