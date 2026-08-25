import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Weekly goals — a separate list from the daily to-do list, for things
/// that span the whole week. Newest goal appears on top as a card.
class WeeklyGoalsScreen extends StatefulWidget {
  const WeeklyGoalsScreen({super.key});

  @override
  State<WeeklyGoalsScreen> createState() => _WeeklyGoalsScreenState();
}

class _WeeklyGoalsScreenState extends State<WeeklyGoalsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_controller.text.trim().isEmpty) return;
    await store.addWeeklyGoal(_controller.text);
    _controller.clear();
    if (mounted) {
      FocusScope.of(context).unfocus();
      toastSaved(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final goals = store.weeklyGoals;
        return Scaffold(
          body: Container(
            decoration: Surfaces.pageBackground(dark),
            child: SafeArea(
              child: FadeSlideIn(
                child: Column(
                  children: [
                    ScreenHeader(
                      icon: Icons.sports_score_rounded,
                      title: 'Weekly goals',
                      subtitle: "Bigger than a day, smaller than a month.",
                      actions: [
                        IconButton(
                          onPressed: () => toastSaved(context, label: 'All saved'),
                          icon: Icon(Icons.save_outlined, color: Surfaces.accent(dark)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              onSubmitted: (_) => _add(),
                              textCapitalization: TextCapitalization.sentences,
                              style: body(14.5, Surfaces.bodyText(dark),
                                  weight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'Add a goal for this week',
                                hintStyle: body(14, Surfaces.muted(dark)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _add,
                            icon: Icon(Icons.add_circle,
                                color: Surfaces.accent(dark), size: 30),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: goals.isEmpty
                          ? Center(
                              child: Text('No weekly goals yet.',
                                  style: body(13, Surfaces.muted(dark))),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                              itemCount: goals.length,
                              itemBuilder: (context, i) {
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(milliseconds: 220 + i * 40),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, t, child) => Transform.translate(
                                    offset: Offset(0, (1 - t.clamp(0, 1)) * 10),
                                    child: Opacity(opacity: t.clamp(0, 1), child: child),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ModuleCard(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          CheckSquare(
                                            checked: goals[i].done,
                                            onTap: () async {
                                              await store.toggleWeeklyGoal(i);
                                              if (context.mounted) toastSaved(context);
                                            },
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Text(
                                              goals[i].title,
                                              style: body(
                                                14.5,
                                                goals[i].done
                                                    ? Surfaces.muted(dark)
                                                    : Surfaces.bodyText(dark),
                                                weight: FontWeight.w500,
                                              ).copyWith(
                                                decoration: goals[i].done
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () async {
                                              await store.removeWeeklyGoal(i);
                                              if (context.mounted) {
                                                toastSaved(context, label: 'Removed');
                                              }
                                            },
                                            icon: Icon(Icons.close,
                                                size: 16, color: Surfaces.muted(dark)),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
