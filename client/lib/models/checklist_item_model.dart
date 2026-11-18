import 'package:equatable/equatable.dart';

class ChecklistItem extends Equatable {
  final String id;
  final String cardId;
  final String title;
  final bool isCompleted;
  final int position;

  const ChecklistItem({
    required this.id,
    required this.cardId,
    required this.title,
    this.isCompleted = false,
    this.position = 0,
  });

  ChecklistItem copyWith({
    String? id,
    String? cardId,
    String? title,
    bool? isCompleted,
    int? position,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
    );
  }

  @override
  List<Object?> get props => [id, cardId, title, isCompleted, position];
}
