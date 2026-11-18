import 'package:flutter_bloc/flutter_bloc.dart';
import 'ai_assistant_event.dart';
import 'ai_assistant_state.dart';

class AiAssistantBloc extends Bloc<AiAssistantEvent, AiAssistantState> {
  AiAssistantBloc() : super(const AiAssistantInitial()) {
    on<FilterChipSelected>(_onFilterChipSelected);
    on<BoardStyleSelected>(_onBoardStyleSelected);
    on<AssistantPromptSubmitted>(_onAssistantPromptSubmitted);
    on<MagicSortTriggered>(_onMagicSortTriggered);
  }

  void _onFilterChipSelected(
    FilterChipSelected event,
    Emitter<AiAssistantState> emit,
  ) {
    emit(AiAssistantInitial(
      activeCategory: event.category,
      activeStyle: state is AiAssistantInitial
          ? (state as AiAssistantInitial).activeStyle
          : 'Orbit',
    ));
  }

  void _onBoardStyleSelected(
    BoardStyleSelected event,
    Emitter<AiAssistantState> emit,
  ) {
    emit(AiAssistantInitial(
      activeCategory: state is AiAssistantInitial
          ? (state as AiAssistantInitial).activeCategory
          : 'All',
      activeStyle: event.style,
    ));
  }

  Future<void> _onAssistantPromptSubmitted(
    AssistantPromptSubmitted event,
    Emitter<AiAssistantState> emit,
  ) async {
    final curCat = state is AiAssistantInitial
        ? (state as AiAssistantInitial).activeCategory
        : 'All';
    final curStyle = state is AiAssistantInitial
        ? (state as AiAssistantInitial).activeStyle
        : 'Orbit';

    emit(AiAssistantThinking(activeCategory: curCat, activeStyle: curStyle));
    await Future.delayed(const Duration(seconds: 1));
    emit(AiAssistantSuccess(
      message: 'Analyzed board! Suggested prioritizing "Website Redesign" and unblocking "Design System Documentation".',
      activeCategory: curCat,
      activeStyle: curStyle,
    ));
  }

  Future<void> _onMagicSortTriggered(
    MagicSortTriggered event,
    Emitter<AiAssistantState> emit,
  ) async {
    final curCat = state is AiAssistantInitial
        ? (state as AiAssistantInitial).activeCategory
        : 'All';
    final curStyle = state is AiAssistantInitial
        ? (state as AiAssistantInitial).activeStyle
        : 'Orbit';

    emit(AiAssistantThinking(activeCategory: curCat, activeStyle: curStyle));
    await Future.delayed(const Duration(milliseconds: 800));
    emit(AiAssistantSuccess(
      message: '✨ Magic Sort applied! Tasks ordered by urgency, due date, and team capacity.',
      activeCategory: curCat,
      activeStyle: curStyle,
    ));
  }
}
