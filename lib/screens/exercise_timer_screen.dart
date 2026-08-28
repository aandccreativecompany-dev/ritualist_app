import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// A simple in-workout interval bell — pick how often it should chime
/// (every 30s up to every 10 minutes), start it, and it rings (system
/// sound + haptic) on every interval until stopped. Good for stretch
/// breaks, HIIT rounds, or just a "still moving?" nudge during a workout.
/// The chosen interval is remembered for next time.
class ExerciseTimerScreen extends StatefulWidget {
  const ExerciseTimerScreen({super.key});

  @override
  State<ExerciseTimerScreen> createState() => _ExerciseTimerScreenState();
}

const _kIntervalOptions = [30, 60, 120, 180, 300, 600]; // seconds

class _ExerciseTimerScreenState extends State<ExerciseTimerScreen> {
  Timer? _ticker;
  bool _running = false;
  int _elapsedInIntervalSeconds = 0;
  int _bellCount = 0;
  late int _intervalSeconds = store.exerciseBellIntervalSeconds;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    _ticker?.cancel();
    setState(() {
      _running = true;
      _elapsedInIntervalSeconds = 0;
      _bellCount = 0;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedInIntervalSeconds += 1;
        if (_elapsedInIntervalSeconds >= _intervalSeconds) {
          _elapsedInIntervalSeconds = 0;
          _bellCount += 1;
          _ringBell();
        }
      });
    });
  }

  void _ringBell() {
    // No custom audio asset is bundled, so the system alert sound + a
    // firm haptic buzz stands in for a "bell" — audible and unmistakable
    // without adding an asset/dependency.
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
  }

  void _stop() {
    _ticker?.cancel();
    setState(() {
      _running = false;
      _elapsedInIntervalSeconds = 0;
    });
  }

  Future<void> _setInterval(int seconds) async {
    setState(() => _intervalSeconds = seconds);
    await store.setExerciseBellInterval(seconds);
    if (_running) _start(); // restart the countdown cleanly on the new interval
  }

  String _label(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final remaining = (_intervalSeconds - _elapsedInIntervalSeconds).clamp(0, _intervalSeconds);
    final progress = _intervalSeconds == 0 ? 0.0 : _elapsedInIntervalSeconds / _intervalSeconds;

    return Scaffold(
      body: Container(
        decoration: Surfaces.pageBackground(dark),
        child: SafeArea(
          child: FadeSlideIn(
            child: Column(
              children: [
                const ScreenHeader(
                  icon: Icons.timer_outlined,
                  title: 'Exercise interval bell',
                  subtitle: 'A bell rings on every interval — stretch breaks, HIIT rounds, or a move-now nudge.',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 220,
                                height: 220,
                                child: CircularProgressIndicator(
                                  value: _running ? progress : 0,
                                  strokeWidth: 10,
                                  backgroundColor: Surfaces.cardBorder(dark),
                                  valueColor: AlwaysStoppedAnimation(Surfaces.accent(dark)),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_running ? '${remaining}s' : _label(_intervalSeconds),
                                      style: display(34, Surfaces.heading(dark))),
                                  const SizedBox(height: 6),
                                  Text(
                                    _running
                                        ? (_bellCount == 0
                                            ? 'until the first bell'
                                            : '$_bellCount ${_bellCount == 1 ? 'bell' : 'bells'} so far')
                                        : 'tap start when ready',
                                    style: body(12, Surfaces.muted(dark)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text('BELL EVERY', style: label(Surfaces.eyebrow(dark))),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final seconds in _kIntervalOptions)
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _setInterval(seconds),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: _intervalSeconds == seconds
                                        ? Surfaces.accent(dark).withValues(alpha: 0.16)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _intervalSeconds == seconds
                                          ? Surfaces.accent(dark)
                                          : Surfaces.accentBorder(dark),
                                      width: _intervalSeconds == seconds ? 1.4 : 1,
                                    ),
                                  ),
                                  child: Text(_label(seconds),
                                      style: body(13,
                                          _intervalSeconds == seconds
                                              ? Surfaces.accent(dark)
                                              : Surfaces.bodyText(dark),
                                          weight: FontWeight.w700)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        if (!_running)
                          GoldButton(labelText: 'Start', onPressed: _start)
                        else
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _stop,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Stop',
                                  style: TextStyle(
                                      color: Colors.redAccent, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
