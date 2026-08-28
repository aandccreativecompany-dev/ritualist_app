import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ritualist/main.dart';
import 'package:ritualist/models.dart';
import 'package:ritualist/store.dart';

void main() {
  testWidgets('App boots to onboarding on first run', (tester) async {
    await tester.pumpWidget(const PrakriyaApp());
    await tester.pump();

    // First run has no onboarding done yet, so the welcome step should show.
    expect(find.text('PRAKRIYĀ'), findsWidgets);
  });

  testWidgets('Home screen renders the Productivity section once onboarded',
      (tester) async {
    // completeOnboarding only touches shared_preferences (not the
    // notifications plugin), so a mocked in-memory store is enough here.
    SharedPreferences.setMockInitialValues({});
    await store.completeOnboarding(
      userName: 'Alex',
      focusAreas: const [],
      dailyTimeCommitment: '15',
      preset: kPresetBalance,
    );

    await tester.pumpWidget(const PrakriyaApp());
    await tester.pumpAndSettle();

    expect(find.text('PRODUCTIVITY'), findsOneWidget);
    expect(find.text('© A and C Creative Ventures'), findsOneWidget);
  });
}
