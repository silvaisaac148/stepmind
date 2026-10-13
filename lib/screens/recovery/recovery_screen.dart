import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../domain/recovery.dart';
import '../../domain/recovery_content.dart';
import '../../providers/providers.dart';
import '../../widgets/brand.dart';
import '../addictions_screen.dart';
import 'recovery_setup_screen.dart';
import 'slip_sheet.dart';
import 'sos_screen.dart';

/// Pestaña "Adicciones": acompaña al usuario a dejar algo que le hace daño.
class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  String? _selectedId;

  /// Refresca el contador cada minuto.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _openSetup([RecoveryGoal? goal]) => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => RecoverySetupScreen(goal: goal)),
      );

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(recoveryProvider).value ?? RecoveryData.empty;
    final goals = data.activeGoals;
    final selected = goals.where((g) => g.id == _selectedId).firstOrNull ?? goals.firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Superar adicciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'Aprender sobre adicciones',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddictionsScreen()),
            ),
          ),
          if (goals.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Nueva meta',
              onPressed: _openSetup,
            ),
        ],
      ),
      body: selected == null
          ? _EmptyState(onStart: _openSetup)
          : _Dashboard(
              key: ValueKey(selected.id),
              goal: selected,
              data: data,
              goals: goals,
              onSelectGoal: (id) => setState(() => _selectedId = id),
              onEdit: () => _openSetup(selected),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyState({required this.onStart});

  @override
  Widget build(BuildContext context) {
    const points = [
      (Icons.sos_rounded, 'Botón SOS para el momento de la urgencia: respiración, tu porqué y qué hacer.'),
      (Icons.favorite_rounded, 'Un desliz no borra tu progreso: cuentas tus días limpios totales.'),
      (Icons.insights_rounded, 'Descubre tus patrones: emociones, lugares y horas de riesgo.'),
      (Icons.lock_rounded, 'Privado: se guarda solo en tu teléfono.'),
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        const Center(child: StepMindLogo(size: 90)),
        const SizedBox(height: 20),
        const Text(
          'Libérate de lo que te frena',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Un acompañamiento basado en lo que dice la ciencia: no pelear con la '
          'urgencia, sino aprender a dejarla pasar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 28),
        for (final (icon, text) in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.orange),
                const SizedBox(width: 14),
                Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(height: 52, child: ElevatedButton(onPressed: onStart, child: const Text('Empezar'))),
      ],
    );
  }
}

class _Dashboard extends ConsumerStatefulWidget {
  final RecoveryGoal goal;
  final RecoveryData data;
  final List<RecoveryGoal> goals;
  final ValueChanged<String> onSelectGoal;
  final VoidCallback onEdit;

  const _Dashboard({
    super.key,
    required this.goal,
    required this.data,
    required this.goals,
    required this.onSelectGoal,
    required this.onEdit,
  });

  @override
  ConsumerState<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<_Dashboard> {
  RecoveryGoal get goal => widget.goal;

  @override
  void didUpdateWidget(covariant _Dashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _celebrateMilestone();
  }

  @override
  void initState() {
    super.initState();
    _celebrateMilestone();
  }

  /// Muestra una sola vez cada hito alcanzado.
  Future<void> _celebrateMilestone() async {
    final stats = recoveryStatsFor(widget.data, goal, ref.read(clockProvider)());
    final reached = stats.lastMilestone;
    if (reached == 0) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'recovery_milestone_seen_${goal.id}';
    if ((prefs.getInt(key) ?? 0) >= reached) return;
    await prefs.setInt(key, reached);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.emoji_events_rounded, color: AppColors.yellow, size: 48),
        title: Text('¡$reached ${reached == 1 ? 'día' : 'días'}!'),
        content: Text(milestoneMessages[reached] ?? '¡Sigue así!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('¡Vamos!')),
        ],
      ),
    );
  }

  Future<void> _confirmArchive() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Archivar "${goal.name}"?'),
        content: const Text('Dejará de mostrarse. Su historial se conserva en el teléfono.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Archivar')),
        ],
      ),
    );
    if (ok == true) await ref.read(recoveryProvider.notifier).archiveGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final stats = recoveryStatsFor(widget.data, goal, now);
    final events = widget.data.eventsFor(goal.id).reversed.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        if (widget.goals.length > 1)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final g in widget.goals)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(g.name),
                      selected: g.id == goal.id,
                      selectedColor: AppColors.orange,
                      onSelected: (_) => widget.onSelectGoal(g.id),
                    ),
                  ),
              ],
            ),
          ),
        _StreakCard(goal: goal, stats: stats, onEdit: widget.onEdit, onArchive: _confirmArchive),
        const SizedBox(height: 16),
        Row(
          children: [
            _MiniStat(label: 'Días limpios', value: '${stats.cleanDays}', icon: Icons.spa_rounded),
            const SizedBox(width: 10),
            _MiniStat(
              label: 'Mejor racha',
              value: '${stats.bestStreakDays} d',
              icon: Icons.emoji_events_rounded,
            ),
            const SizedBox(width: 10),
            _MiniStat(
              label: 'Urgencias superadas',
              value: '${stats.urgesResisted}',
              icon: Icons.waves_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SosButton(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => SosScreen(goal: goal), fullscreenDialog: true),
          ),
        ),
        const SizedBox(height: 20),
        _InfoCard(
          title: 'Mi porqué',
          icon: Icons.favorite_rounded,
          onEdit: widget.onEdit,
          child: Text(
            goal.why.isEmpty ? 'Escribe por qué lo dejas. Te dará fuerza en los momentos difíciles.' : goal.why,
            style: TextStyle(
              height: 1.4,
              color: goal.why.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Mis planes',
          icon: Icons.route_rounded,
          onEdit: widget.onEdit,
          child: goal.plans.isEmpty
              ? const Text(
                  'Prepara qué harás en tus momentos de riesgo: "Si…, entonces…".',
                  style: TextStyle(color: AppColors.textMuted, height: 1.4),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in goal.plans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text.rich(TextSpan(children: [
                          const TextSpan(
                            text: 'Si ',
                            style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: p.ifText),
                          const TextSpan(
                            text: ' → ',
                            style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: p.thenText),
                        ])),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _PatternsCard(stats: stats),
        const SizedBox(height: 20),
        const Text('Hitos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in recoveryMilestones)
              Chip(
                avatar: Icon(
                  stats.currentStreakDays >= m ? Icons.star_rounded : Icons.star_border_rounded,
                  color: stats.currentStreakDays >= m ? AppColors.yellow : AppColors.textMuted,
                  size: 18,
                ),
                label: Text('$m d'),
                backgroundColor:
                    stats.currentStreakDays >= m ? AppColors.orangeDeep : AppColors.surface,
                side: BorderSide.none,
              ),
          ],
        ),
        if (events.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Últimos registros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final e in events) _EventTile(event: e),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => showSlipSheet(context, goal),
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Registrar un desliz'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 20),
        const _HelpCard(),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final RecoveryGoal goal;
  final RecoveryStats stats;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _StreakCard({
    required this.goal,
    required this.stats,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final days = stats.currentStreakDays;
    final hours = stats.currentStreak.inHours % 24;
    final next = stats.nextMilestone;
    final previous = stats.lastMilestone;
    final progress = next == null
        ? 1.0
        : (stats.currentStreak.inMinutes / Duration.minutesPerDay - previous) / (next - previous);

    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                onSelected: (v) => v == 'edit' ? onEdit() : onArchive(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'archive', child: Text('Archivar')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ProgressRing(
                value: progress.clamp(0, 1).toDouble(),
                size: 120,
                stroke: 12,
                semanticsLabel: 'Progreso hacia el próximo hito',
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$days',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, height: 1),
                    ),
                    Text(
                      days == 1 ? 'día' : 'días',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$days d $hours h',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const Text('de racha actual', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Text(
                      next == null
                          ? '¡Superaste todos los hitos!'
                          : 'Próximo hito: $next días',
                      style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Desde ${formatDate(goal.startedAt)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.orange, size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SosButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: const LinearGradient(colors: [Color(0xFF1B9C90), AppColors.teal]),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      child: const Row(
        children: [
          Icon(Icons.waves_rounded, size: 34, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tengo una urgencia',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  'Te acompaño a dejarla pasar',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onEdit;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.textMuted),
                tooltip: 'Editar',
                onPressed: onEdit,
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.only(right: 8), child: child),
        ],
      ),
    );
  }
}

class _PatternsCard extends StatelessWidget {
  final RecoveryStats stats;

  const _PatternsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final part = stats.riskiestDayPart;
    final items = [
      if (stats.topEmotion != null) ('Emoción más frecuente', stats.topEmotion!),
      if (stats.topTrigger != null) ('Situación de más riesgo', stats.topTrigger!),
      if (part != null) ('Momento del día', 'la ${RecoveryStats.dayPartNames[part]}'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: AppColors.orange, size: 20),
              SizedBox(width: 8),
              Text('Tus patrones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'Cuando registres urgencias o deslices, aquí verás cuándo y por qué '
              'aparecen, para que prepares mejores planes.',
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            )
          else ...[
            for (final (label, value) in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            const Text(
              '💡 Crea un plan "si… entonces…" para tu situación de más riesgo.',
              style: TextStyle(color: AppColors.yellow, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventTile extends ConsumerWidget {
  final RecoveryEvent event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSlip = event.kind == RecoveryEventKind.slip;
    final time = TimeOfDay.fromDateTime(event.at).format(context);
    final details = [event.emotion, event.trigger, event.note].whereType<String>().join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSlip ? Icons.replay_rounded : Icons.waves_rounded,
        color: isSlip ? AppColors.coral : AppColors.teal,
      ),
      title: Text(
        isSlip ? 'Desliz' : 'Urgencia superada${event.intensity != null ? ' (${event.intensity}/10)' : ''}',
      ),
      subtitle: Text(
        '${formatDate(event.at)} $time${details.isEmpty ? '' : '\n$details'}',
        style: const TextStyle(color: AppColors.textMuted),
      ),
      isThreeLine: details.isNotEmpty,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
        tooltip: 'Borrar registro',
        onPressed: () => ref.read(recoveryProvider.notifier).deleteEvent(event.id),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Necesitas más apoyo?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text(
            'StepMind te acompaña, pero no reemplaza a un profesional. Si sientes que no '
            'puedes solo, un psicólogo que trabaje con terapia cognitivo-conductual o de '
            'aceptación y compromiso (ACT) puede ayudarte mucho. Pedir ayuda es un acto de fuerza.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
