import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boardbuddy/repositories/board_repository.dart';
import 'package:boardbuddy/screens/board/draggable_board_insights_sheet.dart';

void main() {
  group('Deerflow Insights Tests', () {
    late BoardRepository repository;

    setUp(() {
      repository = InMemoryBoardRepository();
    });

    test('BoardRepository returns valid Deerflow insights report', () async {
      final insights = await repository.getBoardInsights('board-1');

      expect(insights.boardId, 'board-1');
      expect(insights.summary.isNotEmpty, true);
      expect(insights.findings.length, greaterThanOrEqualTo(2));
      expect(insights.recommendations.length, greaterThanOrEqualTo(1));
      expect(insights.sources.isNotEmpty, true);
      expect(insights.isFallback, false);
      expect(insights.totalTasks, greaterThanOrEqualTo(1));
    });

    testWidgets('DraggableBoardInsightsSheet renders drag handle and sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraggableBoardInsightsSheet(
              boardId: 'board-1',
              repository: repository,
            ),
          ),
        ),
      );

      // Loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Finish async load
      await tester.pumpAndSettle();

      // Verify title & badges
      expect(find.text('Deerflow Insights'), findsOneWidget);
      expect(find.text('ORIGINAL'), findsOneWidget);
      expect(find.text('Executive Strategy'), findsOneWidget);

      // Drag the sheet upwards to expand full height
      await tester.drag(find.text('Deerflow Insights'), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Key Findings & Bottlenecks'), findsOneWidget);
    });
  });
}
