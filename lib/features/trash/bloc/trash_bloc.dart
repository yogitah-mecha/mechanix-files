import 'package:mechanix_files/features/trash/bloc/trash_event.dart';
import 'package:mechanix_files/features/trash/bloc/trash_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_files/features/trash/data/repositories/trash_repository.dart';

class TrashBloc extends Bloc<TrashEvent, TrashState> {
  final TrashRepository trashRepository;

  TrashBloc({required this.trashRepository}) : super(const TrashState()) {
    on<MoveToTrash>(_onMoveToTrash);
  }

  Future<void> _onMoveToTrash(
    MoveToTrash event,
    Emitter<TrashState> emit,
  ) async {
    try {
      await trashRepository.moveToTrash(event.paths);
      final items = await trashRepository.getTrashItems();

      emit(
        state.copyWith(
          loading: false,
          trashItems: items,
          operationSuccess: true,
        ),
      );

      event.completer?.complete();
    } catch (e) {
      event.completer?.completeError(e);

      emit(
        state.copyWith(
          loading: false,
          error: e.toString(),
          operationSuccess: false,
        ),
      );
    }
  }
}
