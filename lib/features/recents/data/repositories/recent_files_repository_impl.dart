import 'package:files/core/constants/app_limits.dart';
import 'package:files/core/constants/hive_tables.dart';
import 'package:files/features/recents/data/models/recent_files.dart';
import 'package:hive/hive.dart';
import 'recent_files_repository.dart';

class RecentFilesRepositoryImpl extends RecentFilesRepository {
  Future<void> ensureRecentFilesConnected() async {
    if (!Hive.isBoxOpen(HiveTables.recentFilesTable)) {
      await Hive.openBox<RecentFile>(HiveTables.recentFilesTable);
    }
  }

  Box<RecentFile> _box() => Hive.box<RecentFile>(HiveTables.recentFilesTable);

  @override
  Future<List<RecentFile>> getRecentFiles() async {
    await ensureRecentFilesConnected();

    return _box().values.toList()
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
  }

  @override
  Future<void> addRecentFile(String path) async {
    await ensureRecentFilesConnected();

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
