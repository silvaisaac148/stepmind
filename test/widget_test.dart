import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stepmind/main.dart';

void main() {
  testWidgets('Splash muestra la marca y luego navega al login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: StepMindApp()));

    expect(find.text('StepMind'), findsOneWidget);
    expect(find.text('Continuar sin cuenta'), findsNothing);

    // El splash navega al login tras 2 segundos.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Sin Supabase configurado solo se ofrece usar la app sin cuenta.
    expect(find.text('Continuar sin cuenta'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsNothing);
  });
}
