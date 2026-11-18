import 'package:equatable/equatable.dart';
import 'card_model.dart';

class ColumnModel extends Equatable {
  final String id;
  final String boardId;
  final String title;
  final int position;
  final List<CardModel> cards;

  const ColumnModel({
    required this.id,
    required this.boardId,
    required this.title,
    required this.position,
    this.cards = const [],
  });

  ColumnModel copyWith({
    String? id,
    String? boardId,
    String? title,
    int? position,
    List<CardModel>? cards,
  }) {
    return ColumnModel(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      position: position ?? this.position,
      cards: cards ?? this.cards,
    );
  }

  @override
  List<Object?> get props => [id, boardId, title, position, cards];
}
