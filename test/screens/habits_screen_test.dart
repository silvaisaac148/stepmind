import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepmind/models/habit.dart';
import 'package:stepmind/providers/providers.dart';
import 'package:stepmind/screens/habits_screen.dart';

import '../providers/habits_controller_test.dart';

void main() {
  testWidgets('marcar un hábito actualiza el resumen y la racha', (tester) async {
    final repo = InMemoryHabitRepository();
    await repo.saveHabit(Habit(
      id: 'h1',
      name: 'Beber agua',
      time: const TimeOfDay(hour: 8, minute: 0),
      createdAt: DateTime(2026, 3, 1),
    ));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        habitRepositoryProvider.overrideWithValue(repo),
        reminderSchedulerProvider.overrideWithValue(FakeScheduler()),
        clockProvider.overrideWithValue(() => DateTime(2026, 3, 10, 9)),
      ],
      child: const MaterialApp(home: HabitsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Beber agua'), findsOneWidget);
    expect(find.text('Racha: 0 días'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(find.text('Racha: 1 día'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });
}
