import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepmind/data/recovery_repository.dart';
import 'package:stepmind/domain/recovery.dart';
import 'package:stepmind/providers/providers.dart';
import 'package:stepmind/screens/recovery/recovery_screen.dart';

class InMemoryRecoveryRepository implements RecoveryRepository {
  final goals = <String, RecoveryGoal>{};
  final events = <String, RecoveryEvent>{};

  @override
  Future<RecoveryData> load() async =>
      RecoveryData(goals: goals.values.toList(), events: events.values.toList());

  @override
  Future<void> saveGoal(RecoveryGoal goal) async => goals[goal.id] = goal;

  @override
  Future<void> addEvent(RecoveryEvent event) async => events[event.id] = event;

  @override
  Future<void> deleteEvent(String id) async => events.remove(id);
}

void main() {
  final now = DateTime(2026, 3, 11, 20);

  Future<void> pump(WidgetTester tester, InMemoryRecoveryRepository repo) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      overrides: [
        recoveryRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(() => now),
      ],
      child: const MaterialApp(home: RecoveryScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('sin metas muestra la bienvenida', (tester) async {
    await pump(tester, InMemoryRecoveryRepository());
    expect(find.text('Libérate de lo que te frena'), findsOneWidget);
    expect(find.text('Empezar'), findsOneWidget);
  });

  testWidgets('con una meta muestra la racha y el botón SOS', (tester) async {
    final repo = InMemoryRecoveryRepository();
    await repo.saveGoal(RecoveryGoal(
      id: 'g1',
      name: 'Pornografía',
      startedAt: DateTime(2026, 3, 1, 9),
      createdAt: DateTime(2026, 3, 1, 9),
      why: 'Ser dueño de mi tiempo',
    ));
    await pump(tester, repo);

    // Al abrir se celebra el hito de 7 días alcanzado.
    expect(find.text('¡7 días!'), findsOneWidget);
    await tester.tap(find.text('¡Vamos!'));
    await tester.pumpAndSettle();

    expect(find.text('Pornografía'), findsOneWidget);
    expect(find.text('10 d 11 h'), findsOneWidget);
    expect(find.text('Próximo hito: 14 días'), findsOneWidget);
    expect(find.text('Tengo una urgencia'), findsOneWidget);
    expect(find.text('Ser dueño de mi tiempo'), findsOneWidget);
  });
}
