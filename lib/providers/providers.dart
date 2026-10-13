import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/dates.dart';
import '../data/app_database.dart';
import '../data/event_repository.dart';
import '../data/habit_repository.dart';
import '../domain/habit_stats.dart';
import '../models/calendar_event.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';
import '../services/user_profile_service.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Infraestructura (se sobreescribe en main() y en los tests)
// ---------------------------------------------------------------------------

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider debe sobreescribirse en main()'),
);

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => SqliteHabitRepository(ref.watch(databaseProvider)),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => SqliteEventRepository(ref.watch(databaseProvider)),
);

final userProfileServiceProvider = Provider((ref) => UserProfileService());

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Programa los recordatorios de los hábitos activos.
abstract class ReminderScheduler {
  Future<void> reschedule(List<Habit> activeHabits);
}

class NotificationReminderScheduler implements ReminderScheduler {
  @override
  Future<void> reschedule(List<Habit> activeHabits) =>
      NotificationService().scheduleHabitNotifications(activeHabits);
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => NotificationReminderScheduler(),
);

// ---------------------------------------------------------------------------
// Día actual: se actualiza a medianoche y al volver a la app.
// ---------------------------------------------------------------------------

class TodayNotifier extends Notifier<DateTime> {
  Timer? _midnightTimer;

  @override
  DateTime build() {
    ref.onDispose(() => _midnightTimer?.cancel());
    final now = ref.watch(clockProvider)();
    _scheduleMidnight(now);
    return dateOnly(now);
  }

  void _scheduleMidnight(DateTime now) {
    _midnightTimer?.cancel();
    final untilMidnight = addDays(now, 1).difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(untilMidnight, refresh);
  }

  void refresh() {
    final now = ref.read(clockProvider)();
    _scheduleMidnight(now);
    if (!isSameDay(now, state)) state = dateOnly(now);
  }
}

final todayProvider = NotifierProvider<TodayNotifier, DateTime>(TodayNotifier.new);

// ---------------------------------------------------------------------------
// Hábitos
// ---------------------------------------------------------------------------

class HabitsController extends AsyncNotifier<HabitData> {
  /// Las escrituras se encadenan para que dos toques rápidos no se pisen.
  Future<void> _queue = Future.value();

  HabitRepository get _repo => ref.read(habitRepositoryProvider);

  @override
  Future<HabitData> build() => ref.watch(habitRepositoryProvider).load();

  Future<void> _serial(Future<void> Function() operation) {
    final next = _queue.then((_) => operation());
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> _apply(HabitData Function(HabitData current) change) async {
    final current = await future;
    state = AsyncData(change(current));
  }

  Future<void> _syncReminders() async {
    final data = await future;
    try {
      await ref.read(reminderSchedulerProvider).reschedule(data.activeHabits);
    } catch (e) {
      debugPrint('No se pudieron reprogramar los recordatorios: $e');
    }
  }

  Future<void> addHabit(String name, TimeOfDay time) => _serial(() async {
        final habit = Habit(
          id: _uuid.v4(),
          name: name.trim(),
          time: time,
          createdAt: ref.read(clockProvider)(),
        );
        await _repo.saveHabit(habit);
        await _apply((d) => d.copyWith(habits: [...d.habits, habit]));
        await _syncReminders();
      });

  Future<void> updateHabit(Habit habit) => _serial(() async {
        await _repo.saveHabit(habit);
        await _apply((d) => d.copyWith(
              habits: [for (final h in d.habits) h.id == habit.id ? habit : h],
            ));
        await _syncReminders();
      });

  /// Elimina el hábito de la lista conservando su historial.
  Future<void> archiveHabit(String habitId) => _serial(() async {
        final current = await future;
        final habit = current.habits.firstWhere((h) => h.id == habitId);
        final archived = habit.copyWith(archivedAt: ref.read(clockProvider)());
        await _repo.saveHabit(archived);
        await _apply((d) => d.copyWith(
              habits: [for (final h in d.habits) h.id == habitId ? archived : h],
            ));
        await _syncReminders();
      });

  Future<void> toggleToday(String habitId) => _serial(() async {
        // Refresca "hoy" por si la app quedó abierta pasada la medianoche.
        ref.read(todayProvider.notifier).refresh();
        final day = dayKey(ref.read(todayProvider));
        final current = await future;
        final done = !current.daysFor(habitId).contains(day);
        await _repo.setCheckin(habitId, day, done: done);
        await _apply((d) {
          final days = {...d.daysFor(habitId)};
          done ? days.add(day) : days.remove(day);
          return d.copyWith(checkins: {...d.checkins, habitId: days});
        });
      });
}

final habitsProvider = AsyncNotifierProvider<HabitsController, HabitData>(HabitsController.new);

final statsProvider = Provider<AsyncValue<OverallStats>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(habitsProvider).whenData((data) => OverallStats.compute(data, today));
});

// ---------------------------------------------------------------------------
// Eventos del calendario
// ---------------------------------------------------------------------------

class EventsController extends AsyncNotifier<List<CalendarEvent>> {
  EventRepository get _repo => ref.read(eventRepositoryProvider);

  @override
  Future<List<CalendarEvent>> build() => ref.watch(eventRepositoryProvider).all();

  Future<void> add(DateTime day, String title) async {
    final event = CalendarEvent(id: _uuid.v4(), day: dayKey(day), title: title.trim());
    await _repo.add(event);
    state = AsyncData([...await future, event]);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = AsyncData([for (final e in await future) if (e.id != id) e]);
  }
}

final eventsProvider =
    AsyncNotifierProvider<EventsController, List<CalendarEvent>>(EventsController.new);

// ---------------------------------------------------------------------------
// Perfil
// ---------------------------------------------------------------------------

class ProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() => ref.watch(userProfileServiceProvider).getProfile();

  Future<void> save(UserProfile profile) async {
    await ref.read(userProfileServiceProvider).saveProfile(profile);
    state = AsyncData(profile);
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(ProfileController.new);
