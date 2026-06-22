import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/features/files_explorer/presentation/commons.dart';
import 'package:mechanix_files/features/recents/blocs/recent_file_event.dart';
import 'package:mechanix_files/features/recents/blocs/recent_file_state.dart';
import 'package:mechanix_files/features/recents/blocs/recent_files_bloc.dart';
import 'package:mechanix_files/features/recents/presentation/list_view.dart';
import 'package:mechanix_files/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecentFilesExplorerPage extends StatefulWidget {
  const RecentFilesExplorerPage({super.key});

  @override
  State<RecentFilesExplorerPage> createState() =>
      RecentFilesExplorerPageState();
}

class RecentFilesExplorerPageState extends State<RecentFilesExplorerPage> {
  final ScrollController _scrollController = ScrollController();
  bool isGrid = false;

  @override
  void initState() {
    super.initState();
    context.read<RecentFilesBloc>().add(LoadRecentFiles());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppLocalizations.of(context)!.recent),
      ),

      body: BlocBuilder<RecentFilesBloc, RecentFileState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final files = state.fileSystemList;

          if (files.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.emptyRecentFolderMessage,
              ),
            );
          }

          return RecentFilesList(
            filesList: files,
            scrollController: _scrollController,
            onTap: (fullPath) {
              handleTap(context, fullPath, this);
            },
          );
        },
      ),

      bottomNavigationBar: BottomBar(
        key: const ValueKey('bottom_bar'),
        leading: CustomIconButton.asset(
          assetPath: FileIcons.back,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
