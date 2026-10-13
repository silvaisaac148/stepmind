import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepmind/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location bogota;

  setUpAll(() {
    tz.initializeTimeZones();
    bogota = tz.getLocation('America/Bogota');
  });

  group('nextReminderTime', () {
    const eight = TimeOfDay(hour: 8, minute: 0);

    test('si la hora no ha pasado, es hoy en la zona local', () {
      final now = tz.TZDateTime(bogota, 2026, 3, 10, 7, 0);
      final next = NotificationService.nextReminderTime(eight, now);
      expect(next, tz.TZDateTime(bogota, 2026, 3, 10, 8, 0));
      // 8:00 en Bogotá son las 13:00 UTC, no las 8:00 UTC.
      expect(next.toUtc().hour, 13);
    });

    test('si la hora ya pasó, es mañana', () {
      final now = tz.TZDateTime(bogota, 2026, 3, 10, 9, 0);
      expect(
        NotificationService.nextReminderTime(eight, now),
        tz.TZDateTime(bogota, 2026, 3, 11, 8, 0),
      );
    });

    test('si el hábito ya se hizo hoy, empieza mañana', () {
      final now = tz.TZDateTime(bogota, 2026, 3, 10, 7, 0);
      expect(
        NotificationService.nextReminderTime(eight, now, skipToday: true),
        tz.TZDateTime(bogota, 2026, 3, 11, 8, 0),
      );
    });

    test('fin de mes pasa al día 1 siguiente', () {
      final now = tz.TZDateTime(bogota, 2026, 3, 31, 22, 0);
      expect(
        NotificationService.nextReminderTime(eight, now),
        tz.TZDateTime(bogota, 2026, 4, 1, 8, 0),
      );
    });

    test('respeta el cambio de horario de verano', () {
      final madrid = tz.getLocation('Europe/Madrid');
      // El 29/03/2026 en Madrid se adelanta la hora.
      final now = tz.TZDateTime(madrid, 2026, 3, 28, 9, 0);
      final next = NotificationService.nextReminderTime(eight, now);
      expect(next.hour, 8);
      expect(next.day, 29);
    });
  });

  group('notificationIdFor', () {
    test('es estable, positivo y nunca 0', () {
      const id = '3f1c2e9a-7d4b-4c1e-9a2f-1b2c3d4e5f60';
      final a = NotificationService.notificationIdFor(id);
      expect(a, NotificationService.notificationIdFor(id));
      expect(a, greaterThan(0));
      expect(a, lessThanOrEqualTo(0x7fffffff));
    });

    test('ids distintos para hábitos distintos', () {
      final ids = {
        for (var i = 0; i < 1000; i++) NotificationService.notificationIdFor('habit-$i'),
      };
      expect(ids.length, 1000);
    });
  });

  group('scheduleModeFor', () {
    test('exacto solo si el permiso está concedido', () {
      expect(
        NotificationService.scheduleModeFor(exactAllowed: true),
        AndroidScheduleMode.exactAllowWhileIdle,
      );
      expect(
        NotificationService.scheduleModeFor(exactAllowed: false),
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    });
  });
}
