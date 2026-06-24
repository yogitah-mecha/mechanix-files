import 'dart:io';

import 'package:mechanix_files/core/constants/app_routes.dart';
import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_boc.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_event.dart';
import 'package:mechanix_files/features/files_explorer/data/models/app_settings.dart';
import 'package:mechanix_files/features/files_explorer/data/repositories/app_settings_repository.dart';
import 'package:mechanix_files/features/files_explorer/data/repositories/app_settings_repository_impl.dart';
import 'package:mechanix_files/features/files_explorer/data/repositories/file_repository.dart';
import 'package:mechanix_files/features/files_explorer/data/repositories/file_repository_impl.dart';
import 'package:mechanix_files/features/files_home/presentation/files_home.dart';
import 'package:mechanix_files/features/recents/blocs/recent_file_event.dart';
import 'package:mechanix_files/features/recents/blocs/recent_files_bloc.dart';
import 'package:mechanix_files/features/recents/data/models/recent_files.dart';
import 'package:mechanix_files/features/recents/data/repositories/recent_files_repository.dart';
import 'package:mechanix_files/features/recents/data/repositories/recent_files_repository_impl.dart';
import 'package:mechanix_files/features/trash/bloc/trash_bloc.dart';
import 'package:mechanix_files/features/trash/data/repositories/trash_repository.dart';
import 'package:mechanix_files/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:show_fps/show_fps.dart';

void main() {
  final openPath = _parseOpenPath();
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(RecentFileAdapter());

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FileRepository>(
          create: (_) => FileRepositoryImpl(fs: AppFileSystem.instance),
        ),

        RepositoryProvider<RecentFilesRepository>(
          create: (_) => RecentFilesRepositoryImpl(),
        ),

        RepositoryProvider<AppSettingsRepository>(
          create: (_) => AppSettingsRepositoryImpl(),
        ),

        RepositoryProvider<TrashRepository>(
          create: (_) => TrashRepositoryImpl(fs: AppFileSystem.instance),
        ),
      ],

      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) => FilesBloc(
                  fileRepository: context.read<FileRepository>(),
                  appSettingsRepository: context.read<AppSettingsRepository>(),
                )..add(InitializeFiles()),
          ),
          BlocProvider(
            create:
                (context) => RecentFilesBloc(
                  recentFilesRepository: context.read<RecentFilesRepository>(),
                  appSettingsRepository: context.read<AppSettingsRepository>(),
                )..add(LoadRecentFiles()),
          ),
          BlocProvider(
            create:
                (context) =>
                    TrashBloc(trashRepository: context.read<TrashRepository>()),
          ),
        ],

        child: FilesApp(openPath: openPath),
      ),
    ),
  );
}

class FilesApp extends StatelessWidget {
  const FilesApp({super.key, required this.openPath});
  final String openPath;

  @override
  Widget build(BuildContext context) {
    final showFps = Platform.environment['SHOW_FPS'] == 'true';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder:
          showFps
              ? (context, child) {
                return ShowFPS(
                  visible: showFps,
                  showChart: false,
                  child: child!,
                );
              }
              : null,
      theme: AppTheme.darkTheme,
      home: buildFileExplorerPage(context, openPath),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        AppRoutes.files: (context) => buildFileExplorerPage(context, openPath),
      },
    );
  }

  Widget buildFileExplorerPage(BuildContext context, String openPath) {
    return FileHomePage(
      path: openPath.isNotEmpty ? pathToSegments(openPath) : const [],
    );
  }
}

String _parseOpenPath() {
  const compileTimeOpenPath = String.fromEnvironment(
    'MECHANIX_FILES_OPEN_PATH',
  );
  final runtimeOpenPath = Platform.environment['MECHANIX_FILES_OPEN_PATH'];
  return compileTimeOpenPath.isNotEmpty
      ? compileTimeOpenPath
      : (runtimeOpenPath ?? '');
}
