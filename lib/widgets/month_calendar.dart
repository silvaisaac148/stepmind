import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../domain/habit_stats.dart';
import '../core/theme.dart';

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
        DayStatus.perfect => AppColors.orange,
        DayStatus.partial => AppColors.orangeDeep,
        DayStatus.missed => AppColors.surfaceHigh,
        DayStatus.pending => AppColors.petrol700,
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
                    style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800),
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
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: statusColor(status),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? AppColors.yellow
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
                          color: status == DayStatus.future ? AppColors.textMuted : Colors.white,
                          fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (hasEvents(day))
                      const Positioned(
                        bottom: 3,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: CircleAvatar(radius: 2.5, backgroundColor: AppColors.teal),
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
