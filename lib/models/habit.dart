import 'package:flutter/material.dart';

import '../core/dates.dart';

class Habit {
  final String id;
  final String name;
  final TimeOfDay time;
  final DateTime createdAt;

  /// Fecha en que se eliminó. Los hábitos archivados no se muestran, pero su
  /// historial se conserva para que las estadísticas pasadas no cambien.
  final DateTime? archivedAt;

  const Habit({
    required this.id,
    required this.name,
    required this.time,
    required this.createdAt,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;

  /// Un hábito cuenta para un día si ya existía ese día y no se había archivado.
  bool isActiveOn(DateTime day) {
    final d = dateOnly(day);
    if (d.isBefore(dateOnly(createdAt))) return false;
    final archived = archivedAt;
    return archived == null || d.isBefore(dateOnly(archived));
  }

  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Habit copyWith({
    String? name,
    TimeOfDay? time,
    DateTime? archivedAt,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      time: time ?? this.time,
      createdAt: createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'reminder_minutes': time.hour * 60 + time.minute,
        'created_at': createdAt.millisecondsSinceEpoch,
        'archived_at': archivedAt?.millisecondsSinceEpoch,
      };

  factory Habit.fromRow(Map<String, Object?> row) {
    final minutes = row['reminder_minutes'] as int;
    final archived = row['archived_at'] as int?;
    return Habit(
      id: row['id'] as String,
      name: row['name'] as String,
      time: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      archivedAt: archived == null ? null : DateTime.fromMillisecondsSinceEpoch(archived),
    );
  }
}
