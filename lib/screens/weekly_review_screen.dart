import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// A once-a-week look back at the last 7 days (design ref 2k).
class WeeklyReviewScreen extends StatelessWidget {
  const WeeklyReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final m = store.weeklyMomentum();
    final priorityRate =
        m.prioritiesTotal == 0 ? 0.0 : m.prioritiesDone / m.prioritiesTotal;
    final habitRate = m.habitPossible == 0 ? 0.0 : m.habitChecks / m.habitPossible;

    return Scaffold(
      body: Container(
        decoration: Surfaces.pageBackground(dark),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: Surfaces.bodyText(dark)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Weekly momentum', style: display(24, Surfaces.heading(dark))),
              const SizedBox(height: 6),
              Text('The last 7 days, today included.',
                  style: body(13, Surfaces.muted(dark))),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      value: '${m.prioritiesDone}/${m.prioritiesTotal}',
                      caption: 'priorities finished',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(
                      value: '${m.bestStreak}',
                      caption: m.bestStreak == 1 ? 'day best streak' : 'day best streak',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ModuleCard(
                eyebrow: 'How the week filled in',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bar(
                      label: 'Priorities completed',
                      value: priorityRate,
                      dark: dark,
                    ),
                    const SizedBox(height: 14),
                    _Bar(
                      label: 'Habit check-ins',
                      value: habitRate,
                      dark: dark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ModuleCard(
                eyebrow: 'Worth noticing',
                child: Text(
                  _summaryLine(priorityRate, habitRate, m.bestStreak),
                  style: body(13.5, Surfaces.bodyText(dark)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _summaryLine(double priorityRate, double habitRate, int bestStreak) {
    if (priorityRate == 0 && habitRate == 0) {
      return "Quiet week. Tomorrow's a clean slate — pick three things that would make the day count.";
    }
    if (priorityRate >= 0.7 && habitRate >= 0.7) {
      return 'A strong week across the board. Whatever you\'re doing, it\'s working.';
    }
    if (bestStreak >= 5) {
      return 'Your longest streak this week is $bestStreak days — that\'s the habit that\'s sticking.';
    }
    if (priorityRate > habitRate) {
      return 'Priorities are landing more than habits are. Might be worth trimming to fewer habits for a week.';
    }
    return 'Habits are steadier than priorities this week. Try picking one smaller priority a day.';
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String caption;
  const _Stat({required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ModuleCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: display(26, Surfaces.accent(dark))),
          const SizedBox(height: 6),
          Text(caption, style: body(12, Surfaces.muted(dark))),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double value;
  final bool dark;
  const _Bar({required this.label, required this.value, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: body(13, Surfaces.bodyText(dark), weight: FontWeight.w500)),
            Text('${(value * 100).round()}%',
                style: body(13, Surfaces.accent(dark), weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            backgroundColor: Surfaces.muted(dark).withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation(Surfaces.accent(dark)),
          ),
        ),
      ],
    );
  }
}
