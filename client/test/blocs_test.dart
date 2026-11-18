import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boardbuddy/blocs/ai_assistant/ai_assistant_bloc.dart';
import 'package:boardbuddy/blocs/ai_assistant/ai_assistant_event.dart';
import 'package:boardbuddy/blocs/ai_assistant/ai_assistant_state.dart';
import 'package:boardbuddy/blocs/auth/auth_bloc.dart';
import 'package:boardbuddy/blocs/auth/auth_event.dart';
import 'package:boardbuddy/blocs/auth/auth_state.dart';
import 'package:boardbuddy/blocs/board_detail/board_detail_bloc.dart';
import 'package:boardbuddy/blocs/board_detail/board_detail_event.dart';
import 'package:boardbuddy/blocs/board_detail/board_detail_state.dart';
import 'package:boardbuddy/blocs/board_list/board_list_bloc.dart';
import 'package:boardbuddy/blocs/board_list/board_list_event.dart';
import 'package:boardbuddy/blocs/board_list/board_list_state.dart';
import 'package:boardbuddy/repositories/board_repository.dart';
import 'package:boardbuddy/repositories/mock_data.dart';

void main() {
  group('AuthBloc Tests', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc();
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when LoginSubmitted succeeds',
      build: () => AuthBloc(),
      act: (bloc) => bloc.add(const LoginSubmitted(
        email: 'dhruv@boardbuddy.app',
        password: 'password123',
      )),
      wait: const Duration(milliseconds: 700),
      expect: () => [
        const AuthLoading(),
        const Authenticated(MockData.currentUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] when LogoutRequested is added',
      build: () => AuthBloc(),
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [
        const Unauthenticated(),
      ],
    );
  });

  group('BoardListBloc Tests', () {
    late InMemoryBoardRepository repository;

    setUp(() {
      repository = InMemoryBoardRepository();
    });

    blocTest<BoardListBloc, BoardListState>(
      'emits [BoardListLoading, BoardListLoaded] on BoardListRequested',
      build: () => BoardListBloc(repository: repository),
      act: (bloc) => bloc.add(const BoardListRequested(filter: 'all')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const BoardListLoading(),
        isA<BoardListLoaded>().having(
          (s) => s.boards.isNotEmpty,
          'has boards',
          true,
        ),
      ],
    );

    blocTest<BoardListBloc, BoardListState>(
      'filters boards correctly on BoardFilterChanged',
      build: () => BoardListBloc(repository: repository),
      act: (bloc) => bloc.add(const BoardFilterChanged('favorites')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const BoardListLoading(),
        isA<BoardListLoaded>().having(
          (s) => s.activeFilter,
          'activeFilter',
          'favorites',
        ),
      ],
    );
  });

  group('BoardDetailBloc Tests', () {
    late InMemoryBoardRepository repository;

    setUp(() {
      repository = InMemoryBoardRepository();
    });

    blocTest<BoardDetailBloc, BoardDetailState>(
      'loads board details and column items',
      build: () => BoardDetailBloc(repository: repository),
      act: (bloc) => bloc.add(const LoadBoardDetail('board-1')),
      wait: const Duration(milliseconds: 300),
      expect: () => [
        const BoardDetailLoading(),
        isA<BoardDetailLoaded>().having(
          (s) => s.board.name,
          'name',
          'Product Launch 2024',
        ),
      ],
    );
  });

  group('AiAssistantBloc Tests', () {
    blocTest<AiAssistantBloc, AiAssistantState>(
      'updates active category on FilterChipSelected',
      build: () => AiAssistantBloc(),
      act: (bloc) => bloc.add(const FilterChipSelected('Work')),
      expect: () => [
        const AiAssistantInitial(activeCategory: 'Work', activeStyle: 'Orbit'),
      ],
    );

    blocTest<AiAssistantBloc, AiAssistantState>(
      'updates active style on BoardStyleSelected',
      build: () => AiAssistantBloc(),
      act: (bloc) => bloc.add(const BoardStyleSelected('Fluid')),
      expect: () => [
        const AiAssistantInitial(activeCategory: 'All', activeStyle: 'Fluid'),
      ],
    );

    blocTest<AiAssistantBloc, AiAssistantState>(
      'emits [AiAssistantThinking, AiAssistantSuccess] on MagicSortTriggered',
      build: () => AiAssistantBloc(),
      act: (bloc) => bloc.add(const MagicSortTriggered()),
      wait: const Duration(milliseconds: 900),
      expect: () => [
        const AiAssistantThinking(activeCategory: 'All', activeStyle: 'Orbit'),
        isA<AiAssistantSuccess>().having(
          (s) => s.message.contains('Magic Sort applied'),
          'message',
          true,
        ),
      ],
    );
  });
}
