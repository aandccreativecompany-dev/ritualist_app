import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'evening_reflection_screen.dart';
import 'habit_detail_screen.dart';
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

const _moods = [
  ('Rough', '😔'),
  ('Meh', '😕'),
  ('Okay', '😐'),
  ('Good', '🙂'),
  ('Amazing', '🤩'),
];

/// Small "Saved." toast — a light, consistent confirmation after any quick
/// edit (add/remove/rename a habit, add a priority, pin a vision item…)
/// so saving never feels invisible, without forcing a manual save step for
/// every tiny action.
void toastSaved(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(milliseconds: 1100),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Brand.deep,
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle, color: Brand.gold, size: 16),
          SizedBox(width: 8),
          Text('Saved', style: TextStyle(color: Colors.white)),
        ],
      ),
    ));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDailyPrompts());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _maybeShowDailyPrompts() async {
    if (!mounted) return;
    if (store.shouldShowMoodPrompt) {
      await showDialog<void>(
        context: context,
        builder: (_) => const _MoodDialog(),
      );
    }
    if (!mounted) return;
    if (store.shouldShowEveningPrompt) {
      await showDialog<void>(
        context: context,
        builder: (_) => const _EveningPromptDialog(),
      );
    }
  }

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
        final productivityItems = [
          for (final id in kProductivityModuleIds)
            if (visible.contains(id)) _itemFor(id),
        ];
        final outcomeItems = [
          for (final id in kOutcomeModuleIds)
            if (visible.contains(id)) _itemFor(id),
        ];
        final pages = [
          if (productivityItems.isNotEmpty)
            _SectionPage(title: 'Productivity', items: productivityItems),
          if (outcomeItems.isNotEmpty)
            _SectionPage(title: 'Outcome engineering', items: outcomeItems),
        ];

        return Scaffold(
          body: Container(
            decoration: Surfaces.pageBackground(dark),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                    child: _Header(dateLine: dateLine),
                  ),
                  const SizedBox(height: 14),
                  if (visible.contains('mantra'))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: const _MantraCard(),
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: pages.isEmpty
                        ? Center(
                            child: Text('Nothing turned on — check Settings.',
                                style: body(13, Surfaces.muted(dark))),
                          )
                        : AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, _) {
                              return PageView.builder(
                                controller: _pageController,
                                itemCount: pages.length,
                                onPageChanged: (i) => setState(() => _page = i),
                                itemBuilder: (context, i) {
                                  var scale = 1.0;
                                  if (_pageController.position.haveDimensions) {
                                    final delta =
                                        (i - (_pageController.page ?? _page.toDouble()))
                                            .abs()
                                            .clamp(0.0, 1.0);
                                    scale = 1 - (delta * 0.08);
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                                    child: Transform.scale(
                                      scale: scale,
                                      child: pages[i],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  if (pages.length > 1) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < pages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? Surfaces.accent(dark)
                                  : Surfaces.muted(dark).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  const _Footer(),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _itemFor(String id) {
    switch (id) {
      case 'priorities':
        return const _PriorityContent();
      case 'habits':
        return const _HabitsContent();
      case 'tips':
        return const _TipItem();
      case 'eveningReflection':
        return const _EveningReflectionItem();
      case 'reminders':
        return const _ReminderItem();
      case 'scripting':
        return const _ScriptingItem();
      case 'visionBoard':
        return const _VisionBoardItem();
      default:
        return const SizedBox.shrink();
    }
  }
}

/// One swipeable "page" of the home screen — a whole section (Productivity
/// or Outcome engineering) presented as a single card, scrollable inside
/// itself only if its content runs long, so the primary way to move around
/// the app is a horizontal swipe between cards, not one long vertical feed.
class _SectionPage extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SectionPage({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Surfaces.card(dark),
        border: Border.all(color: Surfaces.cardBorder(dark)),
        borderRadius: BorderRadius.circular(26),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title.toUpperCase(), style: label(Surfaces.eyebrow(dark))),
                const Spacer(),
                Icon(Icons.cloud_done_outlined, size: 13, color: Surfaces.muted(dark)),
                const SizedBox(width: 4),
                Text('Saves automatically',
                    style: body(10, Surfaces.muted(dark), weight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < items.length; i++) ...[
              items[i],
              if (i != items.length - 1) ...[
                const SizedBox(height: 18),
                Divider(height: 1, color: Surfaces.cardBorder(dark)),
                const SizedBox(height: 18),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Small header row used by each item inside a section page — an icon,
/// a title, and whatever trailing summary/action the item wants.
class _ItemHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  const _ItemHeader({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: Surfaces.accent(dark), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title,
              style: body(14, Surfaces.heading(dark), weight: FontWeight.w700)),
        ),
        if (trailing != null) trailing!,
      ],
    );
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateLine.toUpperCase(), style: label(Surfaces.muted(dark))),
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
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
          icon:
              Icon(Icons.settings_outlined, color: Surfaces.muted(dark), size: 22),
        ),
      ],
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
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.mantraEntryOfTheDay.text,
                style: display(17, Surfaces.accentText(dark)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text('— ${store.mantraEntryOfTheDay.source}',
                style: body(11, Surfaces.accentText(dark).withValues(alpha: 0.7),
                    weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline, color: Surfaces.accent(dark), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Productivity tip',
                  style: body(14, Surfaces.heading(dark), weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(store.tipOfTheDay, style: body(13, Surfaces.bodyText(dark))),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriorityContent extends StatefulWidget {
  const _PriorityContent();

  @override
  State<_PriorityContent> createState() => _PriorityContentState();
}

class _PriorityContentState extends State<_PriorityContent> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_controller.text.trim().isEmpty) return;
    await store.addTask(_controller.text);
    _controller.clear();
    if (mounted) {
      FocusScope.of(context).unfocus();
      toastSaved(context);
    }
  }

  Future<void> _remove(int i) async {
    await store.removeTask(i);
    if (mounted) toastSaved(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tasks = store.todaysTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ItemHeader(
            icon: Icons.checklist_rounded, title: "Today's log — top 3"),
        const SizedBox(height: 14),
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
                    onTap: () async {
                      await store.toggleTask(i);
                      if (mounted) toastSaved(context);
                    }),
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
                  onPressed: () => _remove(i),
                  icon: Icon(Icons.close, size: 16, color: Surfaces.muted(dark)),
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
                  style: body(14.5, Surfaces.bodyText(dark), weight: FontWeight.w500),
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
    );
  }
}

/// Habit tracker — each habit is a full-width, softly-gradient "story card"
/// keyed on its stable id (not object identity), so add/remove/edit stay
/// correct no matter what else has rebuilt in between.
class _HabitsContent extends StatelessWidget {
  const _HabitsContent();

  Future<void> _addHabit(BuildContext context) async {
    final result = await showModalBottomSheet<(String, int, int)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HabitEditorSheet(),
    );
    if (result != null) {
      await store.addHabit(result.$1, iconIndex: result.$2, colorIndex: result.$3);
      if (context.mounted) toastSaved(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ItemHeader(icon: Icons.self_improvement, title: 'Habits'),
        const SizedBox(height: 14),
        if (store.habits.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('Nothing tracked yet — add the first one below.',
                style: body(13, Surfaces.muted(dark))),
          ),
        for (final habit in store.habits)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: ValueKey(habit.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 18),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
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
              onDismissed: (_) async {
                await store.removeHabit(habit);
                if (context.mounted) toastSaved(context);
              },
              child: _HabitCard(habit: habit, today: today),
            ),
          ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _addHabit(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Surfaces.accent(dark).withValues(alpha: 0.5),
                width: 1.4,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Surfaces.accent(dark), size: 18),
                const SizedBox(width: 8),
                Text('Add a habit',
                    style: body(13, Surfaces.accent(dark), weight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitCard extends StatefulWidget {
  final Habit habit;
  final DateTime today;
  const _HabitCard({required this.habit, required this.today});

  @override
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard> {
  Future<void> _toggle() async {
    await store.toggleHabit(widget.habit);
    if (mounted) toastSaved(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final habit = widget.habit;
    final color = habitColorFor(habit.colorIndex);
    final done = habit.isDoneOn(widget.today);
    final streak = habit.streak(widget.today);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit))),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: done ? 0.30 : 0.14),
              color.withValues(alpha: done ? 0.12 : 0.05),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            HabitBadge(iconIndex: habit.iconIndex, colorIndex: habit.colorIndex, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.name,
                      style: body(14.5, Surfaces.heading(dark), weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    streak > 0 ? '🔥 $streak day streak' : 'Tap to start a streak',
                    style: body(11.5, Surfaces.muted(dark)),
                  ),
                  const SizedBox(height: 8),
                  _WeekDots(habit: habit, today: widget.today, color: color),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _toggle,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: done ? 1.08 : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? color : Colors.transparent,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done
                      ? const Icon(Icons.check, color: Brand.deep, size: 18)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A week-at-a-glance strip — filled dot for a day this habit was done,
/// hollow for a miss, today ringed — the small daily-progress cue several
/// of the reference trackers use (water glasses, sleep-hour ticks), reworked
/// here as a compact row that fits inline in the habit card.
class _WeekDots extends StatelessWidget {
  final Habit habit;
  final DateTime today;
  final Color color;
  const _WeekDots({required this.habit, required this.today, required this.color});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        for (var i = 6; i >= 0; i--) ...[
          Builder(builder: (context) {
            final day = DateTime(today.year, today.month, today.day)
                .subtract(Duration(days: i));
            final done = habit.isDoneOn(day);
            final isToday = i == 0;
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? color : Colors.transparent,
                border: Border.all(
                  color: done
                      ? color
                      : Surfaces.muted(dark).withValues(alpha: isToday ? 0.7 : 0.3),
                  width: isToday && !done ? 1.6 : 1,
                ),
              ),
            );
          }),
          if (i != 0) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _ScriptingItem extends StatelessWidget {
  const _ScriptingItem();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final count = store.scripts.length;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ScriptingScreen())),
      child: _ItemHeader(
        icon: Icons.auto_awesome,
        title: 'Scripting',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(count == 0 ? 'Not started' : '$count written',
                style: body(12, Surfaces.muted(dark))),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: Surfaces.muted(dark), size: 18),
          ],
        ),
      ),
    );
  }
}

class _EveningReflectionItem extends StatelessWidget {
  const _EveningReflectionItem();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final done = !store.todaysJournal.isEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      // A single app-wide lock (asked once at launch/resume) is enough —
      // no second PIN gate for a screen you're already inside the app to see.
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const EveningReflectionScreen())),
      child: _ItemHeader(
        icon: Icons.nights_stay_outlined,
        title: 'Evening reflection',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(done ? 'Written for today' : 'Not written yet',
                style: body(12, Surfaces.muted(dark))),
            if (store.hasPin) ...[
              const SizedBox(width: 6),
              Icon(Icons.lock_outline, size: 15, color: Surfaces.muted(dark)),
            ],
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: Surfaces.muted(dark), size: 18),
          ],
        ),
      ),
    );
  }
}

class _VisionBoardItem extends StatelessWidget {
  const _VisionBoardItem();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final count = store.visionItems.length;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const VisionBoardScreen())),
      child: _ItemHeader(
        icon: Icons.grid_view_rounded,
        title: 'Vision board',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(count == 0 ? 'Nothing pinned yet' : '$count pinned',
                style: body(12, Surfaces.muted(dark))),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: Surfaces.muted(dark), size: 18),
          ],
        ),
      ),
    );
  }
}

class _ReminderItem extends StatelessWidget {
  const _ReminderItem();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final on = store.reminders.where((ReminderSetting r) => r.enabled).toList();
    final summary =
        on.isEmpty ? 'Reminders are off' : on.map((r) => r.clockLabel).join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const RemindersScreen())),
      child: _ItemHeader(
        icon: Icons.notifications_none,
        title: 'Daily reminders',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(summary,
                  overflow: TextOverflow.ellipsis, style: body(12, Surfaces.muted(dark))),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: Surfaces.muted(dark), size: 18),
          ],
        ),
      ),
    );
  }
}

/// Morning check-in — a light mood pulse, not a journal. Shown at most once
/// a day, purely informational (feeds nothing else yet beyond the log).
class _MoodDialog extends StatelessWidget {
  const _MoodDialog();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Surfaces.card(dark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How are you feeling this morning?',
                style: display(18, Surfaces.heading(dark))),
            const SizedBox(height: 6),
            Text('A quick pulse-check — takes one tap.',
                style: body(12.5, Surfaces.muted(dark))),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final (moodLabel, emoji) in _moods)
                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () async {
                      await store.setTodaysMood(moodLabel);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () async {
                  await store.recordMoodPromptShown();
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text('Skip for today',
                    style: body(12.5, Surfaces.muted(dark), weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Evening pop-up — the same achievements + gratitude capture as the full
/// Evening reflection screen, surfaced proactively instead of waiting for
/// the user to remember to open it.
class _EveningPromptDialog extends StatefulWidget {
  const _EveningPromptDialog();

  @override
  State<_EveningPromptDialog> createState() => _EveningPromptDialogState();
}

class _EveningPromptDialogState extends State<_EveningPromptDialog> {
  late final List<TextEditingController> _achievements;
  late final TextEditingController _gratitude;

  @override
  void initState() {
    super.initState();
    final entry = store.todaysJournal;
    _achievements = List.generate(
        3, (i) => TextEditingController(text: i < entry.achievements.length ? entry.achievements[i] : ''));
    _gratitude = TextEditingController(text: entry.gratitude);
  }

  @override
  void dispose() {
    for (final c in _achievements) {
      c.dispose();
    }
    _gratitude.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    await store.saveTodaysJournal(
        _achievements.map((c) => c.text).toList(), _gratitude.text);
    await store.recordEveningPromptShown();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _dismiss() async {
    await store.recordEveningPromptShown();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Surfaces.card(dark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Close the day', style: display(18, Surfaces.heading(dark))),
              const SizedBox(height: 4),
              Text('Two minutes — what counted today?',
                  style: body(12.5, Surfaces.muted(dark))),
              const SizedBox(height: 16),
              Text('THREE THINGS I ACHIEVED', style: label(Surfaces.eyebrow(dark))),
              const SizedBox(height: 8),
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TextField(
                    controller: _achievements[i],
                    textCapitalization: TextCapitalization.sentences,
                    style: body(13.5, Surfaces.bodyText(dark)),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixText: '${i + 1}.  ',
                      hintText: 'Something that counted',
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text('GRATEFUL FOR', style: label(Surfaces.eyebrow(dark))),
              const SizedBox(height: 8),
              TextField(
                controller: _gratitude,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: body(13.5, Surfaces.bodyText(dark)),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'What are you grateful for today?',
                ),
              ),
              const SizedBox(height: 18),
              GoldButton(labelText: 'Save', onPressed: _saveAndClose),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: _dismiss,
                  child: Text('Not now',
                      style: body(12.5, Surfaces.muted(dark), weight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Persistent brand footer — copyright plus the two social links, present
/// on the home screen the way it appears on shared mantra cards.
class _Footer extends StatelessWidget {
  const _Footer();

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('© A & C Creative Company',
              style: body(10.5, Surfaces.muted(dark), weight: FontWeight.w600)),
          const SizedBox(width: 10),
          _SocialIcon(
            icon: Icons.camera_alt_outlined,
            onTap: () => _open('https://www.instagram.com/aandccreativecompany/'),
          ),
          const SizedBox(width: 8),
          _SocialIcon(
            icon: Icons.play_circle_outline,
            onTap: () => _open('https://www.youtube.com/@aandccreativecompany'),
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 15, color: Surfaces.muted(dark)),
      ),
    );
  }
}
