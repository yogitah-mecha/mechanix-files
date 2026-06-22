import 'package:bloc_test/bloc_test.dart';
import 'package:file/file.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_boc.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_event.dart';
import 'package:mechanix_files/features/files_explorer/blocs/file_state.dart';
import 'package:mechanix_files/features/files_explorer/controllers/file_manager_controller.dart';
import 'package:mechanix_files/features/files_explorer/data/models/app_settings.dart';
import 'package:mechanix_files/features/files_explorer/data/models/conflict_resolution_strategy.dart';
import 'package:mechanix_files/features/files_explorer/data/repositories/app_settings_repository.dart';
import 'package:mechanix_files/features/files_explorer/data/repositories/file_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFileRepository extends Mock implements FileRepository {}

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

class MockFileManagerController extends Mock implements FileManagerController {}

class MockFileSystemEntity extends Mock implements FileSystemEntity {}

void main() {
  late FilesBloc bloc;
  late MockFileRepository mockFileRepository;
  late MockAppSettingsRepository mockSettingsRepository;
  late MockFileManagerController mockController;
  late FileSystemEntity mockFileEntity;

  setUp(() {
    mockFileRepository = MockFileRepository();
    mockSettingsRepository = MockAppSettingsRepository();
    mockController = MockFileManagerController();
    mockFileEntity = MockFileSystemEntity();

    bloc = FilesBloc(
      fileRepository: mockFileRepository,
      appSettingsRepository: mockSettingsRepository,
    );
  });

  setUpAll(() {
    registerFallbackValue(ConflictResolutionStrategy.replace);
  });

  tearDown(() {
    bloc.close();
  });

  group('FilesBloc', () {
    test('initial state is correct', () {
      expect(
        bloc.state,
        const FilesState(
          fileSystemList: [],
          loading: false,
          error: null,
          currentSortBy: '',
          isAscending: false,
          conflictDestinationPath: '',
        ),
      );
    });

    blocTest<FilesBloc, FilesState>(
      'emits loading false with showHiddenFiles on InitializeFiles',
      build: () {
        when(
          () => mockSettingsRepository.getSettings(),
        ).thenAnswer((_) async => AppSettings(showHiddenFiles: true));

        return bloc;
      },
      act: (bloc) => bloc.add(InitializeFiles()),
      expect:
          () => [
            bloc.state.copyWith(loading: true, showHiddenFiles: false),
            bloc.state.copyWith(loading: false, showHiddenFiles: true),
          ],
    );

    blocTest<FilesBloc, FilesState>(
      'emits loading states when CreateFolder succeeds',
      build: () {
        when(
          () => mockFileRepository.createFolder(any(), any()),
        ).thenAnswer((_) async {});

        when(() => mockController.reload()).thenAnswer((_) async {});

        when(() => mockController.markNewFolder(any())).thenReturn(null);

        return bloc;
      },
      act:
          (bloc) => bloc.add(
            CreateFolder(
              path: '/storage',
              folderName: 'New Folder',
              controller: mockController,
            ),
          ),
      expect:
          () => [
            bloc.state.copyWith(loading: true),
            bloc.state.copyWith(loading: false),
          ],
      verify: (_) {
        verify(
          () => mockFileRepository.createFolder('/storage', 'New Folder'),
        ).called(1);

        verify(
          () => mockController.markNewFolder('/storage/New Folder'),
        ).called(1);

        verify(() => mockController.reload()).called(1);
      },
    );

    blocTest<FilesBloc, FilesState>(
      'emits loading false when Rename succeeds',
      build: () {
        when(
          () => mockFileRepository.renameEntity(any(), any()),
        ).thenAnswer((_) async {});

        when(() => mockController.reload()).thenAnswer((_) async {});

        return bloc;
      },
      act:
          (bloc) => bloc.add(
            Rename(
              oldPath: '/storage/Old',
              newName: 'New',
              controller: mockController,
            ),
          ),
      expect:
          () => [
            bloc.state.copyWith(loading: true),
            bloc.state.copyWith(loading: false),
          ],
      verify: (_) {
        verify(
          () => mockFileRepository.renameEntity('/storage/Old', 'New'),
        ).called(1);

        verify(() => mockController.reload()).called(1);
      },
    );

    blocTest<FilesBloc, FilesState>(
      'enables copy mode',
      build: () => bloc,
      act: (bloc) => bloc.add(StartCopyMode(const ['/file1'])),
      expect:
          () => [
            bloc.state.copyWith(
              isCopyMode: true,
              copiedPaths: const ['/file1'],
              isMoveMode: false,
              movedPaths: [],
            ),
          ],
    );

    blocTest<FilesBloc, FilesState>(
      'cancels copy mode',
      build: () => bloc,
      seed:
          () => bloc.state.copyWith(
            isCopyMode: true,
            copiedPaths: const ['/file1'],
          ),
      act: (bloc) => bloc.add(CancelCopyMode()),
      expect: () => [bloc.state.copyWith(isCopyMode: false, copiedPaths: [])],
    );
    blocTest<FilesBloc, FilesState>(
      'toggles hidden files',
      build: () {
        when(
          () => mockSettingsRepository.updateShowHidden(any()),
        ).thenAnswer((_) async {});

        return bloc;
      },
      act: (bloc) => bloc.add(ToggleHiddenFiles()),
      expect:
          () => [
            bloc.state.copyWith(loading: true, showHiddenFiles: false),

            bloc.state.copyWith(loading: true, showHiddenFiles: true),

            bloc.state.copyWith(loading: false, showHiddenFiles: true),
          ],
      verify: (_) {
        verify(() => mockSettingsRepository.updateShowHidden(true)).called(1);
      },
    );

    blocTest<FilesBloc, FilesState>(
      'enables move mode',
      build: () => bloc,
      act: (bloc) => bloc.add(StartMoveMode(const ['/file1'])),
      expect:
          () => [
            bloc.state.copyWith(
              isMoveMode: true,
              movedPaths: const ['/file1'],
              isCopyMode: false,
              copiedPaths: [],
            ),
          ],
    );

    blocTest<FilesBloc, FilesState>(
      'cancels move mode',
      build: () => bloc,
      seed:
          () => bloc.state.copyWith(
            isMoveMode: true,
            movedPaths: const ['/file1'],
          ),
      act: (bloc) => bloc.add(CancelMoveMode()),
      expect: () => [bloc.state.copyWith(isMoveMode: false, movedPaths: [])],
    );

    blocTest<FilesBloc, FilesState>(
      'emits conflict state when Copy has conflicts',
      build: () {
        when(
          () => mockFileRepository.entityExists(any()),
        ).thenAnswer((_) async => true);

        return bloc;
      },
      act:
          (bloc) => bloc.add(
            Copy(
              sourcePaths: const ['/storage/file1.txt'],
              destinationPath: '/dest',
              controller: mockController,
            ),
          ),
      expect:
          () => [
            const FilesState(
              fileSystemList: [],
              loading: true,
              error: null,
              conflictDestinationPath: '',
            ),
            const FilesState(
              fileSystemList: [],
              loading: false,
              error: null,
              conflictingPaths: ['/storage/file1.txt'],
              conflictDestinationPath: '/dest',
              isCopyMode: true,
              copiedPaths: ['/storage/file1.txt'],
            ),
          ],
    );

    blocTest<FilesBloc, FilesState>(
      'copies non-conflicting files successfully',
      build: () {
        when(
          () => mockFileRepository.entityExists(any()),
        ).thenAnswer((_) async => false);

        when(
          () => mockFileRepository.copyEntities(
            any(),
            any(),
            strategy: any(named: 'strategy'),
          ),
        ).thenAnswer((_) async {});

        return bloc;
      },
      act:
          (bloc) => bloc.add(
            Copy(
              sourcePaths: const ['/storage/file1.txt'],
              destinationPath: '/dest',
              controller: mockController,
            ),
          ),
      expect:
          () => [
            const FilesState(
              fileSystemList: [],
              loading: true,
              error: null,
              conflictDestinationPath: '',
            ),
            const FilesState(
              fileSystemList: [],
              loading: false,
              error: null,
              conflictDestinationPath: '',
            ),
          ],
      verify: (_) {
        verify(
          () => mockFileRepository.copyEntities(
            ['/storage/file1.txt'],
            '/dest',
            strategy: ConflictResolutionStrategy.replace,
          ),
        ).called(1);
      },
    );

    blocTest<FilesBloc, FilesState>(
      'emits conflict state when Move has conflicts',
      build: () {
        when(
          () => mockFileRepository.entityExists(any()),
        ).thenAnswer((_) async => true);

        return bloc;
      },
      act:
          (bloc) => bloc.add(
            Move(
              sourcePaths: const ['/storage/file1.txt'],
              destinationPath: '/dest',
            ),
          ),
      expect:
          () => [
            const FilesState(
              fileSystemList: [],
              loading: true,
              error: null,
              conflictDestinationPath: '',
            ),
            const FilesState(
              fileSystemList: [],
              loading: false,
              error: null,
              conflictingPaths: ['/storage/file1.txt'],
              conflictDestinationPath: '/dest',
              isMoveMode: true,
              movedPaths: ['/storage/file1.txt'],
            ),
          ],
    );

    blocTest<FilesBloc, FilesState>(
      'moves non-conflicting files successfully',
      build: () {
        when(
          () => mockFileRepository.entityExists(any()),
        ).thenAnswer((_) async => false);

        when(
          () => mockFileRepository.moveEntities(
            any(),
            any(),
            strategy: any(named: 'strategy'),
          ),
        ).thenAnswer((_) async {});

        return bloc;
      },
      act:
          (bloc) => bloc.add(
            Move(
              sourcePaths: const ['/storage/file1.txt'],
              destinationPath: '/dest',
            ),
          ),
      expect:
          () => [
            bloc.state.copyWith(loading: true, error: null),
            bloc.state.copyWith(loading: false),
          ],
      verify: (_) {
        verify(
          () => mockFileRepository.moveEntities(
            ['/storage/file1.txt'],
            '/dest',
            strategy: ConflictResolutionStrategy.replace,
          ),
        ).called(1);
      },
    );

    blocTest<FilesBloc, FilesState>(
      'continues copy with conflict resolution and clears copy mode',
      build: () {
        when(
          () => mockFileRepository.copyEntities(
            any(),
            any(),
            strategy: any(named: 'strategy'),
          ),
        ).thenAnswer((_) async {});

        when(() => mockController.reload()).thenAnswer((_) async {});

        return bloc;
      },
      act:
          (bloc) => bloc.add(
            ContinueCopyWithConflictResolution(
              sourcePaths: const ['/storage/file1.txt'],
              destinationPath: '/dest',
              strategy: ConflictResolutionStrategy.replace,
              controller: mockController,
            ),
          ),
      expect:
          () => [
            bloc.state.copyWith(loading: true, error: null),
            bloc.state.copyWith(
              conflictingPaths: [],
              conflictDestinationPath: '',
              isCopyMode: false,
              loading: false,
            ),
          ],
      verify: (_) {
        verify(
          () => mockFileRepository.copyEntities(
            ['/storage/file1.txt'],
            '/dest',
            strategy: ConflictResolutionStrategy.replace,
          ),
        ).called(1);

        verify(() => mockController.reload()).called(1);
      },
    );

    blocTest<FilesBloc, FilesState>(
      'continues move with conflict resolution and clears move mode',
      build: () {
        when(
          () => mockFileRepository.moveEntities(
            any(),
            any(),
            strategy: any(named: 'strategy'),
          ),
        ).thenAnswer((_) async {});

        return bloc;
      },
      act:
          (bloc) => bloc.add(
            ContinueMoveWithConflictResolution(
              sourcePaths: const ['/storage/file1.txt'],
              destinationPath: '/dest',
              strategy: ConflictResolutionStrategy.replace,
            ),
          ),
      expect:
          () => [
            bloc.state.copyWith(loading: true, error: null),
            bloc.state.copyWith(
              conflictingPaths: [],
              conflictDestinationPath: '',
              isMoveMode: false,
              loading: false,
            ),
          ],
      verify: (_) {
        verify(
          () => mockFileRepository.moveEntities(
            ['/storage/file1.txt'],
            '/dest',
            strategy: ConflictResolutionStrategy.replace,
          ),
        ).called(1);
      },
    );

    blocTest<FilesBloc, FilesState>(
      'searches files successfully',
      build: () {
        when(
          () => mockFileRepository.searchFiles(any(), any()),
        ).thenAnswer((_) async => []);

        return bloc;
      },
      act: (bloc) => bloc.add(SearchFilesInDirectory('/storage', 'test')),
      expect:
          () => [
            bloc.state.copyWith(loading: true, error: null),
            bloc.state.copyWith(fileSystemList: [], loading: false),
          ],
      verify: (_) {
        verify(
          () => mockFileRepository.searchFiles('/storage', 'test'),
        ).called(1);
      },
    );

    blocTest<FilesBloc, FilesState>(
      'clears search results',
      build: () => bloc,
      seed:
          () => bloc.state.copyWith(
            fileSystemList: [mockFileEntity],
            loading: true,
          ),
      act: (bloc) => bloc.add(ClearSearchResults()),
      expect: () => [bloc.state.copyWith(fileSystemList: [], loading: false)],
    );

    blocTest<FilesBloc, FilesState>(
      'fetches file details successfully',
      build: () {
        final stat = FileStat.statSync('.');

        when(
          () => mockFileRepository.getFileDetails(any()),
        ).thenAnswer((_) async => stat);

        return bloc;
      },
      act: (bloc) => bloc.add(FetchFileDetails('/storage/file.txt')),
      expect:
          () => [
            const FilesState(
              fileSystemList: [],
              loading: true,
              error: null,
              conflictDestinationPath: '',
            ),
            isA<FilesState>()
                .having((s) => s.loading, 'loading', false)
                .having((s) => s.fileDetails, 'fileDetails', isNotNull),
          ],
      verify: (_) {
        verify(
          () => mockFileRepository.getFileDetails('/storage/file.txt'),
        ).called(1);
      },
    );
  });
}
