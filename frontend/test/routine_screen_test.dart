import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autism_learning_assistant/models/routine_item.dart';
import 'package:autism_learning_assistant/screens/routine_screen.dart';

Future<void> _pumpRoutine(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: RoutineScreen()));
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  test('RoutineItem.defaultSchedule returns 8 items in correct order', () {
    final items = List<RoutineItem>.from(RoutineItem.defaultSchedule())
      ..sort((a, b) => a.order.compareTo(b.order));

    expect(items.length, 8);

    final titles = items.map((i) => i.title).toList();
    expect(titles, [
      'Wake Up',
      'Brush Teeth',
      'Breakfast',
      'School',
      'Learning',
      'Play',
      'Dinner',
      'Sleep',
    ]);
  });

  test('RoutineItem.toggled flips isCompleted', () {
    const item = RoutineItem(
      id: 'test',
      title: 'Test',
      icon: '🔵',
      time: '9:00 AM',
      order: 0,
      color: Color(0xFF81C784),
    );
    expect(item.isCompleted, false);

    final toggled = item.toggled();
    expect(toggled.isCompleted, true);
    expect(toggled.title, 'Test');
  });

  test('RoutineItem.copyWith preserves fields', () {
    const item = RoutineItem(
      id: 'wake_up',
      title: 'Wake Up',
      icon: '☀️',
      time: '7:00 AM',
      order: 0,
      color: Color(0xFFFFB74D),
    );
    final copy = item.copyWith(title: 'Rise and Shine');
    expect(copy.title, 'Rise and Shine');
    expect(copy.id, 'wake_up');
    expect(copy.time, '7:00 AM');
  });

  testWidgets('screen shows all 8 routine items', (tester) async {
    await _pumpRoutine(tester);

    expect(find.text('My Day'), findsOneWidget);

    for (final title in [
      'Wake Up',
      'Brush Teeth',
      'Breakfast',
      'School',
      'Learning',
      'Play',
      'Dinner',
      'Sleep',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('progress badge shows 0/8 initially', (tester) async {
    await _pumpRoutine(tester);

    expect(find.text('0 / 8'), findsOneWidget);
  });

  testWidgets('tapping a routine item toggles its completed state', (
    tester,
  ) async {
    await _pumpRoutine(tester);

    // Progress shows 0/8 initially.
    expect(find.text('0 / 8'), findsOneWidget);

    // Tap "Wake Up".
    await tester.tap(find.text('Wake Up'));
    await tester.pumpAndSettle();

    // Progress updates to 1/8.
    expect(find.text('1 / 8'), findsOneWidget);

    // Tap "Wake Up" again to un-toggle.
    await tester.tap(find.text('Wake Up'));
    await tester.pumpAndSettle();

    // Progress back to 0/8.
    expect(find.text('0 / 8'), findsOneWidget);
  });

  testWidgets('multiple items can be completed', (tester) async {
    await _pumpRoutine(tester);

    await tester.tap(find.text('Wake Up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brush Teeth'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Breakfast'));
    await tester.pumpAndSettle();

    expect(find.text('3 / 8'), findsOneWidget);
  });
}
