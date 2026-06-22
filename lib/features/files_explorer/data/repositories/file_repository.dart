import 'package:file/file.dart';
import 'package:mechanix_files/features/files_explorer/data/models/conflict_resolution_strategy.dart';

abstract class FileRepository {
  Future<void> createFolder(String path, String folderName);

  Future<void> renameEntity(String oldPath, String newName);

  Future<void> copyEntities(
    List<String> sourcePaths,
    String destinationPath, {
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.replace,
  });

  Future<void> moveEntities(
    List<String> sourcePaths,
    String destinationPath, {
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.replace,
  });

  Future<FileStat> getFileDetails(String path);

  Future<bool> entityExists(String path);

  Future<List<FileSystemEntity>> searchFiles(String rootPath, String query);

  Future<List<FileSystemEntity>> getPaginatedFileSystemList({
    String path,
    int page,
    int pageSize,
  });
}
