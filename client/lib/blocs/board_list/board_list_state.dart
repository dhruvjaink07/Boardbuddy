import 'package:equatable/equatable.dart';
import '../../models/board_model.dart';

abstract class BoardListState extends Equatable {
  const BoardListState();

  @override
  List<Object?> get props => [];
}

class BoardListInitial extends BoardListState {
  const BoardListInitial();
}

class BoardListLoading extends BoardListState {
  const BoardListLoading();
}

class BoardListLoaded extends BoardListState {
  final List<BoardModel> boards;
  final String activeFilter; // 'all', 'recent', 'favorites'

  const BoardListLoaded({
    required this.boards,
    this.activeFilter = 'all',
  });

  @override
  List<Object?> get props => [boards, activeFilter];
}

class BoardListEmpty extends BoardListState {
  const BoardListEmpty();
}

class BoardListError extends BoardListState {
  final String message;

  const BoardListError(this.message);

  @override
  List<Object?> get props => [message];
}
