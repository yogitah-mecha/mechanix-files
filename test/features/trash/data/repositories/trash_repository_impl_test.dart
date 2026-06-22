import 'package:file/memory.dart';
import 'package:mechanix_files/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:mechanix_files/features/trash/services/trash_path_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryFileSystem fs;
  late TrashRepositoryImpl repo;

  setUp(() async {
    fs = MemoryFileSystem();

    repo = TrashRepositoryImpl(fs: fs);

    await TrashPathsService.init(fs, homeOverride: '/home/test');

    // explicitly create full trash tree in memory FS
    fs
        .directory('/home/test/.local/share/Trash/files')
        .createSync(recursive: true);

    fs
        .directory('/home/test/.local/share/Trash/info')
        .createSync(recursive: true);
  });

  group('TrashRepositoryImpl', () {
    test('moveToTrash moves single file into trash', () async {
      fs.file('/tmp/file.txt').createSync(recursive: true);

      await repo.moveToTrash(['/tmp/file.txt']);

      expect(fs.file('/tmp/file.txt').existsSync(), false);

      expect(
        fs
            .file('${TrashPathsService.trashFilesDir.path}/file.txt')
            .existsSync(),
        true,
      );
    });

    test('moveToTrash moves multiple files into trash', () async {
      fs.file('/tmp/a.txt').createSync(recursive: true);
      fs.file('/tmp/b.txt').createSync(recursive: true);

      await repo.moveToTrash(['/tmp/a.txt', '/tmp/b.txt']);

      expect(fs.file('/tmp/a.txt').existsSync(), false);
      expect(fs.file('/tmp/b.txt').existsSync(), false);

      expect(
        fs.file('${TrashPathsService.trashFilesDir.path}/a.txt').existsSync(),
        true,
      );

      expect(
        fs.file('${TrashPathsService.trashFilesDir.path}/b.txt').existsSync(),
        true,
      );
    });

    test(
      'getTrashItems returns empty list when trash directory is empty',
      () async {
        final result = await repo.getTrashItems();

        expect(result, isEmpty);
      },
    );

    test(
      'getTrashItems returns files sorted by modified time descending',
      () async {
        final trashDir = fs.directory(TrashPathsService.trashFilesDir.path);

        final oldFile =
            fs.file('${trashDir.path}/old.txt')
              ..createSync(recursive: true)
              ..writeAsStringSync('old');

        await Future<void>.delayed(const Duration(milliseconds: 10));

        final newFile =
            fs.file('${trashDir.path}/new.txt')
              ..createSync(recursive: true)
              ..writeAsStringSync('new');

        final result = await repo.getTrashItems();

        expect(result.length, 2);
        expect(result.first.path, newFile.path);
        expect(result.last.path, oldFile.path);
      },
    );

    test('getTrashItems returns only trash directory contents', () async {
      final trashDir = fs.directory(TrashPathsService.trashFilesDir.path);

      fs.file('${trashDir.path}/file1.txt').createSync(recursive: true);

      fs.file('${trashDir.path}/file2.txt').createSync(recursive: true);

      final result = await repo.getTrashItems();

      expect(result.length, 2);

      expect(result.every((e) => e.path.startsWith(trashDir.path)), true);
    });

    test('moveToTrash handles non-existing paths safely', () async {
      await repo.moveToTrash(['/tmp/not_found.txt']);

      expect(
        fs
            .file('${TrashPathsService.trashFilesDir.path}/not_found.txt')
            .existsSync(),
        false,
      );
    });
  });
}
