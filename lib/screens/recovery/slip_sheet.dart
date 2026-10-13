import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/recovery.dart';
import '../../domain/recovery_content.dart';
import '../../providers/providers.dart';

/// Registro de un desliz, sin culpa: qué pasó, para aprender de ello.
/// Devuelve `true` si se guardó.
Future<bool> showSlipSheet(
  BuildContext context,
  RecoveryGoal goal, {
  String? initialEmotion,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.dialog,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _SlipSheet(goal: goal, initialEmotion: initialEmotion),
  );
  if (saved == true && context.mounted) {
    final message = slipCompassionMessages[Random().nextInt(slipCompassionMessages.length)];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  return saved ?? false;
}

class _SlipSheet extends ConsumerStatefulWidget {
  final RecoveryGoal goal;
  final String? initialEmotion;

  const _SlipSheet({required this.goal, this.initialEmotion});

  @override
  ConsumerState<_SlipSheet> createState() => _SlipSheetState();
}

class _SlipSheetState extends ConsumerState<_SlipSheet> {
  final _note = TextEditingController();
  String? _emotion;
  String? _situation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _emotion = widget.initialEmotion;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(recoveryProvider.notifier).logEvent(
          goalId: widget.goal.id,
          kind: RecoveryEventKind.slip,
          emotion: _emotion,
          trigger: _situation,
          note: _note.text,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  Widget _chips(List<String> options, String? selected, ValueChanged<String?> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(o),
            selected: selected == o,
            onSelected: (_) => onChanged(selected == o ? null : o),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Está bien. Aprendamos de esto.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tus días limpios no se borran. Registrar qué pasó te ayuda a ver tus '
              'patrones y preparar mejores planes.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            const Text('¿Qué sentías?', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _chips(recoveryEmotions, _emotion, (v) => setState(() => _emotion = v)),
            const SizedBox(height: 20),
            const Text('¿Dónde o cuándo pasó?', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _chips(recoverySituations, _situation, (v) => setState(() => _situation = v)),
            const SizedBox(height: 20),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: '¿Qué harías distinto la próxima vez? (opcional)',
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: const Text('Guardar y seguir adelante'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
