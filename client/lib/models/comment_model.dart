import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String cardId;
  final String authorName;
  final String? authorAvatar;
  final String body;
  final String timeAgo;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.cardId,
    required this.authorName,
    this.authorAvatar,
    required this.body,
    required this.timeAgo,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, cardId, authorName, authorAvatar, body, timeAgo, createdAt];
}
