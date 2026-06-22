import 'dart:io';
import 'dart:ui';

import 'package:mechanix_files/core/theme/app_theme.dart';
import 'package:mechanix_files/features/files_home/data/models/file_item.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class RecentFilesList extends StatelessWidget {
  final List<FileSystemEntity> filesList;
  final ScrollController scrollController;
  final void Function(String fullPath) onTap;

  const RecentFilesList({
    super.key,
    required this.filesList,
    required this.scrollController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Precompute mapped items once
    final files =
        filesList.map((entity) {
          final fullPath = entity.path;
          final name = p.basename(fullPath);
          final accessed = entity.statSync().accessed;
          final fileItem = FileItem(
            name: name,
            type: p.extension(fullPath).toLowerCase(),
            children: [],
            modified: accessed,
          );

          return MapEntry(fullPath, fileItem);
        }).toList();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: ListView.builder(
        controller: scrollController,
        itemExtent: 72,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final entity = files[index];
          final fullPath = entity.key;
          final file = entity.value;

          return ListTile(
            leading: Image.asset(
              file.iconPath,
              height: 24,
              width: 24,
              color: AppColors.onSurface,
            ),

            title: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            subtitle: Text(
              fullPath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),

            onTap: () => onTap(fullPath),
          );
        },
      ),
    );
  }
}
