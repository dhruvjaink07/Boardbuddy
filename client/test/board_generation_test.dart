import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:boardbuddy/blocs/board_list/board_list_bloc.dart';
import 'package:boardbuddy/core/theme/app_theme.dart';
import 'package:boardbuddy/repositories/board_repository.dart';
import 'package:boardbuddy/screens/create_board/create_board_screen.dart';

void main() {
  group('AI Board Generation Setup & Responsiveness Tests', () {
    late BoardRepository repository;

    setUp(() {
      repository = InMemoryBoardRepository();
    });

    test('BoardRepository generates structured board plan from natural language goal', () async {
      final plan = await repository.generateBoardPlan('Build a mobile banking app with auth and transfers');

      expect(plan.planId, isNotEmpty);
      expect(plan.boardName, contains('Banking'));
      expect(plan.columns.length, greaterThanOrEqualTo(3));
      expect(plan.cards.length, greaterThanOrEqualTo(4));
      expect(plan.cards.first.title, isNotEmpty);
      expect(plan.cards.first.estimateMinutes, greaterThan(0));
    });

    testWidgets('CreateBoardScreen renders without overflow on narrow mobile screen (320px)', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        RepositoryProvider<BoardRepository>.value(
          value: repository,
          child: BlocProvider<BoardListBloc>(
            create: (_) => BoardListBloc(repository: repository),
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const CreateBoardScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow and key elements are rendered
      expect(find.text('Create New Board'), findsOneWidget);
      expect(find.text('AI Goal-to-Board'), findsOneWidget);
      expect(find.text('Generate Plan with AI'), findsOneWidget);
    });

    testWidgets('CreateBoardScreen generates AI plan and displays preview cards without text clipping', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        RepositoryProvider<BoardRepository>.value(
          value: repository,
          child: BlocProvider<BoardListBloc>(
            create: (_) => BoardListBloc(repository: repository),
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const CreateBoardScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter prompt
      final promptField = find.byType(TextField).at(1);
      await tester.enterText(promptField, 'Product Launch and Growth Marketing Campaign');
      await tester.pumpAndSettle();

      // Tap Generate Plan with AI
      final generateBtn = find.text('Generate Plan with AI');
      await tester.tap(generateBtn);
      await tester.pump(); // Start generating

      // Verify thinking / loading state
      expect(find.text('Structuring Kanban Board...'), findsOneWidget);

      await tester.pumpAndSettle(); // Finish generating

      // Verify AI Planned badge and preview columns appear
      expect(find.text('AI Planned'), findsOneWidget);
      expect(find.text('Create & Save Board'), findsOneWidget);
    });
  });
}
