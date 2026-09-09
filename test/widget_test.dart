import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toemoji/main.dart';

void main() {
  testWidgets('home shows custom game and opens setup', (tester) async {
    await tester.pumpWidget(const ToEmoji());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.store_outlined), findsOneWidget);
    expect(find.text('🎮 CUSTOM GAME'), findsOneWidget);
    expect(find.textContaining('ONLINE PVP'), findsNothing);

    await tester.tap(find.text('🎮 CUSTOM GAME'));
    await tester.pumpAndSettle();

    expect(find.text('CUSTOM GAME'), findsOneWidget);
    expect(find.text('choose mode'), findsOneWidget);
    expect(find.text('2 PLAYER'), findsOneWidget);
    expect(find.text('VS AI · EASY'), findsOneWidget);
    expect(find.text('VS AI · HARD'), findsOneWidget);
    expect(find.text('⏱ BLITZ CLOCK'), findsOneWidget);
    expect(find.text('⚔ RANKED'), findsOneWidget);

    await tester.ensureVisible(find.text('VS AI · HARD'));
    await tester.pump();
    await tester.tap(find.text('VS AI · HARD'));
    await tester.pump();

    await tester.ensureVisible(find.text('NEXT → PICK FIGHTERS'));
    await tester.pump();
    await tester.tap(find.text('NEXT → PICK FIGHTERS'));
    await tester.pumpAndSettle();

    expect(find.text('PICK YOUR FIGHTERS'), findsOneWidget);
  });

  testWidgets('emoji pick and game render without overflow', (tester) async {
    await tester.pumpWidget(const ToEmoji());
    await tester.pumpAndSettle();

    await tester.tap(find.text('🎮 CUSTOM GAME'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('NEXT → PICK FIGHTERS'));
    await tester.pump();
    await tester.tap(find.text('NEXT → PICK FIGHTERS'));
    await tester.pumpAndSettle();

    expect(find.text('PICK YOUR FIGHTERS'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('2 PLAYER'));
    await tester.pump();
    await tester.tap(find.text('2 PLAYER'));
    await tester.pumpAndSettle();

    expect(find.text('NEW GAME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('store renders without overflow on narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ToEmoji());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.store_outlined));
    await tester.pumpAndSettle();

    expect(find.text('EMOJI STORE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('game over dialog renders without overflow on narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ToEmoji());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('🎮 CUSTOM GAME'));
    await tester.pump();
    await tester.tap(find.text('🎮 CUSTOM GAME'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('NEXT → PICK FIGHTERS'));
    await tester.pump();
    await tester.tap(find.text('NEXT → PICK FIGHTERS'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('2 PLAYER'));
    await tester.pump();
    await tester.tap(find.text('2 PLAYER'));
    await tester.pumpAndSettle();

    Future<void> play(int i) async {
      final cell = _cellFinder(i);
      await tester.ensureVisible(cell);
      await tester.pump();
      await tester.tap(cell);
      await tester.pump();
    }

    // P1 wins on the diagonal: cells 0, 4, 8 (P2 blocks on 1 and 2).
    await play(0);
    await play(1);
    await play(4);
    await play(2);
    await play(8);

    expect(find.text('REMATCH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shows daily quests and custom game entry', (tester) async {
    await tester.pumpWidget(const ToEmoji());
    await tester.pumpAndSettle();

    expect(find.text('DAILY QUESTS'), findsOneWidget);
    expect(find.text('WIN 3 MATCHES'), findsOneWidget);
    expect(find.text('PLAY 5 MATCHES'), findsOneWidget);
    expect(find.text('HIT A 3-WIN STREAK'), findsOneWidget);
    expect(find.text('🎮 CUSTOM GAME'), findsOneWidget);
    // Online PvP entry is only shown when signed in.
    expect(find.textContaining('ONLINE PVP'), findsNothing);

    await tester.tap(find.text('🎮 CUSTOM GAME'));
    await tester.pumpAndSettle();

    expect(find.text('⏱ BLITZ CLOCK'), findsOneWidget);
    expect(find.text('⚔ RANKED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('store shows boards, frames and fighters without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ToEmoji());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.store_outlined));
    await tester.pumpAndSettle();

    expect(find.text('EMOJI STORE'), findsOneWidget);
    expect(find.text('BACKGROUNDS'), findsOneWidget);

    await tester.ensureVisible(find.text('FRAMES'));
    await tester.pump();
    expect(find.text('FRAMES'), findsOneWidget);

    await tester.ensureVisible(find.text('FIGHTERS'));
    await tester.pump();
    expect(find.text('FIGHTERS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Finder _cellFinder(int i) {
  return find.byKey(ValueKey('cell-$i'));
}