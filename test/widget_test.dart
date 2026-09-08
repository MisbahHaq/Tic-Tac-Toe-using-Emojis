import 'package:flutter_test/flutter_test.dart';

import 'package:game/main.dart';

void main() {
  testWidgets('Renders the onboarding page', (WidgetTester tester) async {
    await tester.pumpWidget(const EmojiTicTacToe());

    // Let the start-game delayed timers and entrance animations settle.
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('START GAME'), findsOneWidget);
    expect(find.textContaining('EMOJI'), findsWidgets);
  });
}
