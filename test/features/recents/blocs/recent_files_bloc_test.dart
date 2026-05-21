import 'package:bloc_test/bloc_test.dart';
import 'package:file/file.dart';
import 'package:files/features/recents/blocs/recent_file_event.dart';
import 'package:files/features/recents/blocs/recent_file_state.dart';
import 'package:files/features/recents/blocs/recent_files_bloc.dart';
import 'package:files/features/recents/data/models/recent_files.dart';
import 'package:files/features/recents/data/repositories/recent_files_repository.dart';
import 'package:files/features/files_explorer/data/repositories/app_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecentFilesRepository extends Mock implements RecentFilesRepository {}

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

class MockFileSystem extends Mock implements FileSystem {}

class MockFile extends Mock implements File {}

class MockDirectory extends Mock implements Directory {}

void main() {
  late RecentFilesBloc bloc;
  late MockRecentFilesRepository mockRecentRepo;
  late MockAppSettingsRepository mockSettingsRepo;

  setUp(() {
    mockRecentRepo = MockRecentFilesRepository();
    mockSettingsRepo = MockAppSettingsRepository();

    bloc = RecentFilesBloc(
      recentFilesRepository: mockRecentRepo,
      appSettingsRepository: mockSettingsRepo,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('RecentFilesBloc', () {
    test('initial state is correct', () {
      expect(
        bloc.state,
        const RecentFileState(fileSystemList: [], loading: false, error: null),
      );
    });

    blocTest<RecentFilesBloc, RecentFileState>(
      'emits loaded recent files successfully when LoadRecentFiles is added',
      build: () {
        when(() => mockRecentRepo.getRecentFiles()).thenAnswer(
          (_) async => [
            // fake recent model (must match your actual model type)
            RecentFile(path: '/storage/file1.txt', openedAt: DateTime.now()),
            RecentFile(path: '/storage/file2.txt', openedAt: DateTime.now()),
          ],
        );

        return bloc;
      },
      act: (bloc) => bloc.add(LoadRecentFiles()),
      expect: () {
        return [bloc.state.copyWith(loading: false, fileSystemList: [])];
      },
    );

    blocTest<RecentFilesBloc, RecentFileState>(
      'filters out non-existing files when LoadRecentFiles is called',
      build: () {
        when(() => mockRecentRepo.getRecentFiles()).thenAnswer(
          (_) async => [
            RecentFile(path: '/storage/existing.txt', openedAt: DateTime.now()),
            RecentFile(path: '/storage/missing.txt', openedAt: DateTime.now()),
          ],
        );

        return bloc;
      },
      act: (bloc) => bloc.add(LoadRecentFiles()),
      expect: () {
        return [bloc.state.copyWith(loading: false, fileSystemList: [])];
      },
    );

    blocTest<RecentFilesBloc, RecentFileState>(
      'does not crash and emits loading false on error in LoadRecentFiles',
      build: () {
        when(
          () => mockRecentRepo.getRecentFiles(),
        ).thenThrow(Exception('error'));

        return bloc;
      },
      act: (bloc) => bloc.add(LoadRecentFiles()),
      expect: () => [bloc.state.copyWith(loading: false)],
    );

    blocTest<RecentFilesBloc, RecentFileState>(
      'calls repository when AddToRecentFiles is added',
      build: () {
        when(
          () => mockRecentRepo.addRecentFile(any()),
        ).thenAnswer((_) async {});

        return bloc;
      },
      act: (bloc) => bloc.add(AddToRecentFiles('/storage/file1.txt')),
      expect: () => [],
      verify: (_) {
        verify(
          () => mockRecentRepo.addRecentFile('/storage/file1.txt'),
        ).called(1);
      },
    );
  });
}
