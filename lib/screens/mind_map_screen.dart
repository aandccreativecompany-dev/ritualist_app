import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _periods = [
  ('day', "Today's pulse"),
  ('week', "This week's pulse"),
  ('month', "This month's pulse"),
];

/// A branching, auto-generated overview of how the day/week/month is going —
/// habits, priorities, mood, and journaling pulled straight from the store,
/// arranged as a central node with branch nodes around it — plus a free-text
/// notes field per period so it's not purely automatic.
class MindMapScreen extends StatefulWidget {
  const MindMapScreen({super.key});

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _noteControllers = {
    'day': TextEditingController(),
    'week': TextEditingController(),
    'month': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
    for (final entry in _noteControllers.entries) {
      entry.value.text = store.mindMapNoteFor(entry.key);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveNote(String period) async {
    await store.setMindMapNote(period, _noteControllers[period]!.text);
    if (mounted) toastSaved(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: Surfaces.pageBackground(dark),
            child: SafeArea(
              child: FadeSlideIn(
                child: Column(
                  children: [
                    const ScreenHeader(
                      icon: Icons.account_tree_outlined,
                      title: 'Organized mind map',
                      subtitle: 'Everything at a glance, plus your own notes.',
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Surfaces.card(dark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Surfaces.cardBorder(dark)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Surfaces.accent(dark),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          labelColor: Brand.deep,
                          unselectedLabelColor: Surfaces.muted(dark),
                          labelStyle: body(12.5, Brand.deep, weight: FontWeight.w700),
                          unselectedLabelStyle: body(12.5, Surfaces.muted(dark)),
                          tabs: const [
                            Tab(text: 'Day'),
                            Tab(text: 'Week'),
                            Tab(text: 'Month'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          for (final (period, label) in _periods)
                            _MindMapTab(
                              period: period,
                              centerLabel: label,
                              noteController: _noteControllers[period]!,
                              onSaveNote: () => _saveNote(period),
                            ),
                        ],
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

class _MindMapTab extends StatelessWidget {
  final String period;
  final String centerLabel;
  final TextEditingController noteController;
  final VoidCallback onSaveNote;

  const _MindMapTab({
    required this.period,
    required this.centerLabel,
    required this.noteController,
    required this.onSaveNote,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final snap = store.mindMapSnapshot(period);
    final habitsPct = snap.habitsTotal == 0
        ? 0
        : ((snap.habitsDone / snap.habitsTotal) * 100).round();
    final prioritiesPct = snap.prioritiesTotal == 0
        ? 0
        : ((snap.prioritiesDone / snap.prioritiesTotal) * 100).round();
    final overall = snap.habitsTotal == 0 && snap.prioritiesTotal == 0
        ? 0
        : ((habitsPct + prioritiesPct) / (snap.prioritiesTotal == 0 ? 1 : 2)).round();

    final branches = [
      _BranchData(
        icon: Icons.self_improvement,
        label: 'Habits',
        value: snap.habitsTotal == 0 ? 'None tracked' : '$habitsPct% done',
        color: Brand.gold,
      ),
      _BranchData(
        icon: Icons.checklist_rounded,
        label: 'Priorities',
        value: snap.prioritiesTotal == 0 ? 'Nothing set' : '$prioritiesPct% done',
        color: Brand.violet,
      ),
      _BranchData(
        icon: Icons.mood_outlined,
        label: 'Mood',
        value: snap.mood ?? 'Not logged',
        color: Brand.goldLight,
      ),
      _BranchData(
        icon: Icons.nights_stay_outlined,
        label: 'Reflection',
        value: snap.journaled ? 'Written' : 'Not yet',
        color: Brand.mutedDark,
      ),
      _BranchData(
        icon: Icons.auto_awesome,
        label: 'Scripting',
        value: '${snap.scriptsCount} total',
        color: Brand.gold,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          SizedBox(
            height: 320,
            width: double.infinity,
            child: _MindMapRadial(
              centerLabel: centerLabel,
              centerValue: '$overall%',
              branches: branches,
              dark: dark,
            ),
          ),
          const SizedBox(height: 20),
          ModuleCard(
            eyebrow: 'Notes for this period',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: body(13.5, Surfaces.bodyText(dark)),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'What stands out about this ${period == 'day' ? 'day' : period}?',
                    hintStyle: body(13, Surfaces.muted(dark)),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onSaveNote,
                    child: Text('Save note',
                        style: body(12.5, Surfaces.accent(dark), weight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _BranchData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Central node plus branch nodes connected by lines — the "organized mind
/// map" visual, auto-laid-out in a circle around the centre regardless of
/// how many branches there are.
class _MindMapRadial extends StatelessWidget {
  final String centerLabel;
  final String centerValue;
  final List<_BranchData> branches;
  final bool dark;

  const _MindMapRadial({
    required this.centerLabel,
    required this.centerValue,
    required this.branches,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final center = Offset(size.width / 2, size.height / 2);
        final radius = math.min(size.width, size.height) / 2 - 46;
        final positions = <Offset>[];
        for (var i = 0; i < branches.length; i++) {
          final angle = (-90 + (360 / branches.length) * i) * math.pi / 180;
          positions.add(Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          ));
        }
        return Stack(
          children: [
            CustomPaint(
              size: size,
              painter: _BranchLinePainter(
                center: center,
                points: positions,
                color: Surfaces.muted(dark).withValues(alpha: 0.35),
              ),
            ),
            Positioned(
              left: center.dx - 56,
              top: center.dy - 56,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Brand.gold, Brand.goldLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Brand.gold.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(centerValue, style: display(22, Brand.deep)),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          centerLabel,
                          textAlign: TextAlign.center,
                          style: body(9.5, Brand.deep, weight: FontWeight.w700),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            for (var i = 0; i < branches.length; i++)
              Positioned(
                left: positions[i].dx - 52,
                top: positions[i].dy - 32,
                child: _BranchNode(data: branches[i], dark: dark),
              ),
          ],
        );
      },
    );
  }
}

class _BranchNode extends StatelessWidget {
  final _BranchData data;
  final bool dark;
  const _BranchNode({required this.data, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Surfaces.card(dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.25 : 0.06), blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 16, color: data.color),
          const SizedBox(height: 4),
          Text(data.label,
              style: body(10.5, Surfaces.heading(dark), weight: FontWeight.w700),
              textAlign: TextAlign.center),
          Text(data.value,
              style: body(9.5, Surfaces.muted(dark)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _BranchLinePainter extends CustomPainter {
  final Offset center;
  final List<Offset> points;
  final Color color;
  const _BranchLinePainter({required this.center, required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    for (final p in points) {
      canvas.drawLine(center, p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BranchLinePainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.points != points || oldDelegate.color != color;
}
