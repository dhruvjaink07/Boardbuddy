import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/board_repository.dart';
import 'board_list_event.dart';
import 'board_list_state.dart';

class BoardListBloc extends Bloc<BoardListEvent, BoardListState> {
  final BoardRepository repository;

  BoardListBloc({required this.repository})
      : super(const BoardListInitial()) {
    on<BoardListRequested>(_onBoardListRequested);
    on<BoardFilterChanged>(_onBoardFilterChanged);
    on<CreateBoardSubmitted>(_onCreateBoardSubmitted);
    on<DeleteBoardRequested>(_onDeleteBoardRequested);
  }

  Future<void> _onBoardListRequested(
    BoardListRequested event,
    Emitter<BoardListState> emit,
  ) async {
    emit(const BoardListLoading());
    try {
      final boards = await repository.getBoards(filter: event.filter);
      if (boards.isEmpty) {
        emit(const BoardListEmpty());
      } else {
        emit(BoardListLoaded(boards: boards, activeFilter: event.filter));
      }
    } catch (e) {
      emit(BoardListError(e.toString()));
    }
  }

  Future<void> _onBoardFilterChanged(
    BoardFilterChanged event,
    Emitter<BoardListState> emit,
  ) async {
    emit(const BoardListLoading());
    try {
      final boards = await repository.getBoards(filter: event.filter);
      emit(BoardListLoaded(boards: boards, activeFilter: event.filter));
    } catch (e) {
      emit(BoardListError(e.toString()));
    }
  }

  Future<void> _onCreateBoardSubmitted(
    CreateBoardSubmitted event,
    Emitter<BoardListState> emit,
  ) async {
    try {
      await repository.createBoard(event.board);
      add(const BoardListRequested(filter: 'all'));
    } catch (e) {
      emit(BoardListError(e.toString()));
    }
  }

  Future<void> _onDeleteBoardRequested(
    DeleteBoardRequested event,
    Emitter<BoardListState> emit,
  ) async {
    try {
      await repository.deleteBoard(event.boardId);
      add(const BoardListRequested(filter: 'all'));
    } catch (e) {
      emit(BoardListError(e.toString()));
    }
  }
}
