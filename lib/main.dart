import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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

/// Users reported the app going blank after extended use. In a release
/// build, Flutter's *default* response to an uncaught error escaping a
/// widget's build — or to an uncaught error on an async callback outside
/// any build (a Timer, a notification callback, a Future) — is either a
/// bare grey box in place of just that widget, or, if it happens high
/// enough in the tree, the whole screen going blank with nothing logged
/// anywhere the user can see. Neither of those is a fix for whatever the
/// underlying bug turns out to be, but both turn "the app is dead, I have
/// to force-quit it" into "there's a recoverable error screen with a
/// button" — which is the actual, reportable symptom here. This is a
/// safety net, not a substitute for fixing root causes when a specific one
/// is found (a few were, in this same pass — see FinanceRoadmap and the
/// reminders JSON parsing).
void _installErrorHandling() {
  ErrorWidget.builder = (FlutterErrorDetails details) => _CrashScreen(details: details);
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Handled framework error: ${details.exceptionAsString()}');
  };
}

Future<void> main() async {
  _installErrorHandling();
  // Catches errors that happen outside the widget-build path entirely —
  // inside a Timer callback, a notification handler, an awaited Future's
  // continuation — which FlutterError.onError above does not see. Without
  // this, one of those can silently kill event processing for the whole
  // app (which reads to a user as "it just went blank and stopped
  // responding") with nothing ever shown on screen.
  runZonedGuarded(() async {
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
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

/// Shown in place of whatever widget crashed, instead of the default blank/
/// grey box. Tapping "Reload" pops back to the app's root route, which is
/// enough to recover from almost anything that isn't a genuine startup
/// failure (this screen only ever replaces ONE widget's subtree, so the
/// Navigator above it is still alive).
class _CrashScreen extends StatelessWidget {
  final FlutterErrorDetails details;
  const _CrashScreen({required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B0F33),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, color: Color(0xFFF2B93B), size: 34),
                const SizedBox(height: 16),
                const Text('Something went wrong',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                  "This part of the app hit a snag. Your data is safe — tap below to continue.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB8AFCF), fontSize: 13, height: 1.4),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 14),
                  Text(details.exceptionAsString(),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF8A7BB5), fontSize: 10.5)),
                ],
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: () {
                    final nav = Navigator.maybeOf(context);
                    if (nav != null && nav.canPop()) {
                      nav.popUntil((r) => r.isFirst);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2B93B),
                    foregroundColor: const Color(0xFF1B0F33),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  child: const Text('Reload', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
