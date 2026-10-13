import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _enabledKey = 'notifications_enabled';

  /// Id reservado para la notificación de prueba (los hábitos nunca usan 0).
  static const _testNotificationId = 0;

  static const _androidDetails = AndroidNotificationDetails(
    'habit_reminders',
    'Recordatorios de Hábitos',
    channelDescription: 'Notificaciones para recordar tus hábitos diarios',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFF282524),
    icon: 'ic_notification',
  );

  static const _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Se pone en `true` cuando el usuario abre la app tocando un recordatorio,
  /// para que la pantalla de inicio muestre la lista de hábitos.
  final ValueNotifier<bool> openHabitsRequested = ValueNotifier(false);

  bool _isInitialized = false;

  /// Configura zona horaria y plugin. No pide permisos: eso se hace cuando el
  /// usuario crea un hábito o activa las notificaciones.
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (e) {
      debugPrint('No se pudo obtener la zona horaria, se usa UTC: $e');
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) => openHabitsRequested.value = true,
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      openHabitsRequested.value = true;
    }

    _isInitialized = true;
  }

  /// Pide permiso para mostrar notificaciones. Devuelve si quedó concedido.
  Future<bool> requestPermission() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return true;
  }

  /// Id de notificación estable para un hábito (FNV-1a de 31 bits, nunca 0).
  static int notificationIdFor(String habitId) {
    var hash = 0x811c9dc5;
    for (final unit in habitId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    final id = hash & 0x7fffffff;
    return id == _testNotificationId ? 1 : id;
  }

  /// Próximo momento del recordatorio diario. Si [skipToday] (hábito ya hecho
  /// hoy) o la hora ya pasó, empieza mañana.
  static tz.TZDateTime nextReminderTime(
    TimeOfDay time,
    tz.TZDateTime now, {
    bool skipToday = false,
  }) {
    final today = tz.TZDateTime(now.location, now.year, now.month, now.day, time.hour, time.minute);
    if (!skipToday && today.isAfter(now)) return today;
    return tz.TZDateTime(now.location, now.year, now.month, now.day + 1, time.hour, time.minute);
  }

  /// Reprograma los recordatorios diarios de [habits]. Los que ya están
  /// completados hoy ([completedToday]) empiezan a sonar mañana.
  Future<void> syncHabitReminders(
    List<Habit> habits, {
    Set<String> completedToday = const {},
  }) async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();

    if (!await areNotificationsEnabled()) return;

    final now = tz.TZDateTime.now(tz.local);
    for (final habit in habits) {
      final id = notificationIdFor(habit.id);
      final done = completedToday.contains(habit.id);
      // Quita de la bandeja el recordatorio de un hábito ya completado.
      if (done) await _plugin.cancel(id: id);
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: '🎯 Recordatorio de StepMind',
          body: 'Es hora de completar tu hábito: ${habit.name}',
          scheduledDate: nextReminderTime(habit.time, now, skipToday: done),
          notificationDetails: _details,
          // Inexacto: no requiere el permiso de alarmas exactas (restringido
          // en Play Store). Android puede retrasarlo unos minutos.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'habit_${habit.id}',
        );
      } catch (e) {
        debugPrint('Error al programar notificación para ${habit.name}: $e');
      }
    }
  }

  Future<void> showTestNotification(String habitName) async {
    await initialize();
    await _plugin.show(
      id: _testNotificationId,
      title: '🧪 Notificación de prueba',
      body: 'Así se verá el recordatorio de: $habitName',
      notificationDetails: _details,
      payload: 'test_notification',
    );
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (!enabled) {
      await initialize();
      await _plugin.cancelAllPendingNotifications();
    }
  }
}
