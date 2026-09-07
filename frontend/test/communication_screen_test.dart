import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autism_learning_assistant/models/communication_card.dart';
import 'package:autism_learning_assistant/screens/communication_screen.dart';

Future<void> _pumpCommunication(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: CommunicationScreen()));
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  test('CommunicationCard.defaultCards returns all 11 required cards', () {
    final cards = CommunicationCard.defaultCards();
    expect(cards.length, 11);

    final labels = cards.map((c) => c.label).toSet();
    expect(
      labels,
      containsAll([
        'Food',
        'Drink',
        'Bathroom',
        'Help',
        'Yes',
        'No',
        'Happy',
        'Sad',
        'Tired',
        'More',
        'Stop',
      ]),
    );
  });

  test('CommunicationCard spokenText falls back to label', () {
    const card = CommunicationCard(id: 'test', label: 'Test', symbol: '🔵');
    expect(card.spokenText, 'Test');
  });

  test('CommunicationCard spokenText uses speechPhrase when provided', () {
    const card = CommunicationCard(
      id: 'food',
      label: 'Food',
      symbol: '🍔',
      speechPhrase: 'I want food, please.',
    );
    expect(card.spokenText, 'I want food, please.');
  });

  testWidgets('screen loads with all communication cards visible', (
    tester,
  ) async {
    await _pumpCommunication(tester);

    expect(find.text('Communicate'), findsOneWidget);
    expect(find.text('Tap a card to say something'), findsOneWidget);

    // All 11 card labels should be present.
    for (final label in [
      'Food',
      'Drink',
      'Bathroom',
      'Help',
      'Yes',
      'No',
      'Happy',
      'Sad',
      'Tired',
      'More',
      'Stop',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('tapping a card adds it to the sentence bar', (tester) async {
    await _pumpCommunication(tester);

    // Tap the "Food" card.
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // The card label should now appear as a Chip in the sentence bar.
    expect(find.byType(Chip), findsOneWidget);
  });

  testWidgets('Clear button removes all selected cards', (tester) async {
    await _pumpCommunication(tester);

    // Tap a card.
    await tester.tap(find.text('Happy'));
    await tester.pumpAndSettle();
    expect(find.byType(Chip), findsOneWidget);

    // Tap Clear.
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    // Sentence bar shows the placeholder again.
    expect(find.text('Tap a card to say something'), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
  });

  testWidgets('Say It button shows snackbar and clears selection', (
    tester,
  ) async {
    await _pumpCommunication(tester);

    // Tap a card then "Say It".
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Say It'));
    await tester.pumpAndSettle();

    // A SnackBar should appear with the spoken phrase.
    expect(find.byType(SnackBar), findsOneWidget);

    // Selection should be cleared after speaking.
    expect(find.text('Tap a card to say something'), findsOneWidget);
  });

  testWidgets('tapping a selected card removes it from selection', (
    tester,
  ) async {
    await _pumpCommunication(tester);

    // The card label is always the LAST "Yes" Text (sentence bar Chips
    // are rendered above the grid).  Use .last for a stable reference.
    final yesCard = find.text('Yes').last;

    // Select "Yes".
    await tester.tap(yesCard);
    await tester.pumpAndSettle();
    expect(find.byType(Chip), findsOneWidget);

    // Tap "Yes" card again to deselect.
    await tester.tap(yesCard);
    await tester.pumpAndSettle();
    expect(find.byType(Chip), findsNothing);
  });
}
