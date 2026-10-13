import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepmind/core/dates.dart';
import 'package:stepmind/domain/habit_stats.dart';
import 'package:stepmind/models/habit.dart';

Habit habit(String id, {required DateTime created, DateTime? archived}) => Habit(
      id: id,
      name: id,
      time: const TimeOfDay(hour: 8, minute: 0),
      createdAt: created,
      archivedAt: archived,
    );

Set<String> days(List<DateTime> dates) => dates.map(dayKey).toSet();

void main() {
  final today = DateTime(2026, 3, 10);
  DateTime ago(int n) => addDays(today, -n);

  group('habitStreak', () {
    test('cuenta días consecutivos terminando hoy', () {
      expect(habitStreak(days([today, ago(1), ago(2)]), today), 3);
    });

    test('si hoy aún no está marcado, la racha de ayer sigue viva', () {
      expect(habitStreak(days([ago(1), ago(2)]), today), 2);
    });

    test('un día saltado corta la racha', () {
      expect(habitStreak(days([today, ago(2), ago(3)]), today), 1);
    });

    test('sin marcas ni ayer ni hoy es 0', () {
      expect(habitStreak(days([ago(2)]), today), 0);
    });
  });

  test('habitBestStreak encuentra la racha más larga', () {
    expect(habitBestStreak(days([ago(9), ago(8), ago(7), ago(5), ago(4)])), 3);
    expect(habitBestStreak({}), 0);
  });

  test('las rachas cruzan meses correctamente', () {
    final d = days([DateTime(2026, 2, 27), DateTime(2026, 2, 28), DateTime(2026, 3, 1)]);
    expect(habitStreak(d, DateTime(2026, 3, 1)), 3);
  });

  group('dayStatus', () {
    final a = habit('a', created: ago(10));
    final b = habit('b', created: ago(10));

    test('perfecto, parcial, ninguno, pendiente y futuro', () {
      final data = HabitData(habits: [a, b], checkins: {
        'a': days([ago(1), ago(2), today]),
        'b': days([ago(1)]),
      });
      expect(dayStatus(data, ago(1), today), DayStatus.perfect);
      expect(dayStatus(data, ago(2), today), DayStatus.partial);
      expect(dayStatus(data, ago(3), today), DayStatus.missed);
      expect(dayStatus(data, today, today), DayStatus.pending);
      expect(dayStatus(data, addDays(today, 1), today), DayStatus.future);
    });

    test('los días antes de crear el hábito no cuentan', () {
      final nuevo = habit('n', created: ago(1));
      final data = HabitData(habits: [a, nuevo], checkins: {
        'a': days([ago(5)]),
      });
      expect(dayStatus(data, ago(5), today), DayStatus.perfect);
    });

    test('un hábito archivado no cuenta desde que se archivó', () {
      final archivado = habit('x', created: ago(10), archived: ago(3));
      final data = HabitData(habits: [a, archivado], checkins: {
        'a': days([ago(1), ago(4)]),
      });
      expect(dayStatus(data, ago(1), today), DayStatus.perfect);
      expect(dayStatus(data, ago(4), today), DayStatus.partial);
    });

    test('sin hábitos activos el día está vacío', () {
      expect(dayStatus(HabitData.empty, ago(1), today), DayStatus.empty);
    });
  });

  group('rachas globales (días perfectos)', () {
    final a = habit('a', created: ago(30));
    final b = habit('b', created: ago(30));

    test('desmarcar hoy no destruye la racha acumulada', () {
      final data = HabitData(habits: [a, b], checkins: {
        'a': days([ago(1), ago(2), ago(3)]),
        'b': days([ago(1), ago(2), ago(3)]),
      });
      final stats = OverallStats.compute(data, today);
      expect(stats.currentStreak, 3);
      expect(stats.bestStreak, 3);
      expect(stats.perfectDays, 3);
    });

    test('un día no perfecto en medio corta la racha actual pero no la mejor', () {
      final data = HabitData(habits: [a, b], checkins: {
        'a': days([today, ago(1), ago(3), ago(4), ago(5), ago(6)]),
        'b': days([today, ago(1), ago(3), ago(4), ago(5), ago(6)]),
      });
      final stats = OverallStats.compute(data, today);
      expect(stats.currentStreak, 2);
      expect(stats.bestStreak, 4);
      expect(stats.perfectDays, 6);
    });
  });

  group('logros', () {
    test('se desbloquean según la mejor racha y no se pierden', () {
      final a = habit('a', created: ago(40));
      final perfect = [for (var i = 10; i < 18; i++) ago(i)]; // 8 días seguidos
      final data = HabitData(habits: [a], checkins: {'a': days(perfect)});
      final stats = OverallStats.compute(data, today);
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 8);
      expect(stats.unlockedAchievements, 2); // 1 día y 7 días
    });
  });

  group('progreso', () {
    test('progreso diario', () {
      final data = HabitData(
        habits: [habit('a', created: ago(1)), habit('b', created: ago(1))],
        checkins: {'a': days([today])},
      );
      final stats = OverallStats.compute(data, today);
      expect(stats.completedToday, 1);
      expect(stats.dailyProgress, 0.5);
    });

    test('mensual: promedia solo días con hábitos activos', () {
      // Hábito creado el día 9: solo cuentan el 9 (hecho) y el 10 (no hecho).
      final data = HabitData(
        habits: [habit('a', created: DateTime(2026, 3, 9))],
        checkins: {'a': days([DateTime(2026, 3, 9)])},
      );
      expect(monthlyCompletion(data, 2026, 3, today), 0.5);
    });

    test('mensual sin hábitos es 0', () {
      expect(monthlyCompletion(HabitData.empty, 2026, 3, today), 0);
    });
  });
}
