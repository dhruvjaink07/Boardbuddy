import 'package:equatable/equatable.dart';
import 'checklist_item_model.dart';
import 'comment_model.dart';

enum CardPriority { low, medium, high, urgent }

enum CardStatus { todo, inProgress, done }

class CardModel extends Equatable {
  final String id;
  final String boardId;
  final String columnId;
  final String title;
  final String description;
  final CardStatus status;
  final CardPriority priority;
  final String? category;
  final int progress; // 0 to 100
  final List<String> assigneeNames;
  final List<String> assigneeAvatars;
  final List<String> labels;
  final String? dueDateText;
  final int estimateMinutes;
  final int position;
  final List<ChecklistItem> subtasks;
  final List<Comment> comments;
  final int attachmentCount;

  const CardModel({
    required this.id,
    required this.boardId,
    required this.columnId,
    required this.title,
    this.description = '',
    this.status = CardStatus.todo,
    this.priority = CardPriority.medium,
    this.category,
    this.progress = 0,
    this.assigneeNames = const [],
    this.assigneeAvatars = const [],
    this.labels = const [],
    this.dueDateText,
    this.estimateMinutes = 0,
    this.position = 0,
    this.subtasks = const [],
    this.comments = const [],
    this.attachmentCount = 0,
  });

  CardModel copyWith({
    String? id,
    String? boardId,
    String? columnId,
    String? title,
    String? description,
    CardStatus? status,
    CardPriority? priority,
    String? category,
    int? progress,
    List<String>? assigneeNames,
    List<String>? assigneeAvatars,
    List<String>? labels,
    String? dueDateText,
    int? estimateMinutes,
    int? position,
    List<ChecklistItem>? subtasks,
    List<Comment>? comments,
    int? attachmentCount,
  }) {
    return CardModel(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      columnId: columnId ?? this.columnId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      assigneeNames: assigneeNames ?? this.assigneeNames,
      assigneeAvatars: assigneeAvatars ?? this.assigneeAvatars,
      labels: labels ?? this.labels,
      dueDateText: dueDateText ?? this.dueDateText,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      position: position ?? this.position,
      subtasks: subtasks ?? this.subtasks,
      comments: comments ?? this.comments,
      attachmentCount: attachmentCount ?? this.attachmentCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        boardId,
        columnId,
        title,
        description,
        status,
        priority,
        category,
        progress,
        assigneeNames,
        assigneeAvatars,
        labels,
        dueDateText,
        estimateMinutes,
        position,
        subtasks,
        comments,
        attachmentCount,
      ];
}
