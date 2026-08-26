import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'notifications.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/cloud_sync.dart';
import 'services/home_widget_service.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notifications.instance.init();
  await store.load();
  HomeWidgetService.instance.wire();
  // Firebase reads its config from android/app/google-services.json (baked
  // in at build time) — no explicit FirebaseOptions needed on Android. If
  // it's ever missing (a local dev build without the file), sign-in/sync
  // just won't be available rather than crashing the whole app.
  try {
    await Firebase.initializeApp();
    CloudSync.instance.wire();
    AuthService.instance.userChanges.listen((user) {
      if (user != null) CloudSync.instance.pullAndApply(user.uid);
    });
  } catch (_) {
    // No google-services.json in this build — app still works fully offline.
  }
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
  DateTime? _pausedAt;

  // A brief trip to the background — the system photo picker, the share
  // sheet, a permission dialog, pulling down the notification shade — all
  // pause the app the same way a real backgrounding does. Relocking on
  // every one of those reads as broken (mid-task, suddenly asked for a
  // PIN again), so only relock once the app has actually been away for a
  // while.
  static const _relockGrace = Duration(seconds: 45);

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
    if (!store.hasPin || !store.onboardingComplete) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      if (pausedAt != null &&
          DateTime.now().difference(pausedAt) >= _relockGrace) {
        setState(() => _locked = true);
      }
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
