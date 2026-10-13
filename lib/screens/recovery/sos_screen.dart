import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/recovery.dart';
import '../../domain/recovery_content.dart';
import '../../providers/providers.dart';
import 'slip_sheet.dart';

/// Ayuda en el momento de la urgencia. Basado en ACT y "urge surfing":
/// no pelear con la urgencia, observarla hasta que baje y actuar según tus
/// valores.
class SosScreen extends ConsumerStatefulWidget {
  final RecoveryGoal goal;

  const SosScreen({super.key, required this.goal});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  static const _steps = 5;

  int _step = 0;
  double _intensity = 7;
  String? _emotion;
  String? _action;

  void _next() => setState(() => _step++);

  Future<void> _finish({required bool resisted}) async {
    final controller = ref.read(recoveryProvider.notifier);
    if (resisted) {
      await controller.logEvent(
        goalId: widget.goal.id,
        kind: RecoveryEventKind.urge,
        intensity: _intensity.round(),
        emotion: _emotion,
        resisted: true,
        note: _action,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¡Lo lograste! 🌊'),
          content: const Text(
            'Surfeaste la ola sin dejar que te arrastrara. Cada vez que lo haces, '
            'la siguiente es un poco más fácil.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Seguir')),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } else {
      final saved = await showSlipSheet(context, widget.goal, initialEmotion: _emotion);
      if (saved && mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.petrol900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Momento de calma'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Salir',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.petrolGradient),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(
                  value: (_step + 1) / _steps,
                  color: AppColors.teal,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() => switch (_step) {
        0 => _IntensityStep(
            intensity: _intensity,
            emotion: _emotion,
            onIntensity: (v) => setState(() => _intensity = v),
            onEmotion: (e) => setState(() => _emotion = _emotion == e ? null : e),
            onNext: _next,
          ),
        1 => _BreathingStep(onNext: _next),
        2 => _SurfStep(onNext: _next),
        3 => _WhyStep(goal: widget.goal, onNext: _next),
        _ => _ActionStep(
            selected: _action,
            onSelect: (a) => setState(() => _action = a),
            onResisted: () => _finish(resisted: true),
            onSlipped: () => _finish(resisted: false),
          ),
      };
}

class _StepLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final String buttonLabel;
  final VoidCallback? onButton;

  const _StepLayout({
    required this.title,
    required this.child,
    this.subtitle,
    this.buttonLabel = 'Siguiente',
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
        const SizedBox(height: 24),
        child,
        if (onButton != null) ...[
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
              onPressed: onButton,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ],
    );
  }
}

class _IntensityStep extends StatelessWidget {
  final double intensity;
  final String? emotion;
  final ValueChanged<double> onIntensity;
  final ValueChanged<String> onEmotion;
  final VoidCallback onNext;

  const _IntensityStep({
    required this.intensity,
    required this.emotion,
    required this.onIntensity,
    required this.onEmotion,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      title: 'Estás aquí. Eso ya es un gran paso.',
      subtitle: 'Vamos a dejar pasar esta urgencia juntos. Dura unos minutos.',
      buttonLabel: 'Empezar',
      onButton: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Qué tan fuerte es? ${intensity.round()}/10',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Slider(
            value: intensity,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: AppColors.teal,
            label: '${intensity.round()}',
            onChanged: onIntensity,
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Qué sientes ahora? (opcional)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in recoveryEmotions)
                ChoiceChip(
                  label: Text(e),
                  selected: emotion == e,
                  selectedColor: AppColors.teal,
                  onSelected: (_) => onEmotion(e),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Respiración 4-6: exhalar más largo que inhalar calma el cuerpo.
class _BreathingStep extends StatefulWidget {
  final VoidCallback onNext;

  const _BreathingStep({required this.onNext});

  @override
  State<_BreathingStep> createState() => _BreathingStepState();
}

class _BreathingStepState extends State<_BreathingStep> with SingleTickerProviderStateMixin {
  static const _inhale = 4;
  static const _exhale = 6;
  static const _cycles = 6;

  late final AnimationController _controller;
  int _cycle = 0;
  Timer? _timer;
  int _secondsLeft = (_inhale + _exhale) * _cycles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _inhale),
      reverseDuration: const Duration(seconds: _exhale),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          setState(() => _cycle++);
          if (_cycle < _cycles) _controller.forward();
        }
      });
    _controller.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0) setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _cycle >= _cycles;
    return _StepLayout(
      title: 'Respira conmigo',
      subtitle: 'Inhala mientras el círculo crece, exhala lentamente mientras se encoge.',
      buttonLabel: done ? 'Siguiente' : 'Saltar',
      onButton: widget.onNext,
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_controller.value);
                  final inhaling = _controller.status == AnimationStatus.forward;
                  return Semantics(
                    liveRegion: true,
                    label: done ? 'Respiración terminada' : (inhaling ? 'Inhala' : 'Exhala'),
                    child: Container(
                      width: 120 + 120 * t,
                      height: 120 + 120 * t,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.teal.withValues(alpha: 0.25 + 0.35 * t),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.4),
                            blurRadius: 40 * t + 10,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        done ? 'Bien hecho' : (inhaling ? 'Inhala' : 'Exhala'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Text(
            done ? 'Listo' : '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _SurfStep extends StatelessWidget {
  final VoidCallback onNext;

  const _SurfStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    const tips = [
      ('🌊', 'Una urgencia es como una ola: sube, llega a un pico y baja. No tienes que hacer nada para que pase.'),
      ('👀', 'Obsérvala con curiosidad. ¿En qué parte del cuerpo la sientes? ¿Cómo es: calor, tensión, inquietud?'),
      ('🏷️', 'Ponle nombre: "Estoy teniendo una urgencia". Tú no eres la urgencia; la estás viendo pasar.'),
      ('🤲', 'No la pelees ni la obedezcas. Déjala estar, y sigue respirando despacio.'),
    ];
    return _StepLayout(
      title: 'Surfea la ola',
      subtitle: 'Lee despacio. Tómate tu tiempo en cada punto.',
      onButton: onNext,
      child: Column(
        children: [
          for (final (emoji, text) in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(text, style: const TextStyle(fontSize: 16, height: 1.45)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WhyStep extends StatelessWidget {
  final RecoveryGoal goal;
  final VoidCallback onNext;

  const _WhyStep({required this.goal, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      title: 'Recuerda tu porqué',
      onButton: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.yellow.withValues(alpha: 0.5)),
            ),
            child: Text(
              goal.why.isEmpty
                  ? 'Aún no escribiste tu porqué. Piensa: ¿qué ganarás al dejar esto? '
                      '¿Quién quieres ser? Luego escríbelo editando tu meta.'
                  : goal.why,
              style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w600),
            ),
          ),
          if (goal.plans.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Tus planes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final plan in goal.plans)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(
                      text: 'Si ',
                      style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: plan.ifText),
                    const TextSpan(
                      text: ', entonces ',
                      style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: plan.thenText),
                  ]),
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onResisted;
  final VoidCallback onSlipped;

  const _ActionStep({
    required this.selected,
    required this.onSelect,
    required this.onResisted,
    required this.onSlipped,
  });

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      title: 'Ahora, muévete',
      subtitle: 'Cambiar de lugar o de estado físico corta el impulso. Elige una y hazla ya.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (emoji, text) in recoveryActions)
                ChoiceChip(
                  label: Text('$emoji  $text'),
                  selected: selected == text,
                  selectedColor: AppColors.teal,
                  onSelected: (_) => onSelect(text),
                ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            '¿Cómo terminó?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
              onPressed: onResisted,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('La urgencia pasó'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: onSlipped,
            child: const Text('Recaí (sin juzgarte)'),
          ),
        ],
      ),
    );
  }
}
