import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../domain/recovery.dart';
import '../../domain/recovery_content.dart';
import '../../providers/providers.dart';

/// Crea o edita una meta: qué dejar, desde cuándo, "mi porqué" y planes.
class RecoverySetupScreen extends ConsumerStatefulWidget {
  final RecoveryGoal? goal;

  const RecoverySetupScreen({super.key, this.goal});

  @override
  ConsumerState<RecoverySetupScreen> createState() => _RecoverySetupScreenState();
}

class _PlanControllers {
  final TextEditingController ifText;
  final TextEditingController thenText;

  _PlanControllers([IfThenPlan? plan])
      : ifText = TextEditingController(text: plan?.ifText),
        thenText = TextEditingController(text: plan?.thenText);

  void dispose() {
    ifText.dispose();
    thenText.dispose();
  }
}

class _RecoverySetupScreenState extends ConsumerState<RecoverySetupScreen> {
  late final TextEditingController _name;
  late final TextEditingController _why;
  late DateTime _startedAt;
  late final List<_PlanControllers> _plans;
  bool _saving = false;

  bool get _editing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _name = TextEditingController(text: goal?.name);
    _why = TextEditingController(text: goal?.why);
    _startedAt = goal?.startedAt ?? ref.read(clockProvider)();
    _plans = [for (final p in goal?.plans ?? const <IfThenPlan>[]) _PlanControllers(p)];
    if (_plans.isEmpty) _plans.add(_PlanControllers());
  }

  @override
  void dispose() {
    _name.dispose();
    _why.dispose();
    for (final p in _plans) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _pickStart() async {
    final now = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startedAt.isAfter(now) ? now : _startedAt,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: '¿Desde cuándo?',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );
    if (picked == null) return;
    final isToday = isSameDay(picked, now);
    setState(() => _startedAt = isToday ? now : picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe o elige qué quieres dejar')),
      );
      return;
    }
    final plans = [
      for (final p in _plans)
        if (p.ifText.text.trim().isNotEmpty && p.thenText.text.trim().isNotEmpty)
          IfThenPlan(ifText: p.ifText.text.trim(), thenText: p.thenText.text.trim()),
    ];
    setState(() => _saving = true);
    final controller = ref.read(recoveryProvider.notifier);
    final goal = widget.goal;
    if (goal == null) {
      await controller.createGoal(
        name: name,
        startedAt: _startedAt,
        why: _why.text,
        plans: plans,
      );
    } else {
      await controller.saveGoal(
        goal.copyWith(name: name, startedAt: _startedAt, why: _why.text.trim(), plans: plans),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Editar meta' : 'Nueva meta')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SectionTitle('¿Qué quieres dejar?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in recoveryPresets)
                ChoiceChip(
                  label: Text(preset),
                  selected: _name.text == preset,
                  onSelected: (_) => setState(() => _name.text = preset),
                  selectedColor: AppColors.orange,
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'O escríbelo tú'),
            onChanged: (_) => setState(() {}),
          ),
          const _SectionTitle('¿Desde cuándo cuentas?'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available_rounded),
            title: Text(
              isSameDay(_startedAt, now) ? 'Desde hoy' : 'Desde el ${formatDate(_startedAt)}',
            ),
            subtitle: const Text(
              'Si ya llevas días sin hacerlo, elige la fecha',
              style: TextStyle(color: AppColors.textMuted),
            ),
            trailing: const Icon(Icons.edit_calendar_rounded),
            onTap: _pickStart,
          ),
          const _SectionTitle('Mi porqué'),
          const Text(
            'Escribe por qué lo dejas y la persona que quieres ser. Lo verás cuando '
            'más lo necesites.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _why,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Ej.: Quiero tener más energía, ser dueño de mi tiempo y '
                  'construir relaciones reales.',
            ),
          ),
          const _SectionTitle('Mis planes "si… entonces…"'),
          const Text(
            'Piensa en tus momentos de riesgo y decide de antemano qué harás. '
            'Es una de las estrategias con más evidencia para cumplir metas.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _plans.length; i++) _buildPlan(i),
          TextButton.icon(
            onPressed: () => setState(() => _plans.add(_PlanControllers())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Añadir otro plan'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_editing ? 'Guardar cambios' : 'Empezar'),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textMuted),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Estos datos se guardan solo en tu teléfono.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlan(int index) {
    final plan = _plans[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: plan.ifText,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Si…',
                    hintText: 'estoy en la cama con el móvil después de las 23:00',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: plan.thenText,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Entonces…',
                    hintText: 'dejo el móvil cargando fuera del cuarto',
                    counterText: '',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar plan',
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
            onPressed: () => setState(() => _plans.removeAt(index).dispose()),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    );
  }
}
