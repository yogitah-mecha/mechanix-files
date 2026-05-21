import 'dart:io';

import 'package:files/core/constants/hive_tables.dart';
import 'package:files/core/constants/app_limits.dart';
import 'package:files/features/recents/data/models/recent_files.dart';
import 'package:files/features/recents/data/repositories/recent_files_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late RecentFilesRepositoryImpl repo;
  late Directory tempDir;

  setUpAll(() {
    // register real adapter once
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(RecentFileAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');

    Hive.init(tempDir.path);

    await Hive.openBox<RecentFile>(HiveTables.recentFilesTable);

    repo = RecentFilesRepositoryImpl();
  });

  tearDown(() async {
    await Hive.box<RecentFile>(HiveTables.recentFilesTable).clear();
    await Hive.deleteFromDisk();
  });

  group('RecentFilesRepositoryImpl', () {
    test('returns recent files sorted by openedAt desc', () async {
      final box = Hive.box<RecentFile>(HiveTables.recentFilesTable);

      final now = DateTime.now();

      await box.add(
        RecentFile(
          path: '/a.txt',
          openedAt: now.subtract(const Duration(minutes: 1)),
        ),
      );

      await box.add(RecentFile(path: '/b.txt', openedAt: now));

      final result = await repo.getRecentFiles();

      expect(result.first.path, '/b.txt');
      expect(result.last.path, '/a.txt');
    });

    test('adds new recent file', () async {
      await repo.addRecentFile('/new.txt');

      final box = Hive.box<RecentFile>(HiveTables.recentFilesTable);

      final exists = box.values.any((e) => e.path == '/new.txt');

      expect(exists, true);
    });

    test('replaces existing recent file entry', () async {
      final box = Hive.box<RecentFile>(HiveTables.recentFilesTable);

      await box.add(RecentFile(path: '/dup.txt', openedAt: DateTime.now()));

      await repo.addRecentFile('/dup.txt');

      final items = box.values.where((e) => e.path == '/dup.txt');

      expect(items.length, 1);
    });

    test('enforces recent files limit', () async {
      final box = Hive.box<RecentFile>(HiveTables.recentFilesTable);

      for (int i = 0; i < AppLimits.recentFilesCount + 3; i++) {
        await repo.addRecentFile('/file$i.txt');
      }

      expect(box.length <= AppLimits.recentFilesCount, true);
    });

    test('keeps most recent at top after multiple inserts', () async {
      await repo.addRecentFile('/a.txt');
      await Future.delayed(const Duration(milliseconds: 10));
      await repo.addRecentFile('/b.txt');

      final result = await repo.getRecentFiles();

      expect(result.first.path, '/b.txt');
    });

    test('does not keep duplicates after repeated add', () async {
      await repo.addRecentFile('/same.txt');
      await repo.addRecentFile('/same.txt');

      final box = Hive.box<RecentFile>(HiveTables.recentFilesTable);

      final count = box.values.where((e) => e.path == '/same.txt').length;

      expect(count, 1);
    });
  });
}
