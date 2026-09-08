import 'package:flutter_test/flutter_test.dart';

import 'package:game/main.dart';

void main() {
  testWidgets('home page renders and starts a game', (tester) async {
    await tester.pumpWidget(const EmojiTicTacToe());
    await tester.pumpAndSettle();

    expect(find.text('PLAY ▶'), findsOneWidget);
    expect(find.text('EMOJI\nTIC·TAC·TOE'), findsOneWidget);
    expect(find.text('choose mode'), findsOneWidget);
  });

  testWidgets('mode picker switches to vs ai hard', (tester) async {
    await tester.pumpWidget(const EmojiTicTacToe());
    await tester.pumpAndSettle();

    await tester.tap(find.text('VS AI · HARD'));
    await tester.pump();
    await tester.tap(find.text('PLAY ▶'));
    await tester.pumpAndSettle();

    expect(find.text('PICK YOUR FIGHTERS'), findsOneWidget);
  });
}