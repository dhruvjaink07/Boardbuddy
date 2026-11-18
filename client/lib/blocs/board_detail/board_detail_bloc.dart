import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/board_repository.dart';
import 'board_detail_event.dart';
import 'board_detail_state.dart';

class BoardDetailBloc extends Bloc<BoardDetailEvent, BoardDetailState> {
  final BoardRepository repository;

  BoardDetailBloc({required this.repository})
      : super(const BoardDetailInitial()) {
    on<LoadBoardDetail>(_onLoadBoardDetail);
    on<MoveCardRequested>(_onMoveCardRequested);
    on<AddCardRequested>(_onAddCardRequested);
    on<UpdateCardRequested>(_onUpdateCardRequested);
    on<ToggleSubtaskRequested>(_onToggleSubtaskRequested);
  }

  Future<void> _onLoadBoardDetail(
    LoadBoardDetail event,
    Emitter<BoardDetailState> emit,
  ) async {
    emit(const BoardDetailLoading());
    try {
      final board = await repository.getBoardById(event.boardId);
      final initialCol = board.columns.isNotEmpty ? board.columns.first.id : '';
      emit(BoardDetailLoaded(board: board, activeColumnId: initialCol));
    } catch (e) {
      emit(BoardDetailError(e.toString()));
    }
  }

  Future<void> _onMoveCardRequested(
    MoveCardRequested event,
    Emitter<BoardDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BoardDetailLoaded) return;

    try {
      await repository.moveCard(
        cardId: event.cardId,
        sourceColumnId: event.sourceColumnId,
        targetColumnId: event.targetColumnId,
        newPosition: event.newPosition,
      );
      final updatedBoard = await repository.getBoardById(currentState.board.id);
      emit(currentState.copyWith(board: updatedBoard));
    } catch (e) {
      emit(BoardDetailError(e.toString()));
    }
  }

  Future<void> _onAddCardRequested(
    AddCardRequested event,
    Emitter<BoardDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BoardDetailLoaded) return;

    try {
      await repository.addCard(event.card);
      final updatedBoard = await repository.getBoardById(currentState.board.id);
      emit(currentState.copyWith(board: updatedBoard));
    } catch (e) {
      emit(BoardDetailError(e.toString()));
    }
  }

  Future<void> _onUpdateCardRequested(
    UpdateCardRequested event,
    Emitter<BoardDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BoardDetailLoaded) return;

    try {
      await repository.updateCard(event.card);
      final updatedBoard = await repository.getBoardById(currentState.board.id);
      emit(currentState.copyWith(board: updatedBoard));
    } catch (e) {
      emit(BoardDetailError(e.toString()));
    }
  }

  Future<void> _onToggleSubtaskRequested(
    ToggleSubtaskRequested event,
    Emitter<BoardDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BoardDetailLoaded) return;

    try {
      await repository.toggleSubtask(cardId: event.cardId, subtaskId: event.subtaskId);
      final updatedBoard = await repository.getBoardById(currentState.board.id);
      emit(currentState.copyWith(board: updatedBoard));
    } catch (e) {
      emit(BoardDetailError(e.toString()));
    }
  }
}
