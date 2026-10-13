class CalendarEvent {
  final String id;

  /// Día del evento como clave `YYYY-MM-DD`.
  final String day;
  final String title;

  const CalendarEvent({required this.id, required this.day, required this.title});

  Map<String, Object?> toRow() => {'id': id, 'day': day, 'title': title};

  factory CalendarEvent.fromRow(Map<String, Object?> row) => CalendarEvent(
        id: row['id'] as String,
        day: row['day'] as String,
        title: row['title'] as String,
      );
}
