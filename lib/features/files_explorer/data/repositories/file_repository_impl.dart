import 'dart:async';
import 'package:file/file.dart';
import 'package:mechanix_files/core/constants/app_constants.dart';
import 'package:mechanix_files/core/utils/app_file_system.dart';
import 'package:mechanix_files/core/utils/app_logger.dart';
import 'package:mechanix_files/features/files_explorer/data/models/conflict_resolution_strategy.dart';
import 'package:mechanix_files/features/files_explorer/data/repositories/file_repository.dart';
import 'package:path/path.dart' as p;

class FileRepositoryImpl implements FileRepository {
  final FileSystem _fs;

  FileRepositoryImpl({FileSystem? fs}) : _fs = fs ?? AppFileSystem.instance;

  @override
  Future<List<FileSystemEntity>> getPaginatedFileSystemList({
    String path = '/',
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final Directory dir = _fs.directory(path);

      if (!dir.existsSync()) {
        return [];
      }

      final int start = (page - 1) * pageSize;

      // Use skip/take directly on the stream for pagination
      final items =
          await dir
              .list(recursive: false, followLinks: false)
              .skip(start)
              .take(pageSize)
              .toList();

      return items;
    } catch (e, stackTrace) {
      AppLogger.e("Failed to list file system at $path: $e, $stackTrace");
      return [];
    }
  }

  @override
  Future<void> createFolder(String path, String folderName) async {
    final dir = _fs.directory(path).childDirectory(folderName);
    if (!dir.existsSync()) {
      dir.createSync();
    }
  }

  @override
  Future<void> renameEntity(String oldPath, String newName) async {
    final newPath = p.join(p.dirname(oldPath), newName);
    final type = _fs.typeSync(oldPath);

    if (type == FileSystemEntityType.directory) {
      await _fs.directory(oldPath).rename(newPath);
    } else {
      await _fs.file(oldPath).rename(newPath);
    }
  }

  @override
  Future<void> copyEntities(
    List<String> sourcePaths,
    String destinationPath, {
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.replace,
  }) async {
    for (final srcPath in sourcePaths) {
      final name = p.basename(srcPath);
      final destPath = p.join(destinationPath, name);

      // Skip if the source and destination paths are the same.
      // This can happen when the user attempts to copy an item
      // into the directory where it already exists.
      if (p.normalize(srcPath) == p.normalize(destPath)) {
        continue;
      }

      final type = _fs.file(srcPath).statSync().type;

      final exists =
          await _fs.file(destPath).exists() ||
          await _fs.directory(destPath).exists();

      if (exists) {
        if (strategy == ConflictResolutionStrategy.skip) {
          continue; // Skip copying this one
        } else if (strategy == ConflictResolutionStrategy.replace) {
          // Delete existing before overwriting
          await _fs.directory(destPath).exists()
              ? await _fs.directory(destPath).delete(recursive: true)
              : await _fs.file(destPath).delete();
        }
      }

      if (type == FileSystemEntityType.file) {
        await _fs.file(srcPath).copy(destPath);
      } else if (type == FileSystemEntityType.directory) {
        await _copyDirectory(_fs.directory(srcPath), _fs.directory(destPath));
      } else {
        AppLogger.e('Unknown or unsupported entity: $srcPath');
      }
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }

    await for (var entity in source.list(recursive: false)) {
      final newPath = p.join(destination.path, p.basename(entity.path));

      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, _fs.directory(newPath));
      }
    }
  }

  @override
  Future<void> moveEntities(
    List<String> sourcePaths,
    String destinationPath, {
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.replace,
  }) async {
    for (final path in sourcePaths) {
      final name = p.basename(path);
      final newPath = p.join(destinationPath, name);

      // Skip if the source and destination paths are the same.
      // Moving an item onto itself is a no-op and would otherwise
      // result in an invalid move operation.
      if (p.normalize(path) == p.normalize(newPath)) {
        continue;
      }

      final isFile = await _fs.file(path).exists();
      final entity = isFile ? _fs.file(path) : _fs.directory(path);

      final destFile = _fs.file(newPath);
      final destDir = _fs.directory(newPath);

      final destExists = await destFile.exists() || await destDir.exists();

      if (destExists) {
        switch (strategy) {
          case ConflictResolutionStrategy.skip:
            continue;
          case ConflictResolutionStrategy.replace:
            if (await destDir.exists()) {
              await destDir.delete(recursive: true);
            } else if (await destFile.exists()) {
              await destFile.delete();
            }
            break;
        }
      }

      await entity.rename(newPath);
    }
  }

  @override
  Future<FileStat> getFileDetails(String path) async {
    final entity =
        _fs.file(path).existsSync() ? _fs.file(path) : _fs.directory(path);
    return entity.statSync();
  }

  @override
  Future<bool> entityExists(String path) async {
    final fileExists = await _fs.file(path).exists();
    if (fileExists) return true;

    final dirExists = await _fs.directory(path).exists();
    return dirExists;
  }

  /// Recursively searches for files and directories matching a query string,
  /// starting from a given root path, up to a limited depth.
  ///
  /// This method performs a **breadth-first search (BFS)** using a queue to avoid
  /// deep recursion. It only searches up to [maxDepth] levels below [rootPath].
  ///
  /// - [rootPath]: The directory path to start searching from.
  /// - [query]: The search term (case-insensitive).
  ///
  /// Returns a [List] of [FileSystemEntity] objects (files or directories)
  /// whose names contain the query string.
  @override
  Future<List<FileSystemEntity>> searchFiles(
    String rootPath,
    String query,
  ) async {
    final dir = _fs.directory(rootPath);
    final q = query.toLowerCase();
    final results = <FileSystemEntity>[];

    if (!await dir.exists()) return results;

    final queue = <MapEntry<Directory, int>>[MapEntry(dir, 0)];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentDir = current.key;
      final depth = current.value;

      if (depth > AppConstants.searchMaxDepth) continue;

      try {
        await for (final entity in currentDir.list(followLinks: false)) {
          final name = p.basename(entity.path);

          if (name.startsWith('.')) continue;

          if (name.toLowerCase().contains(q)) {
            results.add(entity);
          }

          if (entity is Directory) {
            queue.add(MapEntry(entity, depth + 1));
          }
        }
      } catch (e, st) {
        AppLogger.e("Error while listing ${currentDir.path}: $e\n$st");
      }
    }
    return results;
  }
}
