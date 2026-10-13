import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import 'habit_service.dart';

class StatsService {
  static const String _totalDaysKey = 'total_days';
  static const String _achievementsKey = 'achievements';
  static const String _firstLaunchKey = 'first_launch';
  static const String _currentStreakKey = 'current_streak';

  final HabitService _habitService = HabitService();

  Future<double> getMonthlyProgress() async {
    final habits = await _habitService.getHabits();
    final now = DateTime.now();
    
    if (habits.isEmpty) return 0.0;
    
    double totalDailyProgress = 0.0;
    int daysPassed = now.day;
    
    // Calcular progreso diario para cada día del mes hasta hoy
    for (int day = 1; day <= daysPassed; day++) {
      final currentDay = DateTime(now.year, now.month, day);
      double dayProgress = 0.0;
      
      for (final habit in habits) {
        // Verificar si el hábito fue completado en este día
        final completedOnDay = habit.completedDates.any((date) =>
            DateTime(date.year, date.month, date.day).isAtSameMomentAs(currentDay));
        
        if (completedOnDay) {
          dayProgress += (100.0 / habits.length);
        }
      }
      
      totalDailyProgress += dayProgress;
    }
    
    // Calcular promedio mensual
    final monthlyProgress = totalDailyProgress / daysPassed;
    return monthlyProgress;
  }

  Future<Map<String, dynamic>> getStats() async {
    final habits = await _habitService.getHabits();
    final prefs = await SharedPreferences.getInstance();
    
    // Calcular hábitos totales
    final totalHabits = habits.length;
    
    // Calcular días completados
    final totalDays = prefs.getInt(_totalDaysKey) ?? 0;
    
    // Calcular racha actual
    final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    
    // Calcular logros basados en hábitos
    final achievements = await _calculateAchievements(habits, prefs);
    
    // Calcular progreso diario
    final dailyProgress = _calculateDailyProgress(habits);
    
    return {
      'habits': totalHabits,
      'days': totalDays,
      'achievements': achievements,
      'dailyProgress': dailyProgress,
      'currentStreak': currentStreak,
    };
  }

  double _calculateDailyProgress(List<Habit> habits) {
    if (habits.isEmpty) return 0.0;
    
    final completedToday = habits.where((h) => h.isCompletedToday).length;
    return (completedToday / habits.length) * 100;
  }

  Future<int> _calculateAchievements(List<Habit> habits, SharedPreferences prefs) async {
    final achievements = prefs.getInt(_achievementsKey) ?? 0;
    
    // Logro 1: Completar todos los hábitos durante un día completo
    if (achievements == 0) {
      final allCompletedToday = habits.isNotEmpty && 
          habits.every((habit) => habit.isCompletedToday);
      if (allCompletedToday) {
        await prefs.setInt(_achievementsKey, 1);
        return 1;
      }
    }
    
    // Logro 2: Completar todos los hábitos durante una semana (7 días seguidos)
    if (achievements < 2) {
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      if (currentStreak >= 7) {
        await prefs.setInt(_achievementsKey, 2);
        return 2;
      }
    }
    
    // Logro 3: Completar todos los hábitos durante dos semanas (14 días seguidos)
    if (achievements < 3) {
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      if (currentStreak >= 14) {
        await prefs.setInt(_achievementsKey, 3);
        return 3;
      }
    }
    
    // Logro 4: Completar todos los hábitos durante un mes (30 días seguidos)
    if (achievements < 4) {
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      if (currentStreak >= 30) {
        await prefs.setInt(_achievementsKey, 4);
        return 4;
      }
    }
    
    // Logro 5: Completar todos los hábitos durante tres meses (90 días seguidos)
    if (achievements < 5) {
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      if (currentStreak >= 90) {
        await prefs.setInt(_achievementsKey, 5);
        return 5;
      }
    }
    
    // Logro 6: Completar todos los hábitos durante seis meses (180 días seguidos)
    if (achievements < 6) {
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      if (currentStreak >= 180) {
        await prefs.setInt(_achievementsKey, 6);
        return 6;
      }
    }
    
    // Logro 7: Completar todos los hábitos durante un año (365 días seguidos)
    if (achievements < 7) {
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      if (currentStreak >= 365) {
        await prefs.setInt(_achievementsKey, 7);
        return 7;
      }
    }
    
    // Logro 8: Completar todos los hábitos durante dos años (730 días seguidos)
    if (achievements < 8) {
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      if (currentStreak >= 730) {
        await prefs.setInt(_achievementsKey, 8);
        return 8;
      }
    }
    
    // Logro 9: Completar todos los hábitos durante cinco años (1825 días seguidos)
    if (achievements < 9) {
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      if (currentStreak >= 1825) {
        await prefs.setInt(_achievementsKey, 9);
        return 9;
      }
    }
    
    // Logro 10: Completar todos los hábitos durante diez años (3650 días seguidos)
    if (achievements < 10) {
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      if (currentStreak >= 3650) {
        await prefs.setInt(_achievementsKey, 10);
        return 10;
      }
    }
    
    return achievements;
  }

  Future<void> updateDailyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final habits = await _habitService.getHabits();
    
    // Verificar si todos los hábitos fueron completados hoy
    final allCompletedToday = habits.isNotEmpty && 
        habits.every((habit) => habit.isCompletedToday);
    
    // Obtener el estado actual del día para evitar múltiples incrementos
    final todayKey = 'completed_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}';
    final alreadyCompletedToday = prefs.getBool(todayKey) ?? false;
    
    if (allCompletedToday && !alreadyCompletedToday) {
      // Incrementar contador de días solo una vez por día
      final currentDays = prefs.getInt(_totalDaysKey) ?? 0;
      await prefs.setInt(_totalDaysKey, currentDays + 1);
      
      // Marcar que ya se completó hoy
      await prefs.setBool(todayKey, true);
      
      // Incrementar racha actual
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      await prefs.setInt(_currentStreakKey, currentStreak + 1);
      
      // Verificar logros
      await _calculateAchievements(habits, prefs);
    } else if (!allCompletedToday) {
      // Resetear racha si no se completaron todos los hábitos
      await prefs.setInt(_currentStreakKey, 0);
      // Resetear el estado del día si no se completaron todos
      await prefs.setBool(todayKey, false);
    }
  }

  Future<void> initializeFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLaunched = prefs.getBool(_firstLaunchKey) ?? false;
    
    if (!hasLaunched) {
      await prefs.setBool(_firstLaunchKey, true);
      await prefs.setInt(_totalDaysKey, 0);
      await prefs.setInt(_achievementsKey, 0);
      await prefs.setInt(_currentStreakKey, 0);
      
      // Limpiar cualquier clave de día completado existente
      final todayKey = 'completed_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}';
      await prefs.setBool(todayKey, false);
    } else {
      // Forzar reset a 0 si hay valores incorrectos
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      if (currentStreak > 0 && !await _hasValidStreak()) {
        await prefs.setInt(_currentStreakKey, 0);
        await prefs.setInt(_totalDaysKey, 0);
        await prefs.setInt(_achievementsKey, 0);
      }
    }
  }

  Future<bool> _hasValidStreak() async {
    final habits = await _habitService.getHabits();
    if (habits.isEmpty) return false;
    
    // Verificar si realmente hay una racha válida
    return habits.every((habit) => habit.isCompletedToday);
  }

  Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalDaysKey, 0);
    await prefs.setInt(_achievementsKey, 0);
    await prefs.setInt(_currentStreakKey, 0);
    await prefs.setBool(_firstLaunchKey, false);
  }
}
