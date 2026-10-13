import 'package:flutter_test/flutter_test.dart';

import 'package:stepmind/main.dart';

void main() {
  testWidgets('Splash muestra la marca y luego navega al login', (tester) async {
    await tester.pumpWidget(const StepMindApp());

    expect(find.text('StepMind'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsNothing);

    // El splash navega al login tras 2 segundos.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
