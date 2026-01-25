import 'package:flutter_test/flutter_test.dart';

import 'package:stepmind/main.dart';

void main() {
  testWidgets('StepMind app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StepMindApp());

    expect(find.text('StepMind'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
