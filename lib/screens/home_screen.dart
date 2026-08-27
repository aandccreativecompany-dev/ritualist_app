import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'evening_reflection_screen.dart';
import 'habit_detail_screen.dart';
import 'mind_map_screen.dart';
import 'monthly_goals_screen.dart';
import 'quote_screen.dart';
import 'reminders_screen.dart';
import 'scripting_screen.dart';
import 'settings_screen.dart';
import 'todo_list_screen.dart';
import 'vision_board_screen.dart';
import 'weekly_goals_screen.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _hintDismissed = false;
  late final String _mascotGreeting = kMascotGreetings[
      DateTime.now().millisecondsSinceEpoch % kMascotGreetings.length];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDailyPrompts());
    Future.delayed(const Duration(seconds: 5), _dismissHint);
  }

  void _dismissHint() {
    if (_hintDismissed || !mounted) return;
    setState(() => _hintDismissed = true);
    store.markSwipeHintSeen();
  }

  Future<void> _refresh() async {
    await store.load();
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
        final financeItems = [
          for (final id in kFinanceModuleIds)
            if (visible.contains(id)) _itemFor(id),
        ];
        final healthItems = [
          for (final id in kHealthModuleIds)
            if (visible.contains(id)) _itemFor(id),
        ];
        final mindsetItems = [
          for (final id in kMindsetModuleIds)
            if (visible.contains(id)) _itemFor(id),
        ];
        final relationshipsItems = [
          for (final id in kRelationshipsModuleIds)
            if (visible.contains(id)) _itemFor(id),
        ];
        final pages = [
          if (productivityItems.isNotEmpty)
            _SectionPage(title: 'Productivity', items: productivityItems),
          if (outcomeItems.isNotEmpty)
            _SectionPage(title: 'Outcome engineering', items: outcomeItems),
          if (financeItems.isNotEmpty)
            _SectionPage(title: 'Finance & money', items: financeItems),
          if (healthItems.isNotEmpty)
            _SectionPage(title: 'Health & body', items: healthItems),
          if (mindsetItems.isNotEmpty)
            _SectionPage(title: 'Mindset & growth', items: mindsetItems),
          if (relationshipsItems.isNotEmpty)
            _SectionPage(
                title: 'Relationships & connection', items: relationshipsItems),
        ];

        return Scaffold(
          body: Container(
            decoration: Surfaces.pageBackground(dark),
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
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
                            : RefreshIndicator(
                                onRefresh: _refresh,
                                color: Surfaces.accent(dark),
                                child: AnimatedBuilder(
                                  animation: _pageController,
                                  builder: (context, _) {
                                    return PageView.builder(
                                      controller: _pageController,
                                      itemCount: pages.length,
                                      onPageChanged: (i) {
                                        setState(() => _page = i);
                                        _dismissHint();
                                      },
                                      itemBuilder: (context, i) {
                                        var scale = 1.0;
                                        if (_pageController.position.haveDimensions) {
                                          final delta = (i -
                                                  (_pageController.page ??
                                                      _page.toDouble()))
                                              .abs()
                                              .clamp(0.0, 1.0);
                                          scale = 1 - (delta * 0.08);
                                        }
                                        return Padding(
                                          padding:
                                              const EdgeInsets.fromLTRB(18, 0, 18, 4),
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
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Align(
                        alignment: const Alignment(0, -0.05),
                        child: SizedBox(
                          width: double.infinity,
                          height: 118,
                          child: GreetingMascot(
                            avatarGender: store.avatarGender,
                            greeting: _mascotGreeting,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (pages.length > 1 && !store.hasSeenSwipeHint && !_hintDismissed)
                    Positioned(
                      right: 30,
                      bottom: 70,
                      child: IgnorePointer(child: _SwipeHint(dark: dark)),
                    ),
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
        return const _QuickLaunchButtons();
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
      case 'mindMap':
        return const _MindMapItem();
      case 'financeGoals':
        return const _FinanceGoalsContent();
      case 'healthGoals':
        return const _HealthGoalsContent();
      case 'mindsetGoals':
        return const _MindsetGoalsContent();
      case 'relationshipsGoals':
        return const _RelationshipsGoalsContent();
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

/// Three floating quick-launch buttons replacing the old inline "today's
/// log" list — each opens its own full screen (to-do list, weekly goals,
/// monthly goals) with its own add/save/display flow.
class _QuickLaunchButtons extends StatelessWidget {
  const _QuickLaunchButtons();

  @override
  Widget build(BuildContext context) {
    final openTodos = store.todaysTasks.where((t) => !t.done).length;
    final openWeekly = store.weeklyGoals.where((t) => !t.done).length;
    final openMonthly = store.monthlyGoals.where((t) => !t.done).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ItemHeader(icon: Icons.dashboard_customize_outlined, title: 'Goals & to-dos'),
        const SizedBox(height: 14),
        _QuickLaunchButton(
          icon: Icons.edit_note_rounded,
          label: "Today's to-do list",
          summary: openTodos == 0 ? 'All clear' : '$openTodos open',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const TodoListScreen())),
        ),
        const SizedBox(height: 10),
        _QuickLaunchButton(
          icon: Icons.sports_score_rounded,
          label: 'Weekly goals',
          summary: openWeekly == 0 ? 'All clear' : '$openWeekly open',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const WeeklyGoalsScreen())),
        ),
        const SizedBox(height: 10),
        _QuickLaunchButton(
          icon: Icons.calendar_month_rounded,
          label: 'Monthly goals',
          summary: openMonthly == 0 ? 'All clear' : '$openMonthly open',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const MonthlyGoalsScreen())),
        ),
      ],
    );
  }
}

class _QuickLaunchButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String summary;
  final VoidCallback onTap;
  const _QuickLaunchButton({
    required this.icon,
    required this.label,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Surfaces.accent(dark).withValues(alpha: 0.10),
          border: Border.all(color: Surfaces.accent(dark).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Surfaces.accent(dark).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Surfaces.accent(dark), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: body(14, Surfaces.heading(dark), weight: FontWeight.w700)),
            ),
            Text(summary, style: body(11.5, Surfaces.muted(dark))),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: Surfaces.muted(dark), size: 18),
          ],
        ),
      ),
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
        title: 'Journaling (Brain Dump)',
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

class _MindMapItem extends StatelessWidget {
  const _MindMapItem();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const MindMapScreen())),
      child: _ItemHeader(
        icon: Icons.account_tree_outlined,
        title: 'Organized mind map',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Day · week · month',
                style: body(12, Surfaces.muted(dark))),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: Surfaces.muted(dark), size: 18),
          ],
        ),
      ),
    );
  }
}

/// A one-time "swipe for more" nudge — a hand icon that drifts left/right
/// and fades, so first-time users notice the home cards are swipeable
/// instead of assuming Productivity is the whole app.
class _SwipeHint extends StatefulWidget {
  final bool dark;
  const _SwipeHint({required this.dark});

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Opacity(
          opacity: 0.55 + (t * 0.35),
          child: Transform.translate(offset: Offset(-10 + (t * 14), 0), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Surfaces.accent(widget.dark).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swipe, color: Brand.deep, size: 15),
            const SizedBox(width: 5),
            Text('Swipe for more',
                style: body(11, Brand.deep, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Simple checklist for money-related intentions — savings targets, debt
/// payoff steps, budget checkpoints — same interaction as weekly/monthly
/// goals, its own swipeable home card.
/// A generic goal checklist — add, check off, remove, all with a save
/// confirmation — reused by Finance & money, Health & body, Mindset &
/// growth, and Relationships & connection so those four cards share one
/// implementation instead of four near-identical copies.
class _GoalListContent extends StatefulWidget {
  final IconData icon;
  final String title;
  final String hint;
  final String emptyText;
  final List<Task> Function() goals;
  final Future<void> Function(String title) onAdd;
  final Future<void> Function(int index) onToggle;
  final Future<void> Function(int index) onRemove;

  const _GoalListContent({
    required this.icon,
    required this.title,
    required this.hint,
    required this.emptyText,
    required this.goals,
    required this.onAdd,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  State<_GoalListContent> createState() => _GoalListContentState();
}

class _GoalListContentState extends State<_GoalListContent> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_controller.text.trim().isEmpty) return;
    await widget.onAdd(_controller.text);
    _controller.clear();
    if (mounted) {
      FocusScope.of(context).unfocus();
      toastSaved(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final goals = widget.goals();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ItemHeader(icon: widget.icon, title: widget.title),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _add(),
                textCapitalization: TextCapitalization.sentences,
                style: body(13.5, Surfaces.bodyText(dark), weight: FontWeight.w500),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.hint,
                  hintStyle: body(13, Surfaces.muted(dark)),
                ),
              ),
            ),
            IconButton(
              onPressed: _add,
              icon: Icon(Icons.add_circle, color: Surfaces.accent(dark), size: 28),
            ),
          ],
        ),
        if (goals.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(widget.emptyText, style: body(13, Surfaces.muted(dark))),
          ),
        for (var i = 0; i < goals.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                CheckSquare(
                  checked: goals[i].done,
                  onTap: () async {
                    await widget.onToggle(i);
                    if (context.mounted) toastSaved(context);
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goals[i].title,
                    style: body(13.5,
                            goals[i].done ? Surfaces.muted(dark) : Surfaces.bodyText(dark),
                            weight: FontWeight.w500)
                        .copyWith(
                            decoration:
                                goals[i].done ? TextDecoration.lineThrough : TextDecoration.none),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await widget.onRemove(i);
                    if (context.mounted) toastSaved(context, label: 'Removed');
                  },
                  icon: Icon(Icons.close, size: 16, color: Surfaces.muted(dark)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FinanceGoalsContent extends StatefulWidget {
  const _FinanceGoalsContent();
  @override
  State<_FinanceGoalsContent> createState() => _FinanceGoalsContentState();
}

class _FinanceGoalsContentState extends State<_FinanceGoalsContent> {
  final _dreamCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController(text: '12');
  final _incomeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (store.financeBudgetIncome != null) {
      _incomeCtrl.text = store.financeBudgetIncome!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _dreamCtrl.dispose();
    _amountCtrl.dispose();
    _monthsCtrl.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRoadmap() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    final months = int.tryParse(_monthsCtrl.text.trim()) ?? 12;
    if (_dreamCtrl.text.trim().isEmpty || amount == null || amount <= 0 || months <= 0) return;
    await store.setFinanceRoadmap(_dreamCtrl.text, amount, months);
    _dreamCtrl.clear();
    _amountCtrl.clear();
    _monthsCtrl.text = '12';
    if (mounted) {
      FocusScope.of(context).unfocus();
      toastSaved(context);
    }
  }

  void _applyIncome() {
    final income = double.tryParse(_incomeCtrl.text.trim());
    if (income == null || income < 0) return;
    store.setFinanceBudgetIncome(income);
    setState(() {});
    FocusScope.of(context).unfocus();
    toastSaved(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final roadmap = store.financeRoadmap;
    final income = store.financeBudgetIncome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ItemHeader(icon: Icons.savings_outlined, title: 'Finance & money goals'),
        const SizedBox(height: 16),

        // ---- Goal Roadmap: Dream Goal -> 12-Month Goal -> Monthly Milestones ----
        Text('GOAL ROADMAP', style: label(Surfaces.eyebrow(dark))),
        const SizedBox(height: 10),
        if (roadmap == null) ...[
          TextField(
            controller: _dreamCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: body(13.5, Surfaces.bodyText(dark), weight: FontWeight.w500),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Your dream goal — e.g. Down payment on a home',
              hintStyle: body(12.5, Surfaces.muted(dark)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: body(13.5, Surfaces.bodyText(dark), weight: FontWeight.w500),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixText: '\$ ',
                    hintText: 'Target amount',
                    hintStyle: body(12.5, Surfaces.muted(dark)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _monthsCtrl,
                  keyboardType: TextInputType.number,
                  style: body(13.5, Surfaces.bodyText(dark), weight: FontWeight.w500),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Months',
                    hintStyle: body(12.5, Surfaces.muted(dark)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GoldButton(labelText: 'Create roadmap', onPressed: _createRoadmap),
        ] else ...[
          Text(roadmap.dreamGoal,
              style: display(15, Surfaces.heading(dark))),
          const SizedBox(height: 4),
          Text(
            '\$${roadmap.savedSoFar.toStringAsFixed(0)} of \$${roadmap.targetAmount.toStringAsFixed(0)} · \$${roadmap.perMonth.toStringAsFixed(0)}/month for ${roadmap.months} months',
            style: body(12, Surfaces.muted(dark)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < roadmap.months; i++)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    await store.toggleRoadmapMonth(i);
                    setState(() {});
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: roadmap.monthsDone[i]
                          ? Surfaces.accent(dark)
                          : Surfaces.accent(dark).withValues(alpha: 0.1),
                      border: Border.all(color: Surfaces.accent(dark), width: 1.2),
                    ),
                    child: Text('${i + 1}',
                        style: body(12,
                            roadmap.monthsDone[i] ? Brand.base : Surfaces.accent(dark),
                            weight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              await store.clearFinanceRoadmap();
              setState(() {});
            },
            child: Text('Start a new roadmap',
                style: body(12, Surfaces.muted(dark), weight: FontWeight.w600)),
          ),
        ],

        const SizedBox(height: 18),
        Divider(height: 1, color: Surfaces.cardBorder(dark)),
        const SizedBox(height: 18),

        // ---- 50/30/20 budget calculator ----
        Text('50/30/20 BUDGET CALCULATOR', style: label(Surfaces.eyebrow(dark))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _incomeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _applyIncome(),
                style: body(13.5, Surfaces.bodyText(dark), weight: FontWeight.w500),
                decoration: InputDecoration(
                  isDense: true,
                  prefixText: '\$ ',
                  hintText: 'Monthly income',
                  hintStyle: body(12.5, Surfaces.muted(dark)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GoldButton(labelText: 'Split it', onPressed: _applyIncome),
          ],
        ),
        if (income != null) ...[
          const SizedBox(height: 12),
          _BudgetRow(label: 'Needs (50%)', amount: income * 0.5, dark: dark),
          const SizedBox(height: 6),
          _BudgetRow(label: 'Wants (30%)', amount: income * 0.3, dark: dark),
          const SizedBox(height: 6),
          _BudgetRow(label: 'Savings & debt (20%)', amount: income * 0.2, dark: dark),
        ],

        const SizedBox(height: 18),
        Divider(height: 1, color: Surfaces.cardBorder(dark)),
        const SizedBox(height: 18),

        _GoalListContent(
          icon: Icons.checklist_outlined,
          title: 'Other money goals',
          hint: 'e.g. Save \$500 this month',
          emptyText: 'Nothing set yet — add a money goal above.',
          goals: () => store.financeGoals,
          onAdd: store.addFinanceGoal,
          onToggle: store.toggleFinanceGoal,
          onRemove: store.removeFinanceGoal,
        ),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool dark;
  const _BudgetRow({required this.label, required this.amount, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(label,
                style: body(13, Surfaces.bodyText(dark), weight: FontWeight.w500))),
        Text('\$${amount.toStringAsFixed(0)}',
            style: body(13, Surfaces.accent(dark), weight: FontWeight.w700)),
      ],
    );
  }
}

/// Suggested daily habits for major body systems — tap to add straight to
/// the Health & Body goal list below; still fully editable/deletable there.
const kHealthBodySuggestions = [
  'Daily walking (heart)',
  'Quality sleep (brain)',
  'Deep breathing exercises (lungs)',
  'Weight-bearing exercise (bones)',
  'Drink water regularly (blood)',
  'Daily sunscreen (skin)',
  'Quality sleep (immune system)',
  'Limit processed foods (liver)',
  'Eat probiotics (gut)',
  'Floss daily (teeth)',
  'Natural daylight exposure (eyes)',
  'Regular hand-washing (hands)',
  'Strength training twice a week (muscles)',
  'Meditation (nervous system)',
  'Consistent sleep-wake cycle (hormones)',
  'Learn something new (memory)',
];

class _HealthGoalsContent extends StatelessWidget {
  const _HealthGoalsContent();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ItemHeader(icon: Icons.favorite_border, title: 'Health & body'),
        const SizedBox(height: 14),
        Text('TAP TO ADD', style: label(Surfaces.eyebrow(dark))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in kHealthBodySuggestions)
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  final already =
                      store.healthGoals.any((t) => t.title == suggestion);
                  if (already) return;
                  await store.addHealthGoal(suggestion);
                  if (context.mounted) toastSaved(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Surfaces.accentBorder(dark)),
                  ),
                  child: Text(suggestion,
                      style: body(11.5, Surfaces.muted(dark), weight: FontWeight.w600)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Divider(height: 1, color: Surfaces.cardBorder(dark)),
        const SizedBox(height: 18),
        _GoalListContent(
          icon: Icons.checklist_outlined,
          title: 'Your health goals',
          hint: 'e.g. Drink 8 glasses of water',
          emptyText: 'Nothing set yet — tap a suggestion above or add your own.',
          goals: () => store.healthGoals,
          onAdd: store.addHealthGoal,
          onToggle: store.toggleHealthGoal,
          onRemove: store.removeHealthGoal,
        ),
      ],
    );
  }
}

class _MindsetGoalsContent extends StatefulWidget {
  const _MindsetGoalsContent();
  @override
  State<_MindsetGoalsContent> createState() => _MindsetGoalsContentState();
}

class _MindsetGoalsContentState extends State<_MindsetGoalsContent> {
  final _negativeCtrl = TextEditingController();
  final _positiveCtrl = TextEditingController();

  @override
  void dispose() {
    _negativeCtrl.dispose();
    _positiveCtrl.dispose();
    super.dispose();
  }

  Future<void> _addReframe() async {
    await store.addCustomReframe(_negativeCtrl.text, _positiveCtrl.text);
    _negativeCtrl.clear();
    _positiveCtrl.clear();
    if (mounted) {
      FocusScope.of(context).unfocus();
      setState(() {});
      toastSaved(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ItemHeader(icon: Icons.psychology_outlined, title: 'Mindset & growth'),
        const SizedBox(height: 16),

        // ---- Thought reframe ----
        Text('CHANGE YOUR WORDS, CHANGE YOUR MINDSET',
            style: label(Surfaces.eyebrow(dark))),
        const SizedBox(height: 10),
        for (final pair in kReframePairs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ReframeRow(negative: pair.$1, positive: pair.$2, dark: dark),
          ),
        for (var i = 0; i < store.customReframes.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _ReframeRow(
                    negative: store.customReframes[i].negative,
                    positive: store.customReframes[i].positive,
                    dark: dark,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await store.removeCustomReframe(i);
                    setState(() {});
                  },
                  icon: Icon(Icons.close, size: 16, color: Surfaces.muted(dark)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        TextField(
          controller: _negativeCtrl,
          textCapitalization: TextCapitalization.sentences,
          style: body(13, Surfaces.bodyText(dark), weight: FontWeight.w500),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'A thought you keep having…',
            hintStyle: body(12.5, Surfaces.muted(dark)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _positiveCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: body(13, Surfaces.bodyText(dark), weight: FontWeight.w500),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Reframe it as…',
                  hintStyle: body(12.5, Surfaces.muted(dark)),
                ),
              ),
            ),
            IconButton(
              onPressed: _addReframe,
              icon: Icon(Icons.add_circle, color: Surfaces.accent(dark), size: 28),
            ),
          ],
        ),

        const SizedBox(height: 18),
        Divider(height: 1, color: Surfaces.cardBorder(dark)),
        const SizedBox(height: 18),

        // ---- Stress bucket ----
        Text('STRESS BUCKET — TODAY', style: label(Surfaces.eyebrow(dark))),
        const SizedBox(height: 4),
        Text('What\'s filling it, and what\'s emptying it?',
            style: body(12, Surfaces.muted(dark))),
        const SizedBox(height: 10),
        Text('FILLS IT UP', style: body(11, Surfaces.muted(dark), weight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in kStressFillItems)
              _ToggleChip(
                label: item,
                selected: store.todaysStressFills.contains(item),
                dark: dark,
                onTap: () async {
                  await store.toggleStressFill(item);
                  setState(() {});
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('EMPTIES IT', style: body(11, Surfaces.muted(dark), weight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in kStressEmptyItems)
              _ToggleChip(
                label: item,
                selected: store.todaysStressEmpties.contains(item),
                dark: dark,
                onTap: () async {
                  await store.toggleStressEmpty(item);
                  setState(() {});
                },
              ),
          ],
        ),

        const SizedBox(height: 18),
        Divider(height: 1, color: Surfaces.cardBorder(dark)),
        const SizedBox(height: 18),

        // ---- Daily DOSE ----
        Text('GET YOUR DAILY DOSE', style: label(Surfaces.eyebrow(dark))),
        const SizedBox(height: 10),
        for (final category in kDoseCategories)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${category.$1} · ${category.$2}',
                    style: body(12, Surfaces.accent(dark), weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final activity in category.$3)
                      _ToggleChip(
                        label: activity,
                        selected: store.todaysDose.contains(activity),
                        dark: dark,
                        onTap: () async {
                          await store.toggleDoseActivity(activity);
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 4),
        Divider(height: 1, color: Surfaces.cardBorder(dark)),
        const SizedBox(height: 18),

        _GoalListContent(
          icon: Icons.checklist_outlined,
          title: 'Other mindset goals',
          hint: 'e.g. Reframe one limiting belief',
          emptyText: 'Nothing set yet — add a mindset goal above.',
          goals: () => store.mindsetGoals,
          onAdd: store.addMindsetGoal,
          onToggle: store.toggleMindsetGoal,
          onRemove: store.removeMindsetGoal,
        ),
      ],
    );
  }
}

class _ReframeRow extends StatelessWidget {
  final String negative;
  final String positive;
  final bool dark;
  const _ReframeRow({required this.negative, required this.positive, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Surfaces.accent(dark).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Surfaces.accentBorder(dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(negative,
              style: body(12, Surfaces.muted(dark), weight: FontWeight.w500)
                  .copyWith(decoration: TextDecoration.lineThrough)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.arrow_forward, size: 13, color: Surfaces.accent(dark)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(positive,
                    style: body(13, Surfaces.accent(dark), weight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;
  const _ToggleChip(
      {required this.label, required this.selected, required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Surfaces.accent(dark).withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Surfaces.accent(dark) : Surfaces.accentBorder(dark),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(label,
            style: body(11.5, selected ? Surfaces.accent(dark) : Surfaces.muted(dark),
                weight: FontWeight.w600)),
      ),
    );
  }
}

class _RelationshipsGoalsContent extends StatelessWidget {
  const _RelationshipsGoalsContent();
  @override
  Widget build(BuildContext context) => _GoalListContent(
        icon: Icons.diversity_1_outlined,
        title: 'Relationships & connection',
        hint: 'e.g. Call someone you miss',
        emptyText: 'Nothing set yet — add a connection goal above.',
        goals: () => store.relationshipsGoals,
        onAdd: store.addRelationshipsGoal,
        onToggle: store.toggleRelationshipsGoal,
        onRemove: store.removeRelationshipsGoal,
      );
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
      backgroundColor: Surfaces.sheet(dark),
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
      backgroundColor: Surfaces.sheet(dark),
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
