import 'package:equatable/equatable.dart';
import '../../models/board_model.dart';

abstract class BoardListEvent extends Equatable {
  const BoardListEvent();

  @override
  List<Object?> get props => [];
}

class BoardListRequested extends BoardListEvent {
  final String filter; // 'all', 'recent', 'favorites'

  const BoardListRequested({this.filter = 'all'});

  @override
  List<Object?> get props => [filter];
}

class BoardFilterChanged extends BoardListEvent {
  final String filter;

  const BoardFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

class CreateBoardSubmitted extends BoardListEvent {
  final BoardModel board;

  const CreateBoardSubmitted(this.board);

  @override
  List<Object?> get props => [board];
}

class DeleteBoardRequested extends BoardListEvent {
  final String boardId;

  const DeleteBoardRequested(this.boardId);

  @override
  List<Object?> get props => [boardId];
}
