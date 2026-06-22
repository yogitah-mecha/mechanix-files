import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/features/files_explorer/presentation/file_explorer.dart';
import 'package:mechanix_files/features/previews/presentation/preview_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';

class ImagePreview extends StatelessWidget {
  final String imagePath;
  final FileExplorerPageState? state;

  const ImagePreview({super.key, required this.imagePath, this.state});
  bool get isSvg => imagePath.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// APP BAR
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(imagePath.split('/').last),
      ),

      /// IMAGE VIEWER
      body:
          isSvg
              ? _SvgViewer(imagePath: imagePath)
              : _RasterViewer(imagePath: imagePath),

      /// BOTTOM BAR
      bottomNavigationBar: PreviewActionBar(
        path: imagePath,
        state: state,
        rootContext: context,
      ),
    );
  }
}

class _RasterViewer extends StatelessWidget {
  final String imagePath;

  const _RasterViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final file = AppFileSystem.instance.file(imagePath);
    if (!file.existsSync() || file.lengthSync() == 0) {
      return Center(
        child: Text(
          'Image file is empty',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
    }
    final bytes = file.readAsBytesSync();
    return Center(
      child: PhotoView(
        imageProvider: MemoryImage(bytes),
        backgroundDecoration: const BoxDecoration(color: AppColors.surface),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }
}

class _SvgViewer extends StatelessWidget {
  final String imagePath;

  const _SvgViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final file = AppFileSystem.instance.file(imagePath);
    if (!file.existsSync() || file.lengthSync() == 0) {
      return Center(
        child: Text(
          'Image file is empty',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
    }
    final bytes = file.readAsBytesSync();
    return Center(
      child: PhotoView.customChild(
        backgroundDecoration: const BoxDecoration(color: AppColors.surface),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        child: SvgPicture.memory(
          bytes,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
