import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:mechanix_files/features/trash/bloc/trash_bloc.dart';
import 'package:mechanix_files/features/trash/bloc/trash_event.dart';
import 'package:mechanix_files/features/trash/bloc/trash_state.dart';
import 'package:mechanix_files/features/trash/data/repositories/trash_repository.dart';
import 'package:file/file.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTrashRepository extends Mock implements TrashRepository {}

class MockFileSystemEntity extends Mock implements FileSystemEntity {}

void main() {
  late TrashBloc bloc;
  late MockTrashRepository mockRepo;

  setUp(() {
    mockRepo = MockTrashRepository();
    bloc = TrashBloc(trashRepository: mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  group('TrashBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, const TrashState());
    });

    blocTest<TrashBloc, TrashState>(
      'moves items to trash successfully',
      build: () {
        when(() => mockRepo.moveToTrash(any())).thenAnswer((_) async {});

        when(
          () => mockRepo.getTrashItems(),
        ).thenAnswer((_) async => <FileSystemEntity>[]);

        return bloc;
      },
      act: (bloc) => bloc.add(MoveToTrash(const ['/file1.txt', '/file2.txt'])),
      expect:
          () => [
            const TrashState(
              loading: false,
              trashItems: [],
              operationSuccess: true,
            ),
          ],
      verify: (_) {
        verify(
          () => mockRepo.moveToTrash(['/file1.txt', '/file2.txt']),
        ).called(1);

        verify(() => mockRepo.getTrashItems()).called(1);
      },
    );

    blocTest<TrashBloc, TrashState>(
      'emits error state when moveToTrash throws',
      build: () {
        when(
          () => mockRepo.moveToTrash(any()),
        ).thenThrow(Exception('trash failed'));

        return bloc;
      },
      act: (bloc) => bloc.add(MoveToTrash(const ['/file1.txt'])),
      expect:
          () => [
            isA<TrashState>()
                .having((s) => s.loading, 'loading', false)
                .having((s) => s.operationSuccess, 'operationSuccess', false)
                .having((s) => s.error, 'error', contains('Exception')),
          ],
      verify: (_) {
        verify(() => mockRepo.moveToTrash(['/file1.txt'])).called(1);
      },
    );

    blocTest<TrashBloc, TrashState>(
      'completer completes on success',
      build: () {
        when(() => mockRepo.moveToTrash(any())).thenAnswer((_) async {});

        when(
          () => mockRepo.getTrashItems(),
        ).thenAnswer((_) async => <FileSystemEntity>[]);

        return bloc;
      },
      act: (bloc) {
        final completer = Completer<void>();

        bloc.add(MoveToTrash(const ['/file1.txt'], completer: completer));

        return completer.future;
      },
      expect: () => [isA<TrashState>()],
    );

    blocTest<TrashBloc, TrashState>(
      'completer completes with error on failure',
      build: () {
        when(() => mockRepo.moveToTrash(any())).thenThrow(Exception('fail'));

        return bloc;
      },
      act: (bloc) {
        final completer = Completer<void>();

        bloc.add(MoveToTrash(const ['/file1.txt'], completer: completer));

        return completer.future.catchError((_) {});
      },
      expect:
          () => [
            isA<TrashState>().having(
              (s) => s.operationSuccess,
              'operationSuccess',
              false,
            ),
          ],
    );

    blocTest<TrashBloc, TrashState>(
      'emits success state with trash items',
      build: () {
        when(() => mockRepo.moveToTrash(any())).thenAnswer((_) async {});

        when(
          () => mockRepo.getTrashItems(),
        ).thenAnswer((_) async => <FileSystemEntity>[]);

        return bloc;
      },
      act: (bloc) => bloc.add(MoveToTrash(const ['/a.txt'])),
      expect:
          () => [
            const TrashState(
              loading: false,
              trashItems: [],
              operationSuccess: true,
            ),
          ],
      verify: (_) {
        verify(() => mockRepo.moveToTrash(['/a.txt'])).called(1);
        verify(() => mockRepo.getTrashItems()).called(1);
      },
    );

    blocTest<TrashBloc, TrashState>(
      'emits error state when repository throws',
      build: () {
        when(() => mockRepo.moveToTrash(any())).thenThrow(Exception('Error'));

        return bloc;
      },
      act: (bloc) => bloc.add(MoveToTrash(const ['/file.txt'])),
      expect:
          () => [
            isA<TrashState>()
                .having((s) => s.loading, 'loading', false)
                .having((s) => s.operationSuccess, 'operationSuccess', false)
                .having((s) => s.error, 'error', contains('Error')),
          ],
      verify: (_) {
        verify(() => mockRepo.moveToTrash(['/file.txt'])).called(1);
        verifyNever(() => mockRepo.getTrashItems());
      },
    );
  });
}
