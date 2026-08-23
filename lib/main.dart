import 'package:flutter/material.dart';

import 'notifications.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notifications.instance.init();
  await store.load();
  runApp(const RitualistApp());
}

class RitualistApp extends StatelessWidget {
  const RitualistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          title: 'Ritualist',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: store.themeMode,
          // `home` stays the same const instance across rebuilds — its own
          // AnimatedBuilder below is what actually swaps onboarding for home,
          // so we're not relying on MaterialApp's Navigator ever re-generating
          // the initial route (it won't, once already pushed).
          home: const _Root(),
        );
      },
    );
  }
}

/// Swaps between onboarding and the home screen as `store` changes, without
/// ever asking the Navigator to regenerate its initial route.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.onboardingComplete) {
          return OnboardingScreen(onDone: () {});
        }
        return const HomeScreen();
      },
    );
  }
}
