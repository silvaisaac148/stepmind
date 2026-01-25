import 'package:flutter/material.dart';

class Habit {
  final String id;
  final String name;
  final TimeOfDay time;
  final DateTime createdAt;
  final List<DateTime> completedDates;
  bool isCompletedToday;

  Habit({
    required this.id,
    required this.name,
    required this.time,
    required this.createdAt,
    required this.completedDates,
    this.isCompletedToday = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedDates': completedDates.map((date) => date.millisecondsSinceEpoch).toList(),
      'isCompletedToday': isCompletedToday,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      time: TimeOfDay(
        hour: json['timeHour'],
        minute: json['timeMinute'],
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      completedDates: (json['completedDates'] as List)
          .map((timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp))
          .toList(),
      isCompletedToday: json['isCompletedToday'] ?? false,
    );
  }

  Habit copyWith({
    String? id,
    String? name,
    TimeOfDay? time,
    DateTime? createdAt,
    List<DateTime>? completedDates,
    bool? isCompletedToday,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
    );
  }

  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    
    final sortedDates = List<DateTime>.from(completedDates)..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (int i = 0; i < sortedDates.length; i++) {
      final date = DateTime(
        sortedDates[i].year,
        sortedDates[i].month,
        sortedDates[i].day,
      );
      final checkDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day - i,
      );
      
      if (date.isAtSameMomentAs(checkDate)) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
}
