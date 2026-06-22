import 'dart:async';

import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/core/constants/icons.dart';
import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_files/core/widgets/custom_icon_button.dart';
import 'package:mechanix_files/core/widgets/toast/custom_app_toast.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_boc.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_state.dart';
import 'package:mechanix_files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:mechanix_files/features/files_explorer/presentation/breadcrumbs.dart';
import 'package:mechanix_files/features/trash/presentation/list_view.dart';
import 'package:mechanix_files/features/trash/services/trash_path_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => TrashPageState();
}

class TrashPageState extends State<TrashPage> {
  final FileManagerController controller = FileManagerController();
  final ValueNotifier<String?> infoPathNotifier = ValueNotifier(null);
  final ScrollController scrollController = ScrollController();

  String currentPath = '';

  @override
  void initState() {
    super.initState();

    _init();
    _setupListeners();
  }

  Future<void> _init() async {
    await TrashPathsService.init(AppFileSystem.instance);

    currentPath = TrashPathsService.trashFilesDir.path;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrashDirectory();
    });
  }

  Future<void> _loadTrashDirectory() async {
    await controller.openDirectory(
      AppFileSystem.instance.directory(TrashPathsService.trashFilesDir.path),
    );

    if (!mounted) return;

    setState(() {});
  }

  void _setupListeners() {
    controller.getPathNotifier.addListener(_onPathChanged);
    scrollController.addListener(_onScroll);
  }

  void _onPathChanged() {
    if (!mounted) return;

    setState(() {
      currentPath = controller.getPathNotifier.value;
    });
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;

    if (position.pixels >= position.maxScrollExtent * 0.8) {
      controller.loadNextChunk();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    infoPathNotifier.dispose();
    super.dispose();
  }

  Future<void> handleBack() async {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FilesBloc, FilesState>(
          listenWhen:
              (previous, current) =>
                  previous.error != current.error && current.error != null,
          listener: (context, state) {
            CustomAppToast.show(
              context: context,
              message: state.error ?? '',
              type: ToastType.error,
            );
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: ExplorerBreadcrumbs(
            isCopyMode: false,
            isMoveMode: false,
            copiedItemCount: 0,
            movedItemCount: 0,
            parentContext: context,
            currentPath: currentPath,
            controller: controller,
            scrollController: ScrollController(),
            selectionCount: 0,
            isSelectionMode: false,
            isSearching: false,
            searchCount: 0,
          ),
        ),

        body: Column(
          children: [
            const Divider(height: 1, color: AppColors.backgroundVariant),

            Expanded(
              child: TrashListSection(
                controller: controller,
                scrollController: scrollController,
              ),
            ),
          ],
        ),

        bottomNavigationBar: BottomBar(
          leading: CustomIconButton.asset(
            assetPath: FileIcons.back,
            onPressed: handleBack,
          ),
        ),
      ),
    );
  }
}
