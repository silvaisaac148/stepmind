import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import 'notification_service.dart';
import 'stats_service.dart';

class HabitService {
  static const String _habitsKey = 'habits';
  final NotificationService _notificationService = NotificationService();

  Future<List<Habit>> getHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getString(_habitsKey);
    
    if (habitsJson == null) return [];
    
    try {
      final List<dynamic> habitsList = json.decode(habitsJson);
      return habitsList.map((habitJson) => Habit.fromJson(habitJson)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = json.encode(habits.map((habit) => habit.toJson()).toList());
    await prefs.setString(_habitsKey, habitsJson);
  }

  Future<void> addHabit(Habit habit) async {
    final habits = await getHabits();
    habits.add(habit);
    await saveHabits(habits);
    // Programar notificaciones para el nuevo hábito
    await _notificationService.scheduleHabitNotifications(habits);
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final habits = await getHabits();
    final index = habits.indexWhere((habit) => habit.id == updatedHabit.id);
    
    if (index != -1) {
      habits[index] = updatedHabit;
      await saveHabits(habits);
      // Reprogramar notificaciones con los datos actualizados
      await _notificationService.scheduleHabitNotifications(habits);
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final habits = await getHabits();
    habits.removeWhere((habit) => habit.id == habitId);
    await saveHabits(habits);
    // Cancelar notificación del hábito eliminado
    await _notificationService.cancelHabitNotification(habitId);
    // Reprogramar todas las notificaciones
    await _notificationService.scheduleHabitNotifications(habits);
  }

  Future<void> toggleHabitCompletion(String habitId) async {
    final habits = await getHabits();
    final index = habits.indexWhere((habit) => habit.id == habitId);
    
    if (index != -1) {
      final habit = habits[index];
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      if (habit.isCompletedToday) {
        // Remove today from completed dates
        habit.completedDates.removeWhere((date) => 
            DateTime(date.year, date.month, date.day).isAtSameMomentAs(todayDate));
        habit.isCompletedToday = false;
      } else {
        // Add today to completed dates
        habit.completedDates.add(todayDate);
        habit.isCompletedToday = true;
      }
      
      await saveHabits(habits);
      
      // Actualizar estadísticas después de cambiar el estado
      await StatsService().updateDailyStats();
    }
  }

  Future<void> resetDailyCompletion() async {
    final habits = await getHabits();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    bool needsUpdate = false;
    
    for (final habit in habits) {
      final lastCompletedDate = habit.completedDates.isNotEmpty 
          ? habit.completedDates.reduce((a, b) => a.isAfter(b) ? a : b)
          : null;
      
      if (lastCompletedDate != null) {
        final lastCompletedDay = DateTime(
          lastCompletedDate.year, 
          lastCompletedDate.month, 
          lastCompletedDate.day
        );
        
        if (!lastCompletedDay.isAtSameMomentAs(todayDate)) {
          habit.isCompletedToday = false;
          needsUpdate = true;
        }
      }
    }
    
    if (needsUpdate) {
      await saveHabits(habits);
    }
  }

  // Método para inicializar notificaciones al iniciar la app
  Future<void> initializeNotifications() async {
    try {
      await _notificationService.initialize();
      final habits = await getHabits();
      if (habits.isNotEmpty) {
        // Cancelar notificaciones existentes y reprogramar
        await _notificationService.cancelAllNotifications();
        await _notificationService.scheduleHabitNotifications(habits);
        debugPrint('Notificaciones reinicializadas para ${habits.length} hábitos');
      }
    } catch (e) {
      debugPrint('Error al inicializar notificaciones: $e');
    }
  }

  // Método para obtener horas activas de notificaciones
  Future<List<String>> getActiveNotificationTimes() async {
    return await _notificationService.getActiveNotificationTimes();
  }

  // Método para verificar si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabled();
  }

  // Método para habilitar/deshabilitar notificaciones
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _notificationService.setNotificationsEnabled(enabled);
    if (enabled) {
      final habits = await getHabits();
      await _notificationService.scheduleHabitNotifications(habits);
    }
  }
}
