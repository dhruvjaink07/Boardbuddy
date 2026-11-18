import 'package:flutter_test/flutter_test.dart';
import 'package:boardbuddy/main.dart';
import 'package:boardbuddy/repositories/board_repository.dart';

void main() {
  testWidgets('BoardBuddyApp smoke test', (WidgetTester tester) async {
    final repository = InMemoryBoardRepository();
    await tester.pumpWidget(BoardBuddyApp(boardRepository: repository));

    // Verify WelcomeScreen renders 'BoardBuddy' and 'Get Started'
    expect(find.text('BoardBuddy'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
