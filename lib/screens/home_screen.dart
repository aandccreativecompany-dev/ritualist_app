import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'evening_reflection_screen.dart';
import 'habit_detail_screen.dart';
import 'lock_screen.dart';
import 'quote_screen.dart';
import 'reminders_screen.dart';
import 'scripting_screen.dart';
import 'settings_screen.dart';
import 'vision_board_screen.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final dateLine =
        '${_dayNames[today.weekday - 1]} ${today.day} ${_monthNames[today.month - 1]}';

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final visible = store.visibleModuleIds;
        return Scaffold(
          body: Container(
            decoration: Surfaces.pageBackground(dark),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                children: [
                  _Header(dateLine: dateLine),
                  const SizedBox(height: 18),
                  for (final id in visible) ...[
                    _moduleFor(id),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _moduleFor(String id) {
    switch (id) {
      case 'mantra':
        return const _MantraCard();
      case 'priorities':
        return const _PriorityCard();
      case 'habits':
        return const _HabitsCard();
      case 'scripting':
        return const _ScriptingCard();
      case 'eveningReflection':
        return const _EveningReflectionRow();
      case 'visionBoard':
        return const _VisionBoardRow();
      case 'reminders':
        return const _ReminderCard();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _Header extends StatelessWidget {
  final String dateLine;
  const _Header({required this.dateLine});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final done = store.todaysTasks.where((t) => t.done).length;
    final total = store.todaysTasks.length;
    final greeting = _greeting();
    final name = store.userName;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateLine.toUpperCase(),
                    style: label(Surfaces.muted(dark))),
                const SizedBox(height: 8),
                Text(name.isEmpty ? greeting : '$greeting, $name',
                    style: display(26, Surfaces.heading(dark))),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'Nothing set yet'
                      : '$done of $total priorities · ${store.habitsDoneToday} of ${store.habits.length} habits',
                  style: body(12.5, Surfaces.muted(dark)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SettingsScreen())),
            icon: Icon(Icons.settings_outlined,
                color: Surfaces.muted(dark), size: 22),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Still up';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Winding down';
  }
}

class _MantraCard extends StatelessWidget {
  const _MantraCard();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const QuoteScreen())),
      child: ModuleCard(
        accent: true,
        eyebrow: 'Mantra of the day',
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.mantraEntryOfTheDay.text,
                style: display(19, Surfaces.accentText(dark))),
            const SizedBox(height: 10),
            Text('— ${store.mantraEntryOfTheDay.source}',
                style: body(11.5, Surfaces.accentText(dark).withValues(alpha: 0.7),
                    weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _PriorityCard extends StatefulWidget {
  const _PriorityCard();

  @override
  State<_PriorityCard> createState() => _PriorityCardState();
}

class _PriorityCardState extends State<_PriorityCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    await store.addTask(_controller.text);
    _controller.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tasks = store.todaysTasks;

    return ModuleCard(
      eyebrow: 'Your day, in three',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top 3 today', style: display(16, Surfaces.heading(dark))),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            Text('Pick three things that would make today count.',
                style: body(13.5, Surfaces.muted(dark))),
          for (var i = 0; i < tasks.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  CheckSquare(
                      checked: tasks[i].done,
                      onTap: () => store.toggleTask(i)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      tasks[i].title,
                      style: body(14.5,
                          tasks[i].done
                              ? Surfaces.muted(dark)
                              : Surfaces.bodyText(dark),
                          weight: FontWeight.w500).copyWith(
                        decoration: tasks[i].done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => store.removeTask(i),
                    icon: Icon(Icons.close,
                        size: 16, color: Surfaces.muted(dark)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          if (tasks.length < 3) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _add(),
                    textCapitalization: TextCapitalization.sentences,
                    style: body(14.5, Surfaces.bodyText(dark),
                        weight: FontWeight.w500),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Add a priority',
                      hintStyle: body(14, Surfaces.muted(dark)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _add,
                  icon: Icon(Icons.add, color: Surfaces.accent(dark)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HabitsCard extends StatelessWidget {
  const _HabitsCard();

  Future<void> _addHabit(BuildContext context) async {
    final result = await showModalBottomSheet<(String, int, int)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HabitEditorSheet(),
    );
    if (result != null) {
      await store.addHabit(result.$1, iconIndex: result.$2, colorIndex: result.$3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();

    return ModuleCard(
      eyebrow: 'Habits',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (store.habits.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Nothing tracked yet — add the first one below.',
                  style: body(13, Surfaces.muted(dark))),
            ),
          for (final habit in store.habits)
            Dismissible(
              key: ValueKey(habit),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.delete_outline, color: Colors.redAccent.withValues(alpha: 0.8)),
              ),
              confirmDismiss: (_) => showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Remove "${habit.name}"?',
                      style: display(16, Surfaces.heading(dark))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Keep it')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Remove')),
                  ],
                ),
              ),
              onDismissed: (_) => store.removeHabit(habit),
              child: InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => HabitDetailScreen(habit: habit))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      HabitBadge(iconIndex: habit.iconIndex, colorIndex: habit.colorIndex),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(habit.name,
                            style: body(14, Surfaces.bodyText(dark),
                                weight: FontWeight.w500)),
                      ),
                      Text(
                        habit.streak(today) > 0
                            ? '${habit.streak(today)} day streak'
                            : 'Not yet',
                        style: body(11, Surfaces.muted(dark)),
                      ),
                      const SizedBox(width: 10),
                      CheckSquare(
                        checked: habit.isDoneOn(today),
                        onTap: () => store.toggleHabit(habit),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _addHabit(context),
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                alignment: Alignment.centerLeft),
            child: Text('Add a habit',
                style: body(12.5, Surfaces.accent(dark),
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}


class _ScriptingCard extends StatelessWidget {
  const _ScriptingCard();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final count = store.scripts.length;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ScriptingScreen())),
      child: ModuleCard(
        eyebrow: 'Outcome engineering',
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: Surfaces.accent(dark), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scripting',
                      style: body(14, Surfaces.heading(dark),
                          weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    count == 0 ? 'Not started' : '$count written',
                    style: body(12, Surfaces.muted(dark)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Surfaces.muted(dark)),
          ],
        ),
      ),
    );
  }
}

class _EveningReflectionRow extends StatelessWidget {
  const _EveningReflectionRow();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final done = !store.todaysJournal.isEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final unlocked = await AppLock.ensureUnlocked(context);
        if (unlocked && context.mounted) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const EveningReflectionScreen()));
        }
      },
      child: ModuleCard(
        child: Row(
          children: [
            Icon(Icons.nights_stay_outlined,
                color: Surfaces.accent(dark), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Evening reflection',
                      style: body(14, Surfaces.heading(dark),
                          weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    done ? 'Written for today' : 'Not written yet',
                    style: body(12, Surfaces.muted(dark)),
                  ),
                ],
              ),
            ),
            if (store.hasPin)
              Icon(Icons.lock_outline, size: 15, color: Surfaces.muted(dark)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Surfaces.muted(dark)),
          ],
        ),
      ),
    );
  }
}

class _VisionBoardRow extends StatelessWidget {
  const _VisionBoardRow();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final count = store.visionItems.length;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const VisionBoardScreen())),
      child: ModuleCard(
        child: Row(
          children: [
            Icon(Icons.grid_view_rounded,
                color: Surfaces.accent(dark), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vision board',
                      style: body(14, Surfaces.heading(dark),
                          weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    count == 0 ? 'Nothing pinned yet' : '$count pinned',
                    style: body(12, Surfaces.muted(dark)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Surfaces.muted(dark)),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final on = store.reminders.where((ReminderSetting r) => r.enabled).toList();
    final summary = on.isEmpty
        ? 'Reminders are off'
        : on.map((ReminderSetting r) => r.clockLabel).join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RemindersScreen())),
      child: ModuleCard(
        child: Row(
          children: [
            Icon(Icons.notifications_none,
                color: Surfaces.accent(dark), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily reminders',
                      style: body(14, Surfaces.heading(dark),
                          weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(summary, style: body(12, Surfaces.muted(dark))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Surfaces.muted(dark)),
          ],
        ),
      ),
    );
  }
}
