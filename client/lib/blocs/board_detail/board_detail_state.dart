import 'package:equatable/equatable.dart';
import '../../models/board_model.dart';

abstract class BoardDetailState extends Equatable {
  const BoardDetailState();

  @override
  List<Object?> get props => [];
}

class BoardDetailInitial extends BoardDetailState {
  const BoardDetailInitial();
}

class BoardDetailLoading extends BoardDetailState {
  const BoardDetailLoading();
}

class BoardDetailLoaded extends BoardDetailState {
  final BoardModel board;
  final String activeColumnId;

  const BoardDetailLoaded({
    required this.board,
    required this.activeColumnId,
  });

  BoardDetailLoaded copyWith({
    BoardModel? board,
    String? activeColumnId,
  }) {
    return BoardDetailLoaded(
      board: board ?? this.board,
      activeColumnId: activeColumnId ?? this.activeColumnId,
    );
  }

  @override
  List<Object?> get props => [board, activeColumnId];
}

class BoardDetailError extends BoardDetailState {
  final String message;

  const BoardDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
