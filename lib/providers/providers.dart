import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/dates.dart';
import '../data/app_database.dart';
import '../data/event_repository.dart';
import '../data/habit_repository.dart';
import '../domain/habit_stats.dart';
import '../models/calendar_event.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/user_profile_service.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_remote.dart';

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
  /// [completedToday]: ids de hábitos ya hechos hoy (no deben sonar hoy).
  Future<void> reschedule(List<Habit> activeHabits, {Set<String> completedToday = const {}});
}

class NotificationReminderScheduler implements ReminderScheduler {
  @override
  Future<void> reschedule(List<Habit> activeHabits, {Set<String> completedToday = const {}}) =>
      NotificationService().syncHabitReminders(activeHabits, completedToday: completedToday);
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => NotificationReminderScheduler(),
);

// ---------------------------------------------------------------------------
// Cuenta y nube (opcionales: `null` si Supabase no está configurado)
// ---------------------------------------------------------------------------

final authServiceProvider = Provider<AuthService?>((ref) => null);

final syncRemoteProvider = Provider<SyncRemote?>((ref) => null);

/// Usuario con sesión iniciada, o `null` si se usa la app sin cuenta.
final authUserProvider = StreamProvider<AuthUser?>((ref) async* {
  final auth = ref.watch(authServiceProvider);
  yield auth?.currentUser;
  if (auth != null) yield* auth.userChanges;
});

class SyncState {
  final bool syncing;
  final DateTime? lastSyncedAt;

  /// Mensaje del último error, `null` si la última sincronización fue bien.
  final String? error;

  const SyncState({this.syncing = false, this.lastSyncedAt, this.error});
}

class SyncController extends Notifier<SyncState> {
  static const _debounce = Duration(seconds: 2);

  Timer? _timer;
  bool _running = false;
  bool _runAgain = false;

  @override
  SyncState build() {
    ref.onDispose(() => _timer?.cancel());
    // Al iniciar sesión (o al abrir la app con sesión) se sincroniza.
    ref.listen(authUserProvider, (previous, next) {
      final user = next.value;
      if (user != null && previous?.value?.id != user.id) syncNow();
    }, fireImmediately: true);
    return const SyncState();
  }

  String? get _userId => ref.read(authUserProvider).value?.id;

  /// Sincroniza en unos segundos (agrupa varios cambios seguidos).
  void schedule() {
    if (_userId == null) return;
    _timer?.cancel();
    _timer = Timer(_debounce, syncNow);
  }

  Future<void> syncNow() async {
    final userId = _userId;
    final remote = ref.read(syncRemoteProvider);
    if (userId == null || remote == null) return;
    if (_running) {
      _runAgain = true;
      return;
    }
    _running = true;
    state = SyncState(syncing: true, lastSyncedAt: state.lastSyncedAt);
    try {
      final engine = SyncEngine(
        ref.read(databaseProvider),
        remote,
        ref.read(userProfileServiceProvider),
      );
      if (await engine.sync(userId)) await _reloadLocalData();
      state = SyncState(lastSyncedAt: ref.read(clockProvider)());
    } catch (e) {
      debugPrint('Error al sincronizar: $e');
      state = SyncState(
        lastSyncedAt: state.lastSyncedAt,
        error: 'No se pudo sincronizar. Se reintentará con conexión.',
      );
    } finally {
      _running = false;
      if (_runAgain) {
        _runAgain = false;
        schedule();
      }
    }
  }

  Future<void> _reloadLocalData() async {
    await ref.read(habitsProvider.notifier).reload();
    await ref.read(eventsProvider.notifier).reload();
    ref.invalidate(profileProvider);
  }

  /// Cierra sesión. Antes intenta subir lo pendiente. Con [wipeLocalData]
  /// borra además los datos del teléfono (quedan en la nube).
  Future<void> signOut({required bool wipeLocalData}) async {
    await syncNow();
    if (wipeLocalData && state.error != null) {
      // Borrar sin haber subido lo pendiente perdería datos.
      throw const AuthFailure(
        'No se pudieron subir los últimos cambios. Conéctate a internet e inténtalo de nuevo.',
      );
    }
    await ref.read(authServiceProvider)?.signOut();
    if (!wipeLocalData) return;
    final profiles = ref.read(userProfileServiceProvider);
    final imagePath = (await profiles.getProfile())?.profileImagePath;
    if (imagePath != null) await profiles.deleteProfileImage(imagePath);
    await profiles.clearProfile();
    await ref.read(databaseProvider).clearAll();
    await SyncEngine.forgetUser(await SharedPreferences.getInstance());
    await _reloadLocalData();
  }
}

final syncProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);

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
    final next = _queue.then((_) => operation()).then((_) => _scheduleSync());
    _queue = next.catchError((Object _) {});
    return next;
  }

  void _scheduleSync() => ref.read(syncProvider.notifier).schedule();

  /// Vuelve a leer la base (tras bajar cambios de la nube).
  Future<void> reload() {
    final next = _queue.then((_) async {
      state = AsyncData(await _repo.load());
      await syncReminders();
    });
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> _apply(HabitData Function(HabitData current) change) async {
    final current = await future;
    state = AsyncData(change(current));
  }

  /// Reprograma los recordatorios según el estado actual (también se llama al
  /// abrir la app y al volver a ella).
  Future<void> syncReminders() async {
    final data = await future;
    final today = ref.read(todayProvider);
    final active = data.activeHabits;
    try {
      await ref.read(reminderSchedulerProvider).reschedule(
            active,
            completedToday: {for (final h in active) if (data.isDone(h.id, today)) h.id},
          );
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
        await syncReminders();
      });

  Future<void> updateHabit(Habit habit) => _serial(() async {
        await _repo.saveHabit(habit);
        await _apply((d) => d.copyWith(
              habits: [for (final h in d.habits) h.id == habit.id ? habit : h],
            ));
        await syncReminders();
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
        await syncReminders();
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
        await syncReminders();
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
    ref.read(syncProvider.notifier).schedule();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = AsyncData([for (final e in await future) if (e.id != id) e]);
    ref.read(syncProvider.notifier).schedule();
  }

  Future<void> reload() async => state = AsyncData(await _repo.all());
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
    ref.read(syncProvider.notifier).schedule();
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(ProfileController.new);
