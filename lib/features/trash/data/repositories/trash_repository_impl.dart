import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/features/trash/services/trash_path_service.dart';
import 'package:mechanix_files/features/trash/data/repositories/trash_repository.dart';

class TrashRepositoryImpl implements TrashRepository {
  final FileSystem _fs;

  TrashRepositoryImpl({FileSystem? fs}) : _fs = fs ?? AppFileSystem.instance;

  Future<void> _ensureTrashInitialized() async {
    await TrashPathsService.init(_fs);
  }

  @override
  Future<void> moveToTrash(List<String> paths) async {
    await _ensureTrashInitialized();

    if (_fs is! LocalFileSystem) {
      for (final path in paths) {
        final isDir = _fs.directory(path).existsSync();
        final isLink = _fs.link(path).existsSync();
        final entity =
            isLink
                ? _fs.link(path)
                : (isDir ? _fs.directory(path) : _fs.file(path));
        if (entity.existsSync()) {
          final targetPath =
              '${TrashPathsService.trashFilesDir.path}/${_fs.path.basename(path)}';
          entity.renameSync(targetPath);
        }
      }
      return;
    }

    final result = await Process.run('gio', ['trash', ...paths]);

    if (result.exitCode != 0) {
      for (final path in paths) {
        await Process.run('gio', ['trash', path]);
      }
    }
  }

  @override
  Future<List<FileSystemEntity>> getTrashItems() async {
    await _ensureTrashInitialized();

    final entities =
        _fs.directory(TrashPathsService.trashFilesDir.path).listSync().toList();

    entities.sort((a, b) {
      final aStat = a.statSync();
      final bStat = b.statSync();

      return bStat.modified.compareTo(aStat.modified);
    });

    return entities;
  }
}
