/// Utilidades de fechas "de calendario" (sin hora).
///
/// Los días se representan como claves `YYYY-MM-DD` en hora local. Así una
/// marca hecha el martes sigue siendo del martes aunque cambie la zona horaria.
library;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String dayKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

DateTime parseDayKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// Suma días de calendario (seguro frente a cambios de horario de verano).
DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

const monthNames = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

String formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
