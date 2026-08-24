import 'package:flutter_test/flutter_test.dart';

import 'package:ritualist/main.dart';

void main() {
  testWidgets('App boots to onboarding on first run', (tester) async {
    await tester.pumpWidget(const PrakriyaApp());
    await tester.pump();

    // First run has no onboarding done yet, so the welcome step should show.
    expect(find.text('PRAKRIYĀ'), findsWidgets);
  });
}
