import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepmind/data/habit_repository.dart';
import 'package:stepmind/domain/habit_stats.dart';
import 'package:stepmind/models/habit.dart';
import 'package:stepmind/providers/providers.dart';

class InMemoryHabitRepository implements HabitRepository {
  final habits = <String, Habit>{};
  final checkins = <String, Set<String>>{};

  @override
  Future<HabitData> load() async => HabitData(
        habits: habits.values.toList(),
        checkins: {for (final e in checkins.entries) e.key: {...e.value}},
      );

  @override
  Future<void> saveHabit(Habit habit) async => habits[habit.id] = habit;

  @override
  Future<void> setCheckin(String habitId, String day, {required bool done}) async {
    // Simula latencia para que las escrituras puedan solaparse.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final set = checkins.putIfAbsent(habitId, () => {});
    done ? set.add(day) : set.remove(day);
  }
}

class FakeScheduler implements ReminderScheduler {
  final calls = <List<Habit>>[];
  final completedCalls = <Set<String>>[];

  @override
  Future<void> reschedule(List<Habit> activeHabits, {Set<String> completedToday = const {}}) async {
    calls.add(activeHabits);
    completedCalls.add(completedToday);
  }
}

void main() {
  late InMemoryHabitRepository repo;
  late FakeScheduler scheduler;
  late ProviderContainer container;
  final now = DateTime(2026, 3, 10, 9, 30);

  setUp(() {
    repo = InMemoryHabitRepository();
    scheduler = FakeScheduler();
    container = ProviderContainer(overrides: [
      habitRepositoryProvider.overrideWithValue(repo),
      reminderSchedulerProvider.overrideWithValue(scheduler),
      clockProvider.overrideWithValue(() => now),
    ]);
  });

  tearDown(() => container.dispose());

  HabitsController controller() => container.read(habitsProvider.notifier);

  test('agregar un hábito lo guarda y reprograma recordatorios', () async {
    await container.read(habitsProvider.future);
    await controller().addHabit('  Leer  ', const TimeOfDay(hour: 21, minute: 0));

    final data = container.read(habitsProvider).requireValue;
    expect(data.activeHabits.single.name, 'Leer');
    expect(repo.habits, hasLength(1));
    expect(scheduler.calls.last, hasLength(1));
  });

  test('marcar y desmarcar hoy', () async {
    await container.read(habitsProvider.future);
    await controller().addHabit('Agua', const TimeOfDay(hour: 8, minute: 0));
    final id = container.read(habitsProvider).requireValue.habits.single.id;

    await controller().toggleToday(id);
    expect(container.read(habitsProvider).requireValue.daysFor(id), {'2026-03-10'});
    expect(container.read(statsProvider).requireValue.completedToday, 1);

    await controller().toggleToday(id);
    expect(container.read(habitsProvider).requireValue.daysFor(id), isEmpty);
    expect(repo.checkins[id], isEmpty);
  });

  test('marcar hoy reprograma: el hábito hecho no suena hoy', () async {
    await container.read(habitsProvider.future);
    await controller().addHabit('Agua', const TimeOfDay(hour: 8, minute: 0));
    final id = container.read(habitsProvider).requireValue.habits.single.id;

    await controller().toggleToday(id);
    expect(scheduler.completedCalls.last, {id});

    await controller().toggleToday(id);
    expect(scheduler.completedCalls.last, isEmpty);
  });

  test('toques rápidos no se pisan entre sí', () async {
    await container.read(habitsProvider.future);
    await controller().addHabit('A', const TimeOfDay(hour: 8, minute: 0));
    await controller().addHabit('B', const TimeOfDay(hour: 9, minute: 0));
    final ids = container.read(habitsProvider).requireValue.habits.map((h) => h.id).toList();

    // Sin esperar entre llamadas.
    await Future.wait([
      controller().toggleToday(ids[0]),
      controller().toggleToday(ids[1]),
      controller().toggleToday(ids[0]),
    ]);

    final data = container.read(habitsProvider).requireValue;
    expect(data.isDone(ids[0], now), isFalse);
    expect(data.isDone(ids[1], now), isTrue);
    expect(repo.checkins[ids[0]], isEmpty);
    expect(repo.checkins[ids[1]], {'2026-03-10'});
  });

  test('archivar conserva el historial y quita el recordatorio', () async {
    await container.read(habitsProvider.future);
    await controller().addHabit('A', const TimeOfDay(hour: 8, minute: 0));
    final id = container.read(habitsProvider).requireValue.habits.single.id;
    await controller().toggleToday(id);

    await controller().archiveHabit(id);

    final data = container.read(habitsProvider).requireValue;
    expect(data.activeHabits, isEmpty);
    expect(data.habits.single.isArchived, isTrue);
    expect(data.daysFor(id), {'2026-03-10'});
    expect(scheduler.calls.last, isEmpty);
  });

  test('editar cambia nombre y hora', () async {
    await container.read(habitsProvider.future);
    await controller().addHabit('A', const TimeOfDay(hour: 8, minute: 0));
    final habit = container.read(habitsProvider).requireValue.habits.single;

    await controller().updateHabit(
      habit.copyWith(name: 'B', time: const TimeOfDay(hour: 7, minute: 15)),
    );

    final updated = container.read(habitsProvider).requireValue.habits.single;
    expect(updated.name, 'B');
    expect(updated.formattedTime, '07:15');
    expect(repo.habits[habit.id]!.name, 'B');
  });
}
