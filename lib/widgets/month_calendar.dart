import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../domain/habit_stats.dart';

/// Cuadrícula de un mes (semana empezando en lunes). Cada día se colorea según
/// su [DayStatus] y muestra un punto si tiene eventos.
class MonthCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime? selected;
  final DateTime today;
  final DayStatus Function(DateTime day) statusOf;
  final bool Function(DateTime day) hasEvents;
  final ValueChanged<DateTime> onSelect;

  const MonthCalendar({
    super.key,
    required this.month,
    required this.today,
    required this.statusOf,
    required this.hasEvents,
    required this.onSelect,
    this.selected,
  });

  static const _weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  static Color statusColor(DayStatus status) => switch (status) {
        DayStatus.perfect => Colors.green[700]!,
        DayStatus.partial => Colors.amber[800]!,
        DayStatus.missed => Colors.red[800]!,
        DayStatus.pending => const Color(0xFF4A4543),
        DayStatus.empty || DayStatus.future => Colors.transparent,
      };

  @override
  Widget build(BuildContext context) {
    final total = daysInMonth(month.year, month.month);
    final leading = DateTime(month.year, month.month, 1).weekday - 1;

    return Column(
      children: [
        Row(
          children: [
            for (final d in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: leading + total,
          itemBuilder: (context, index) {
            if (index < leading) return const SizedBox();
            final day = DateTime(month.year, month.month, index - leading + 1);
            final status = statusOf(day);
            final isSelected = selected != null && isSameDay(selected!, day);
            final isToday = isSameDay(today, day);

            return GestureDetector(
              onTap: () => onSelect(day),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: statusColor(status),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? Colors.blue
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: status == DayStatus.future ? Colors.grey[600] : Colors.white,
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (hasEvents(day))
                      const Positioned(
                        bottom: 3,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: CircleAvatar(radius: 2.5, backgroundColor: Colors.lightBlueAccent),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
