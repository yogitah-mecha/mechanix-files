import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:files/features/files_explorer/blocs/file_event.dart';
import 'package:files/features/files_explorer/data/repositories/file_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late MemoryFileSystem fs;
  late FileRepositoryImpl repo;

  setUp(() {
    fs = MemoryFileSystem();
    repo = FileRepositoryImpl(fs: fs);
  });

  group('FileRepositoryImpl', () {
    test('createFolder creates directory', () async {
      fs.directory('/root').createSync(recursive: true);

      await repo.createFolder('/root', 'test');

      expect(fs.directory('/root/test').existsSync(), true);
    });

    test('getPaginatedFileSystemList returns paginated items', () async {
      for (int i = 0; i < 10; i++) {
        fs.file('/root/file$i.txt').createSync(recursive: true);
      }

      final result = await repo.getPaginatedFileSystemList(
        path: '/root',
        page: 1,
        pageSize: 5,
      );

      expect(result.length, 5);
    });

    test('renameEntity renames file', () async {
      final file = fs.file('/root/file.txt')..createSync(recursive: true);

      await repo.renameEntity(file.path, 'renamed.txt');

      expect(fs.file('/root/renamed.txt').existsSync(), true);
    });

    test('renameEntity renames directory', () async {
      fs.directory('/root/test').createSync(recursive: true);

      await repo.renameEntity('/root/test', 'renamed');

      expect(fs.directory('/root/renamed').existsSync(), true);
    });

    test('copyEntities copies file', () async {
      fs.directory('/dest').createSync(recursive: true);

      final file =
          fs.file('/src/file.txt')
            ..createSync(recursive: true)
            ..writeAsStringSync('hello');

      await repo.copyEntities([file.path], '/dest');

      expect(fs.file('/dest/file.txt').existsSync(), true);
      expect(fs.file('/dest/file.txt').readAsStringSync(), 'hello');
    });

    test('copyEntities copies directory recursively', () async {
      fs.file('/src/folder/file.txt').createSync(recursive: true);

      fs.directory('/dest').createSync(recursive: true);

      await repo.copyEntities(['/src/folder'], '/dest');

      expect(fs.file('/dest/folder/file.txt').existsSync(), true);
    });

    test('copyEntities skips existing file when strategy is skip', () async {
      fs.directory('/dest').createSync(recursive: true);

      fs.file('/src/file.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('source');

      fs.file('/dest/file.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('destination');

      await repo.copyEntities(
        ['/src/file.txt'],
        '/dest',
        strategy: ConflictResolutionStrategy.skip,
      );

      expect(fs.file('/dest/file.txt').readAsStringSync(), 'destination');
    });

    test('moveEntities moves file', () async {
      final file =
          fs.file('/src/file.txt')
            ..createSync(recursive: true)
            ..writeAsStringSync('hello');

      fs.directory('/dest').createSync(recursive: true);

      await repo.moveEntities([file.path], '/dest');

      expect(fs.file('/dest/file.txt').existsSync(), true);
      expect(fs.file('/src/file.txt').existsSync(), false);
    });

    test('moveEntities skips existing file when strategy is skip', () async {
      fs.file('/src/file.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('source');

      fs.file('/dest/file.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('destination');

      await repo.moveEntities(
        ['/src/file.txt'],
        '/dest',
        strategy: ConflictResolutionStrategy.skip,
      );

      expect(fs.file('/src/file.txt').existsSync(), true);

      expect(fs.file('/dest/file.txt').readAsStringSync(), 'destination');
    });

    test('getFileDetails returns file stat', () async {
      final file = fs.file('/root/file.txt')..createSync(recursive: true);

      final stat = await repo.getFileDetails(file.path);

      expect(stat.type, FileSystemEntityType.file);
    });

    test('entityExists returns true for existing file', () async {
      fs.file('/file.txt').createSync();

      final exists = await repo.entityExists('/file.txt');

      expect(exists, true);
    });

    test('entityExists returns false for missing entity', () async {
      final exists = await repo.entityExists('/missing.txt');

      expect(exists, false);
    });

    test('searchFiles finds matching files', () async {
      fs.file('/root/test1.txt').createSync(recursive: true);
      fs.file('/root/demo.txt').createSync(recursive: true);

      final result = await repo.searchFiles('/root', 'test');

      expect(result.length, 1);
      expect(p.basename(result.first.path), 'test1.txt');
    });

    test('searchFiles ignores hidden files', () async {
      fs.file('/root/.hidden.txt').createSync(recursive: true);

      final result = await repo.searchFiles('/root', 'hidden');

      expect(result, isEmpty);
    });

    test('searchFiles respects max depth', () async {
      fs.file('/root/a/b/c/deep.txt').createSync(recursive: true);

      final result = await repo.searchFiles('/root', 'deep');

      expect(result, isEmpty);
    });

    test('searchFiles returns empty for invalid root', () async {
      final result = await repo.searchFiles('/invalid', 'test');

      expect(result, isEmpty);
    });

    test(
      'getPaginatedFileSystemList returns empty when directory does not exist',
      () async {
        final result = await repo.getPaginatedFileSystemList(path: '/invalid');

        expect(result, isEmpty);
      },
    );

    test(
      'copyEntities replaces existing file when strategy is replace',
      () async {
        fs.directory('/dest').createSync(recursive: true);

        fs.file('/src/file.txt')
          ..createSync(recursive: true)
          ..writeAsStringSync('new content');

        fs.file('/dest/file.txt')
          ..createSync(recursive: true)
          ..writeAsStringSync('old content');

        await repo.copyEntities(
          ['/src/file.txt'],
          '/dest',
          strategy: ConflictResolutionStrategy.replace,
        );

        expect(fs.file('/dest/file.txt').readAsStringSync(), 'new content');
      },
    );

    test(
      'copyEntities replaces existing directory when strategy is replace',
      () async {
        fs.file('/src/folder/new.txt').createSync(recursive: true);

        fs.file('/dest/folder/old.txt').createSync(recursive: true);

        await repo.copyEntities(
          ['/src/folder'],
          '/dest',
          strategy: ConflictResolutionStrategy.replace,
        );

        expect(fs.file('/dest/folder/new.txt').existsSync(), true);
        expect(fs.file('/dest/folder/old.txt').existsSync(), false);
      },
    );

    test('copyEntities handles nested directories recursively', () async {
      fs.file('/src/a/b/c/file.txt').createSync(recursive: true);

      fs.directory('/dest').createSync(recursive: true);

      await repo.copyEntities(['/src/a'], '/dest');

      expect(fs.file('/dest/a/b/c/file.txt').existsSync(), true);
    });

    test(
      'moveEntities replaces existing file when strategy is replace',
      () async {
        fs.file('/src/file.txt')
          ..createSync(recursive: true)
          ..writeAsStringSync('source');

        fs.file('/dest/file.txt')
          ..createSync(recursive: true)
          ..writeAsStringSync('destination');

        await repo.moveEntities(
          ['/src/file.txt'],
          '/dest',
          strategy: ConflictResolutionStrategy.replace,
        );

        expect(fs.file('/dest/file.txt').readAsStringSync(), 'source');
        expect(fs.file('/src/file.txt').existsSync(), false);
      },
    );

    test(
      'moveEntities replaces existing directory when strategy is replace',
      () async {
        fs.file('/src/folder/new.txt').createSync(recursive: true);

        fs.file('/dest/folder/old.txt').createSync(recursive: true);

        await repo.moveEntities(
          ['/src/folder'],
          '/dest',
          strategy: ConflictResolutionStrategy.replace,
        );

        expect(fs.file('/dest/folder/new.txt').existsSync(), true);
        expect(fs.file('/dest/folder/old.txt').existsSync(), false);
        expect(fs.directory('/src/folder').existsSync(), false);
      },
    );

    test('getFileDetails returns directory stat', () async {
      fs.directory('/root/test').createSync(recursive: true);

      final stat = await repo.getFileDetails('/root/test');

      expect(stat.type, FileSystemEntityType.directory);
    });

    test('entityExists returns true for existing directory', () async {
      fs.directory('/folder').createSync(recursive: true);

      final exists = await repo.entityExists('/folder');

      expect(exists, true);
    });

    test('searchFiles finds matching directories', () async {
      fs.directory('/root/test_folder').createSync(recursive: true);

      final result = await repo.searchFiles('/root', 'test');

      expect(result.length, 1);
      expect(p.basename(result.first.path), 'test_folder');
    });

    test('searchFiles is case insensitive', () async {
      fs.file('/root/TestFile.txt').createSync(recursive: true);

      final result = await repo.searchFiles('/root', 'testfile');

      expect(result.length, 1);
    });

    test('searchFiles searches nested directories within max depth', () async {
      fs.file('/root/a/b/file.txt').createSync(recursive: true);

      final result = await repo.searchFiles('/root', 'file');

      expect(result.length, 1);
    });

    test('createFolder does not fail if folder already exists', () async {
      fs.directory('/root/test').createSync(recursive: true);

      await repo.createFolder('/root', 'test');

      expect(fs.directory('/root/test').existsSync(), true);
    });
  });
}
