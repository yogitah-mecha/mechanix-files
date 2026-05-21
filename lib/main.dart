import 'dart:io';

import 'package:files/core/constants/app_routes.dart';
import 'package:files/core/theme/app_theme.dart';
import 'package:files/features/files_explorer/blocs/file_boc.dart';
import 'package:files/features/files_explorer/blocs/file_event.dart';
import 'package:files/features/files_explorer/data/repositories/app_settings_repository.dart';
import 'package:files/features/files_explorer/data/repositories/app_settings_repository_impl.dart';
import 'package:files/features/files_explorer/data/repositories/file_repository.dart';
import 'package:files/features/files_explorer/data/repositories/file_repository_impl.dart';
import 'package:files/features/files_explorer/services/hive_service.dart';
import 'package:files/features/files_home/presentation/files_home.dart';
import 'package:files/features/recents/blocs/recent_file_event.dart';
import 'package:files/features/recents/blocs/recent_files_bloc.dart';
import 'package:files/features/recents/data/repositories/recent_files_repository.dart';
import 'package:files/features/recents/data/repositories/recent_files_repository_impl.dart';
import 'package:files/features/trash/bloc/trash_bloc.dart';
import 'package:files/features/trash/data/repositories/trash_repository.dart';
import 'package:files/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:files/features/trash/services/trash_path_service.dart';
import 'package:files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  final openPath = _parseOpenPath();
  await HiveService.init();
  await TrashPathsService.init();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FileRepository>(create: (_) => FileRepositoryImpl()),

        RepositoryProvider<RecentFilesRepository>(
          create: (_) => RecentFilesRepositoryImpl(),
        ),

        RepositoryProvider<AppSettingsRepository>(
          create: (_) => AppSettingsRepositoryImpl(),
        ),

        RepositoryProvider<TrashRepository>(
          create: (_) => TrashRepositoryImpl(),
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

        child: MainApp(openPath: openPath),
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.openPath});
  final String openPath;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
