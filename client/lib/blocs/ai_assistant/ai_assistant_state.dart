import 'package:equatable/equatable.dart';

abstract class AiAssistantState extends Equatable {
  const AiAssistantState();

  @override
  List<Object?> get props => [];
}

class AiAssistantInitial extends AiAssistantState {
  final String activeCategory;
  final String activeStyle;

  const AiAssistantInitial({
    this.activeCategory = 'All',
    this.activeStyle = 'Orbit',
  });

  @override
  List<Object?> get props => [activeCategory, activeStyle];
}

class AiAssistantThinking extends AiAssistantState {
  final String activeCategory;
  final String activeStyle;

  const AiAssistantThinking({
    required this.activeCategory,
    required this.activeStyle,
  });

  @override
  List<Object?> get props => [activeCategory, activeStyle];
}

class AiAssistantSuccess extends AiAssistantState {
  final String message;
  final String activeCategory;
  final String activeStyle;

  const AiAssistantSuccess({
    required this.message,
    required this.activeCategory,
    required this.activeStyle,
  });

  @override
  List<Object?> get props => [message, activeCategory, activeStyle];
}
