import 'package:flutter_test/flutter_test.dart';
import 'package:files/features/recents/data/models/recent_files.dart';

void main() {
  group('RecentFile model', () {
    test('creates object correctly', () {
      final time = DateTime(2025, 1, 1);

      final file = RecentFile(path: '/storage/file.txt', openedAt: time);

      expect(file.path, '/storage/file.txt');
      expect(file.openedAt, time);
    });

    test('copyWith updates path only', () {
      final time = DateTime(2025, 1, 1);

      final file = RecentFile(path: '/old/path.txt', openedAt: time);

      final updated = file.copyWith(path: '/new/path.txt');

      expect(updated.path, '/new/path.txt');
      expect(updated.openedAt, time);
    });

    test('copyWith updates openedAt only', () {
      final file = RecentFile(
        path: '/storage/file.txt',
        openedAt: DateTime(2025, 1, 1),
      );

      final newTime = DateTime(2026, 1, 1);

      final updated = file.copyWith(openedAt: newTime);

      expect(updated.path, '/storage/file.txt');
      expect(updated.openedAt, newTime);
    });

    test('copyWith updates both fields', () {
      final file = RecentFile(path: '/old.txt', openedAt: DateTime(2025, 1, 1));

      final updated = file.copyWith(
        path: '/new.txt',
        openedAt: DateTime(2026, 1, 1),
      );

      expect(updated.path, '/new.txt');
      expect(updated.openedAt, DateTime(2026, 1, 1));
    });

    test('toString returns expected format', () {
      final file = RecentFile(
        path: '/storage/file.txt',
        openedAt: DateTime(2025, 1, 1),
      );

      expect(file.toString(), contains('RecentFile(path: /storage/file.txt'));
    });
  });
}
