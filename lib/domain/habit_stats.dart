import '../core/dates.dart';
import '../models/habit.dart';

/// Hábitos (incluidos archivados) y los días en que se completó cada uno.
///
/// Todas las estadísticas se derivan de aquí; no se guardan contadores aparte,
/// así nunca pueden desincronizarse.
class HabitData {
  final List<Habit> habits;

  /// habitId -> conjunto de claves de día (`YYYY-MM-DD`) completadas.
  final Map<String, Set<String>> checkins;

  const HabitData({required this.habits, required this.checkins});

  static const empty = HabitData(habits: [], checkins: {});

  List<Habit> get activeHabits => habits.where((h) => !h.isArchived).toList();

  Set<String> daysFor(String habitId) => checkins[habitId] ?? const {};

  bool isDone(String habitId, DateTime day) => daysFor(habitId).contains(dayKey(day));

  HabitData copyWith({List<Habit>? habits, Map<String, Set<String>>? checkins}) =>
      HabitData(habits: habits ?? this.habits, checkins: checkins ?? this.checkins);
}

enum DayStatus {
  /// Día posterior a hoy.
  future,

  /// No había hábitos activos ese día.
  empty,

  /// Todos los hábitos activos completados.
  perfect,

  /// Algunos completados (en un día ya pasado).
  partial,

  /// Ninguno completado (en un día ya pasado).
  missed,

  /// Hoy, todavía sin completar todos.
  pending,
}

class Achievement {
  final int days;
  final String title;
  final String description;

  const Achievement(this.days, this.title, this.description);
}

const achievements = [
  Achievement(1, '🌟 Primer Día', 'Completar todos los hábitos durante un día'),
  Achievement(7, '🔥 Semana Perfecta', 'Mantener racha de 7 días'),
  Achievement(14, '⭐ Doble Semana', 'Mantener racha de 14 días'),
  Achievement(30, '🏆 Mes Completo', 'Mantener racha de 30 días'),
  Achievement(90, '💎 Trimestre Maestro', 'Mantener racha de 90 días'),
  Achievement(180, '🎯 Semestre Leyenda', 'Mantener racha de 180 días'),
  Achievement(365, '👑 Año de Éxito', 'Mantener racha de 365 días'),
  Achievement(730, '⚡ Doble Año', 'Mantener racha de 730 días'),
  Achievement(1825, '🏅 Quinquenio', 'Mantener racha de 5 años'),
  Achievement(3650, '👑🏆 Década Perfecta', 'Mantener racha de 10 años'),
];

/// Racha de un hábito: días consecutivos completados terminando hoy.
/// Si hoy aún no se ha marcado, la racha que termina ayer sigue viva.
int habitStreak(Set<String> days, DateTime today) {
  var cursor = dateOnly(today);
  if (!days.contains(dayKey(cursor))) cursor = addDays(cursor, -1);
  var streak = 0;
  while (days.contains(dayKey(cursor))) {
    streak++;
    cursor = addDays(cursor, -1);
  }
  return streak;
}

int habitBestStreak(Set<String> days) {
  if (days.isEmpty) return 0;
  final sorted = days.map(parseDayKey).toList()..sort();
  var best = 1;
  var run = 1;
  for (var i = 1; i < sorted.length; i++) {
    run = isSameDay(addDays(sorted[i - 1], 1), sorted[i]) ? run + 1 : 1;
    if (run > best) best = run;
  }
  return best;
}

DayStatus dayStatus(HabitData data, DateTime day, DateTime today) {
  final d = dateOnly(day);
  final t = dateOnly(today);
  if (d.isAfter(t)) return DayStatus.future;

  final active = data.habits.where((h) => h.isActiveOn(d)).toList();
  if (active.isEmpty) return DayStatus.empty;

  final done = active.where((h) => data.isDone(h.id, d)).length;
  if (done == active.length) return DayStatus.perfect;
  if (isSameDay(d, t)) return DayStatus.pending;
  return done == 0 ? DayStatus.missed : DayStatus.partial;
}

/// Fracción (0..1) de hábitos completados ese día, o null si no había activos.
double? completionRatio(HabitData data, DateTime day) {
  final active = data.habits.where((h) => h.isActiveOn(day)).toList();
  if (active.isEmpty) return null;
  final done = active.where((h) => data.isDone(h.id, day)).length;
  return done / active.length;
}

/// Días perfectos consecutivos terminando hoy (o ayer si hoy sigue pendiente).
int currentPerfectStreak(HabitData data, DateTime today) {
  var cursor = dateOnly(today);
  if (dayStatus(data, cursor, today) != DayStatus.perfect) {
    cursor = addDays(cursor, -1);
  }
  var streak = 0;
  while (dayStatus(data, cursor, today) == DayStatus.perfect) {
    streak++;
    cursor = addDays(cursor, -1);
  }
  return streak;
}

DateTime? _firstDay(HabitData data) {
  if (data.habits.isEmpty) return null;
  return data.habits
      .map((h) => dateOnly(h.createdAt))
      .reduce((a, b) => a.isBefore(b) ? a : b);
}

({int best, int total}) _perfectDayRuns(HabitData data, DateTime today) {
  final first = _firstDay(data);
  if (first == null) return (best: 0, total: 0);
  var best = 0;
  var run = 0;
  var total = 0;
  for (var d = first; !d.isAfter(dateOnly(today)); d = addDays(d, 1)) {
    if (dayStatus(data, d, today) == DayStatus.perfect) {
      run++;
      total++;
      if (run > best) best = run;
    } else if (!isSameDay(d, today)) {
      // Hoy todavía pendiente no rompe la racha.
      run = 0;
    }
  }
  return (best: best, total: total);
}

/// Promedio del cumplimiento diario del mes hasta hoy (0..1). Solo cuenta los
/// días en que había hábitos activos.
double monthlyCompletion(HabitData data, int year, int month, DateTime today) {
  var sum = 0.0;
  var counted = 0;
  final last = daysInMonth(year, month);
  for (var day = 1; day <= last; day++) {
    final d = DateTime(year, month, day);
    if (d.isAfter(dateOnly(today))) break;
    final ratio = completionRatio(data, d);
    if (ratio == null) continue;
    sum += ratio;
    counted++;
  }
  return counted == 0 ? 0 : sum / counted;
}

class OverallStats {
  final int activeHabits;
  final int completedToday;
  final int currentStreak;
  final int bestStreak;
  final int perfectDays;
  final double monthlyProgress;

  const OverallStats({
    required this.activeHabits,
    required this.completedToday,
    required this.currentStreak,
    required this.bestStreak,
    required this.perfectDays,
    required this.monthlyProgress,
  });

  /// Fracción (0..1) de hábitos completados hoy.
  double get dailyProgress => activeHabits == 0 ? 0 : completedToday / activeHabits;

  int get unlockedAchievements => achievements.where((a) => bestStreak >= a.days).length;

  factory OverallStats.compute(HabitData data, DateTime today) {
    final active = data.activeHabits;
    final runs = _perfectDayRuns(data, today);
    return OverallStats(
      activeHabits: active.length,
      completedToday: active.where((h) => data.isDone(h.id, today)).length,
      currentStreak: currentPerfectStreak(data, today),
      bestStreak: runs.best,
      perfectDays: runs.total,
      monthlyProgress: monthlyCompletion(data, today.year, today.month, today),
    );
  }
}
