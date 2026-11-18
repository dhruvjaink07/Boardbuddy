import 'package:equatable/equatable.dart';
import '../../models/card_model.dart';

abstract class BoardDetailEvent extends Equatable {
  const BoardDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadBoardDetail extends BoardDetailEvent {
  final String boardId;

  const LoadBoardDetail(this.boardId);

  @override
  List<Object?> get props => [boardId];
}

class MoveCardRequested extends BoardDetailEvent {
  final String cardId;
  final String sourceColumnId;
  final String targetColumnId;
  final int newPosition;

  const MoveCardRequested({
    required this.cardId,
    required this.sourceColumnId,
    required this.targetColumnId,
    required this.newPosition,
  });

  @override
  List<Object?> get props => [cardId, sourceColumnId, targetColumnId, newPosition];
}

class AddCardRequested extends BoardDetailEvent {
  final CardModel card;

  const AddCardRequested(this.card);

  @override
  List<Object?> get props => [card];
}

class UpdateCardRequested extends BoardDetailEvent {
  final CardModel card;

  const UpdateCardRequested(this.card);

  @override
  List<Object?> get props => [card];
}

class ToggleSubtaskRequested extends BoardDetailEvent {
  final String cardId;
  final String subtaskId;

  const ToggleSubtaskRequested({required this.cardId, required this.subtaskId});

  @override
  List<Object?> get props => [cardId, subtaskId];
}
