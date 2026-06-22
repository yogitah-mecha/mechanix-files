import 'package:mechanix_files/core/constants/app_limits.dart';
import 'package:mechanix_files/core/utils/app_logger.dart';
import 'package:mechanix_files/features/files_explorer/services/hive_service.dart';
import 'package:mechanix_files/features/recents/data/models/recent_files.dart';
import 'package:hive/hive.dart';
import 'recent_files_repository.dart';

class RecentFilesRepositoryImpl extends RecentFilesRepository {
  Box<RecentFile> get box => Hive.box<RecentFile>(recentFilesTable);

  Future<void> ensureHiveConnected() async {
    try {
      if (!Hive.isBoxOpen(recentFilesTable)) {
        await HiveService.initializeHive();
        await Hive.openBox<RecentFile>(recentFilesTable);
      }
    } catch (e) {
      AppLogger.e('Failed to open Hive box: $e');
    }
  }

  Box<RecentFile> _box() => Hive.box<RecentFile>(recentFilesTable);

  @override
  Future<List<RecentFile>> getRecentFiles() async {
    await ensureHiveConnected();

    return _box().values.toList()
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
  }

  @override
  Future<void> addRecentFile(String path) async {
    await ensureHiveConnected();

    dynamic existingKey;

    for (final key in _box().keys) {
      final item = _box().get(key);
      if (item?.path == path) {
        existingKey = key;
        break;
      }
    }

    if (existingKey != null) {
      await _box().delete(existingKey);
    }

    await _box().add(RecentFile(path: path, openedAt: DateTime.now()));

    final limit = AppLimits.recentFilesCount;

    final items =
        _box().values.toList()
          ..sort((a, b) => b.openedAt.compareTo(a.openedAt));

    if (items.length > limit) {
      for (final extra in items.sublist(limit)) {
        final key = _box().keys.firstWhere((k) => _box().get(k) == extra);
        await _box().delete(key);
      }
    }
  }
}
