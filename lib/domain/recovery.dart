import 'dart:convert';

import '../core/dates.dart';

/// Plan "si… entonces…" para una situación de riesgo.
class IfThenPlan {
  final String ifText;
  final String thenText;

  const IfThenPlan({required this.ifText, required this.thenText});

  Map<String, String> toJson() => {'if': ifText, 'then': thenText};

  factory IfThenPlan.fromJson(Map<String, dynamic> json) =>
      IfThenPlan(ifText: json['if'] as String? ?? '', thenText: json['then'] as String? ?? '');
}

/// Algo que el usuario quiere dejar (p. ej. pornografía, redes sociales).
class RecoveryGoal {
  final String id;
  final String name;

  /// Desde cuándo cuenta el progreso.
  final DateTime startedAt;

  /// "Mi porqué": razones y valores escritos por el usuario.
  final String why;
  final List<IfThenPlan> plans;
  final DateTime createdAt;
  final DateTime? archivedAt;

  const RecoveryGoal({
    required this.id,
    required this.name,
    required this.startedAt,
    required this.createdAt,
    this.why = '',
    this.plans = const [],
    this.archivedAt,
  });

  RecoveryGoal copyWith({
    String? name,
    DateTime? startedAt,
    String? why,
    List<IfThenPlan>? plans,
    DateTime? archivedAt,
  }) =>
      RecoveryGoal(
        id: id,
        name: name ?? this.name,
        startedAt: startedAt ?? this.startedAt,
        why: why ?? this.why,
        plans: plans ?? this.plans,
        createdAt: createdAt,
        archivedAt: archivedAt ?? this.archivedAt,
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'started_at': startedAt.millisecondsSinceEpoch,
        'why': why,
        'plans_json': jsonEncode([for (final p in plans) p.toJson()]),
        'created_at': createdAt.millisecondsSinceEpoch,
        'archived_at': archivedAt?.millisecondsSinceEpoch,
      };

  factory RecoveryGoal.fromRow(Map<String, Object?> row) {
    final archived = row['archived_at'] as int?;
    List<IfThenPlan> plans;
    try {
      plans = [
        for (final p in jsonDecode(row['plans_json'] as String? ?? '[]') as List)
          IfThenPlan.fromJson(p as Map<String, dynamic>),
      ];
    } catch (_) {
      plans = const [];
    }
    return RecoveryGoal(
      id: row['id'] as String,
      name: row['name'] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(row['started_at'] as int),
      why: row['why'] as String? ?? '',
      plans: plans,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      archivedAt: archived == null ? null : DateTime.fromMillisecondsSinceEpoch(archived),
    );
  }
}

enum RecoveryEventKind {
  /// Recaída / desliz.
  slip,

  /// Urgencia registrada (normalmente desde el SOS).
  urge,
}

class RecoveryEvent {
  final String id;
  final String goalId;
  final RecoveryEventKind kind;
  final DateTime at;

  /// Emoción en ese momento (p. ej. "Soledad", "Estrés").
  final String? emotion;

  /// Situación desencadenante (p. ej. "En la cama con el móvil").
  final String? trigger;

  /// Intensidad de la urgencia, 1 a 10.
  final int? intensity;

  /// Para urgencias: si se superó sin recaer.
  final bool resisted;
  final String? note;

  const RecoveryEvent({
    required this.id,
    required this.goalId,
    required this.kind,
    required this.at,
    this.emotion,
    this.trigger,
    this.intensity,
    this.resisted = false,
    this.note,
  });

  Map<String, Object?> toRow() => {
        'id': id,
        'goal_id': goalId,
        'kind': kind.name,
        'at': at.millisecondsSinceEpoch,
        'emotion': emotion,
        'situation': trigger,
        'intensity': intensity,
        'resisted': resisted ? 1 : 0,
        'note': note,
      };

  factory RecoveryEvent.fromRow(Map<String, Object?> row) => RecoveryEvent(
        id: row['id'] as String,
        goalId: row['goal_id'] as String,
        kind: RecoveryEventKind.values.firstWhere(
          (k) => k.name == row['kind'],
          orElse: () => RecoveryEventKind.urge,
        ),
        at: DateTime.fromMillisecondsSinceEpoch(row['at'] as int),
        emotion: row['emotion'] as String?,
        trigger: row['situation'] as String?,
        intensity: row['intensity'] as int?,
        resisted: row['resisted'] == 1,
        note: row['note'] as String?,
      );
}

class RecoveryData {
  final List<RecoveryGoal> goals;
  final List<RecoveryEvent> events;

  const RecoveryData({required this.goals, required this.events});

  static const empty = RecoveryData(goals: [], events: []);

  List<RecoveryGoal> get activeGoals => goals.where((g) => g.archivedAt == null).toList();

  List<RecoveryEvent> eventsFor(String goalId) =>
      events.where((e) => e.goalId == goalId).toList()..sort((a, b) => a.at.compareTo(b.at));

  RecoveryData copyWith({List<RecoveryGoal>? goals, List<RecoveryEvent>? events}) =>
      RecoveryData(goals: goals ?? this.goals, events: events ?? this.events);
}

/// Hitos en días. 66 = media para formar un hábito (Lally, 2010).
const recoveryMilestones = [1, 3, 7, 14, 30, 66, 90, 180, 365];

class RecoveryStats {
  /// Tiempo desde el último desliz (o desde el inicio).
  final Duration currentStreak;

  /// Días de calendario sin deslices desde el inicio (incluye hoy si va limpio).
  /// Un desliz no borra este total.
  final int cleanDays;
  final int bestStreakDays;
  final int slips;
  final int urgesResisted;
  final String? topEmotion;
  final String? topTrigger;

  /// Franja horaria con más deslices y urgencias (0 madrugada, 1 mañana,
  /// 2 tarde, 3 noche), o `null` si aún no hay datos.
  final int? riskiestDayPart;

  const RecoveryStats({
    required this.currentStreak,
    required this.cleanDays,
    required this.bestStreakDays,
    required this.slips,
    required this.urgesResisted,
    this.topEmotion,
    this.topTrigger,
    this.riskiestDayPart,
  });

  int get currentStreakDays => currentStreak.inDays;

  /// Próximo hito, o `null` si ya se superaron todos.
  int? get nextMilestone {
    for (final m in recoveryMilestones) {
      if (currentStreakDays < m) return m;
    }
    return null;
  }

  /// Último hito alcanzado (0 si ninguno).
  int get lastMilestone {
    var last = 0;
    for (final m in recoveryMilestones) {
      if (currentStreakDays >= m) last = m;
    }
    return last;
  }

  static const dayPartNames = ['madrugada', 'mañana', 'tarde', 'noche'];

  static int dayPartOf(DateTime t) => switch (t.hour) {
        < 6 => 0,
        < 12 => 1,
        < 19 => 2,
        _ => 3,
      };

  factory RecoveryStats.compute(RecoveryGoal goal, List<RecoveryEvent> events, DateTime now) {
    final start = goal.startedAt.isAfter(now) ? now : goal.startedAt;
    final slips = events
        .where((e) => e.kind == RecoveryEventKind.slip && !e.at.isBefore(start))
        .map((e) => e.at)
        .toList()
      ..sort();

    final lastReset = slips.isEmpty ? start : slips.last;
    final current = now.difference(lastReset);

    // Mejor racha: el mayor tramo entre inicio, deslices y ahora.
    var best = Duration.zero;
    var previous = start;
    for (final slip in [...slips, now]) {
      final gap = slip.difference(previous);
      if (gap > best) best = gap;
      previous = slip;
    }

    final slipDays = slips.map(dayKey).toSet();
    var clean = 0;
    for (var d = dateOnly(start); !d.isAfter(dateOnly(now)); d = addDays(d, 1)) {
      if (!slipDays.contains(dayKey(d))) clean++;
    }

    String? mostCommon(Iterable<String?> values) {
      final counts = <String, int>{};
      for (final v in values) {
        if (v != null && v.isNotEmpty) counts[v] = (counts[v] ?? 0) + 1;
      }
      if (counts.isEmpty) return null;
      return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    }

    final risky = events.where((e) => e.kind == RecoveryEventKind.slip || !e.resisted).toList();
    final parts = <int, int>{};
    for (final e in risky.isEmpty ? events : risky) {
      final part = dayPartOf(e.at);
      parts[part] = (parts[part] ?? 0) + 1;
    }
    final riskiest = parts.isEmpty
        ? null
        : (parts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;

    return RecoveryStats(
      currentStreak: current,
      cleanDays: clean,
      bestStreakDays: best.inDays,
      slips: slips.length,
      urgesResisted:
          events.where((e) => e.kind == RecoveryEventKind.urge && e.resisted).length,
      topEmotion: mostCommon(events.map((e) => e.emotion)),
      topTrigger: mostCommon(events.map((e) => e.trigger)),
      riskiestDayPart: riskiest,
    );
  }
}
