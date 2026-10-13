import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();

    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permisos
    await _requestPermissions();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    // Permisos para Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // Permisos adicionales para Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Manejar el toque en la notificación
    debugPrint('Notificación tocada: ${response.payload}');
  }

  Future<void> scheduleHabitNotifications(List<Habit> habits) async {
    await initialize();

    // Cancelar todas las notificaciones existentes
    await _flutterLocalNotificationsPlugin.cancelAll();

    // Programar notificaciones para cada hábito
    for (final habit in habits) {
      await _scheduleHabitNotification(habit);
    }

    // Guardar estado de notificaciones activas
    await _saveNotificationStatus(habits);
  }

  Future<void> _scheduleHabitNotification(Habit habit) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = _getNextScheduledTime(habit.time, now);

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'habit_reminders',
        'Recordatorios de Hábitos',
        channelDescription: 'Notificaciones para recordar tus hábitos diarios',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF282524),
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          'Es hora de completar tu hábito: ${habit.name}',
          htmlFormatBigText: true,
          contentTitle: '🎯 Recordatorio de StepMind',
          htmlFormatContentTitle: true,
        ),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        habit.id.hashCode,
        '🎯 Recordatorio de StepMind',
        'Es hora de completar tu hábito: ${habit.name}',
        scheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'habit_${habit.id}',
      );

      debugPrint('Notificación programada para ${habit.name} a las ${habit.formattedTime} el ${scheduledTime.day}/${scheduledTime.month}');
    } catch (e) {
      debugPrint('Error al programar notificación para ${habit.name}: $e');
    }
  }

  tz.TZDateTime _getNextScheduledTime(TimeOfDay time, tz.TZDateTime now) {
    final scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduled.isBefore(now)) {
      return scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  // Método para programar notificación inmediata (para pruebas)
  Future<void> scheduleImmediateNotification(Habit habit) async {
    try {
      await initialize();

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'habit_reminders',
        'Recordatorios de Hábitos',
        channelDescription: 'Notificaciones para recordar tus hábitos diarios',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF282524),
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          'Es hora de completar tu hábito: ${habit.name}',
          htmlFormatBigText: true,
          contentTitle: '🎯 Recordatorio de StepMind',
          htmlFormatContentTitle: true,
        ),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Programar para 5 segundos después
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        habit.id.hashCode,
        '🎯 Recordatorio de StepMind',
        'Es hora de completar tu hábito: ${habit.name}',
        scheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'habit_${habit.id}',
      );

      debugPrint('Notificación inmediata programada para ${habit.name}');
    } catch (e) {
      debugPrint('Error al programar notificación inmediata para ${habit.name}: $e');
    }
  }

  Future<void> cancelHabitNotification(String habitId) async {
    await _flutterLocalNotificationsPlugin.cancel(habitId.hashCode);
    debugPrint('Notificación cancelada para hábito: $habitId');
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('Todas las notificaciones canceladas');
  }

  Future<void> showTestNotification() async {
    await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_channel',
      'Canal de Prueba',
      channelDescription: 'Notificaciones de prueba',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF282524),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '🧪 Notificación de Prueba',
      'StepMind está funcionando correctamente',
      platformChannelSpecifics,
      payload: 'test_notification',
    );
  }

  Future<List<String>> getActiveNotificationTimes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('active_notification_times') ?? [];
  }

  Future<void> _saveNotificationStatus(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final times = habits.map((habit) => habit.formattedTime).toSet().toList();
    await prefs.setStringList('active_notification_times', times);
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  Future<void> requestNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      final granted = await androidPlugin?.requestNotificationsPermission();
      debugPrint('Permiso de notificación concedido: $granted');
    }
  }

  // Método para verificar el estado de los permisos
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      switch (status) {
        case PermissionStatus.granted:
          return NotificationPermissionStatus.granted;
        case PermissionStatus.denied:
          return NotificationPermissionStatus.denied;
        case PermissionStatus.permanentlyDenied:
          return NotificationPermissionStatus.permanentlyDenied;
        default:
          return NotificationPermissionStatus.unknown;
      }
    }
    return NotificationPermissionStatus.granted; // iOS maneja permisos diferente
  }
}

enum NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unknown,
}