import 'package:flutter_test/flutter_test.dart';
import 'package:stepmind/domain/recovery.dart';

void main() {
  final goal = RecoveryGoal(
    id: 'g1',
    name: 'Pornografía',
    startedAt: DateTime(2026, 3, 1, 9),
    createdAt: DateTime(2026, 3, 1, 9),
  );

  RecoveryEvent slip(DateTime at, {String? emotion, String? trigger}) => RecoveryEvent(
        id: 's${at.millisecondsSinceEpoch}',
        goalId: 'g1',
        kind: RecoveryEventKind.slip,
        at: at,
        emotion: emotion,
        trigger: trigger,
      );

  test('sin deslices, la racha es el tiempo desde el inicio', () {
    final stats = RecoveryStats.compute(goal, const [], DateTime(2026, 3, 11, 10));
    expect(stats.currentStreakDays, 10);
    expect(stats.cleanDays, 11, reason: 'del 1 al 11 de marzo, hoy incluido');
    expect(stats.bestStreakDays, 10);
    expect(stats.nextMilestone, 14);
    expect(stats.lastMilestone, 7);
  });

  test('un desliz reinicia la racha pero no borra los días limpios', () {
    final stats = RecoveryStats.compute(
      goal,
      [slip(DateTime(2026, 3, 8, 23))],
      DateTime(2026, 3, 11, 23),
    );
    expect(stats.currentStreakDays, 3);
    expect(stats.cleanDays, 10, reason: '11 días menos el día del desliz');
    expect(stats.bestStreakDays, 7);
    expect(stats.slips, 1);
  });

  test('detecta la emoción, el desencadenante y la franja más frecuentes', () {
    final stats = RecoveryStats.compute(
      goal,
      [
        slip(DateTime(2026, 3, 3, 23), emotion: 'Soledad', trigger: 'En la cama'),
        slip(DateTime(2026, 3, 6, 22), emotion: 'Soledad', trigger: 'En la cama'),
        slip(DateTime(2026, 3, 9, 15), emotion: 'Estrés', trigger: 'Redes sociales'),
        RecoveryEvent(
          id: 'u1',
          goalId: 'g1',
          kind: RecoveryEventKind.urge,
          at: DateTime(2026, 3, 10, 23),
          resisted: true,
        ),
      ],
      DateTime(2026, 3, 11, 12),
    );
    expect(stats.topEmotion, 'Soledad');
    expect(stats.topTrigger, 'En la cama');
    expect(stats.riskiestDayPart, 3, reason: 'noche');
    expect(stats.urgesResisted, 1);
  });

  test('los planes se guardan y leen como JSON', () {
    final withPlans = goal.copyWith(plans: const [
      IfThenPlan(ifText: 'Estoy en la cama con el móvil', thenText: 'Lo dejo fuera del cuarto'),
    ]);
    final back = RecoveryGoal.fromRow(withPlans.toRow());
    expect(back.plans.single.thenText, 'Lo dejo fuera del cuarto');
    expect(back.startedAt, goal.startedAt);
  });
}
