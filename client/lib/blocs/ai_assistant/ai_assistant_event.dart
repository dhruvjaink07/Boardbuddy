import 'package:equatable/equatable.dart';

abstract class AiAssistantEvent extends Equatable {
  const AiAssistantEvent();

  @override
  List<Object?> get props => [];
}

class FilterChipSelected extends AiAssistantEvent {
  final String category;

  const FilterChipSelected(this.category);

  @override
  List<Object?> get props => [category];
}

class BoardStyleSelected extends AiAssistantEvent {
  final String style; // 'Classic', 'Orbit', 'Fluid'

  const BoardStyleSelected(this.style);

  @override
  List<Object?> get props => [style];
}

class AssistantPromptSubmitted extends AiAssistantEvent {
  final String prompt;

  const AssistantPromptSubmitted(this.prompt);

  @override
  List<Object?> get props => [prompt];
}

class MagicSortTriggered extends AiAssistantEvent {
  const MagicSortTriggered();
}
