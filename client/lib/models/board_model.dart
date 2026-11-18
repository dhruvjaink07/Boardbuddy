import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'column_model.dart';

class BoardModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final Color accentColor;
  final String iconType; // 'rocket', 'calendar', 'pen', 'megaphone', 'chart', 'star'
  final String updatedTimeAgo;
  final int progress; // 0 to 100
  final List<String> memberAvatars;
  final bool isFavorite;
  final List<ColumnModel> columns;

  const BoardModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.accentColor,
    required this.iconType,
    required this.updatedTimeAgo,
    this.progress = 0,
    this.memberAvatars = const [],
    this.isFavorite = false,
    this.columns = const [],
  });

  BoardModel copyWith({
    String? id,
    String? name,
    String? description,
    Color? accentColor,
    String? iconType,
    String? updatedTimeAgo,
    int? progress,
    List<String>? memberAvatars,
    bool? isFavorite,
    List<ColumnModel>? columns,
  }) {
    return BoardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      accentColor: accentColor ?? this.accentColor,
      iconType: iconType ?? this.iconType,
      updatedTimeAgo: updatedTimeAgo ?? this.updatedTimeAgo,
      progress: progress ?? this.progress,
      memberAvatars: memberAvatars ?? this.memberAvatars,
      isFavorite: isFavorite ?? this.isFavorite,
      columns: columns ?? this.columns,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        accentColor,
        iconType,
        updatedTimeAgo,
        progress,
        memberAvatars,
        isFavorite,
        columns,
      ];
}
