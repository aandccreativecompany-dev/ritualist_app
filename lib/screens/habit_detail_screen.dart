import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HabitDetailScreen extends StatelessWidget {
  final Habit habit;
  const HabitDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final streak = habit.streak(today);
        final last30 = habit.completionsInLast(30, today);

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
                        icon: Icon(Icons.arrow_back,
                            color: Surfaces.bodyText(dark)),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () async {
                          await store.removeHabit(habit);
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: Icon(Icons.delete_outline,
                            color: Surfaces.muted(dark)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(habit.name, style: display(26, Surfaces.heading(dark))),
                  const SizedBox(height: 6),
                  Text('Every day', style: body(12.5, Surfaces.muted(dark))),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _Stat(
                              value: '$streak',
                              caption: streak == 1 ? 'day streak' : 'day streak')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _Stat(
                              value: '$last30',
                              caption: 'of the last 30')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ModuleCard(
                    eyebrow: 'Last five weeks',
                    child: _Grid(habit: habit),
                  ),
                  const SizedBox(height: 20),
                  GoldButton(
                    labelText: habit.isDoneOn(today)
                        ? 'Undo today'
                        : 'Mark done today',
                    onPressed: () => store.toggleHabit(habit),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
          Text(value, style: display(30, Surfaces.accent(dark))),
          const SizedBox(height: 6),
          Text(caption, style: body(12, Surfaces.muted(dark))),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final Habit habit;
  const _Grid({required this.habit});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final cells = <Widget>[];

    for (var i = 34; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      final done = habit.isDoneOn(day);
      cells.add(Container(
        decoration: BoxDecoration(
          color: done
              ? Surfaces.accent(dark)
              : Surfaces.muted(dark).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(5),
        ),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}
