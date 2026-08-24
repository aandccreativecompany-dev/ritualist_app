import 'package:flutter/material.dart';

import 'notifications.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notifications.instance.init();
  await store.load();
  runApp(const PrakriyaApp());
}

class PrakriyaApp extends StatelessWidget {
  const PrakriyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          title: 'Prakriyā',
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

/// Swaps between onboarding, an app-wide PIN/biometric relock, and the home
/// screen as `store` changes and as the app moves through the foreground/
/// background lifecycle.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> with WidgetsBindingObserver {
  late bool _locked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Lock immediately on a cold start too, not just when returning from
    // the background — otherwise a PIN that's never been challenged reads
    // as broken.
    _locked = store.hasPin && store.onboardingComplete;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        store.hasPin &&
        store.onboardingComplete) {
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.onboardingComplete) {
          return OnboardingScreen(onDone: () {});
        }
        if (_locked && store.hasPin) {
          return LockScreen(
            mode: LockMode.unlock,
            onUnlocked: () => setState(() => _locked = false),
          );
        }
        return const HomeScreen();
      },
    );
  }
}
