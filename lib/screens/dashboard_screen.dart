import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'about_screen.dart';
import 'quote_screen.dart';
import 'settings_screen.dart';

/// The true landing page — greeting, today's mantra, and an at-a-glance
/// summary, all in one place instead of being repeated at the top of every
/// section. Each other section is reached from here (or the bottom nav)
/// as its own separate, focused screen.
class DashboardScreen extends StatelessWidget {
  final List<HomePageSection> sections;
  final void Function(String sectionKey) onOpenSection;
  const DashboardScreen({super.key, required this.sections, required this.onOpenSection});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Still up';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Winding down';
  }

  IconData _sectionIcon(String key) {
    switch (key) {
      case 'productivity':
        return Icons.checklist_rounded;
      case 'outcome':
        return Icons.auto_awesome;
      case 'finance':
        return Icons.account_balance_wallet_outlined;
      case 'health':
        return Icons.favorite_border;
      case 'mindset':
        return Icons.psychology_alt_outlined;
      case 'relationships':
        return Icons.diversity_1_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateLine =
        '${dayNames[today.weekday - 1]} ${today.day} ${monthNames[today.month - 1]}';
    final done = store.todaysTasks.where((t) => t.done).length;
    final total = store.todaysTasks.length;
    final momentum = store.weeklyMomentum();
    final greeting = _greeting();
    final name = store.userName;
    final mascotGreeting = kMascotGreetings[
        DateTime.now().millisecondsSinceEpoch % kMascotGreetings.length];

    return Scaffold(
      body: Container(
        decoration: Surfaces.pageBackground(dark),
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                children: [
                  Row(
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
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        icon: Icon(Icons.settings_outlined, color: Surfaces.muted(dark), size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 90),
                  InkWell(
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
                          Text(store.mantraEntryOfTheDay.source,
                              style: body(11, Surfaces.accentText(dark).withValues(alpha: 0.7),
                                  weight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Today',
                          value: total == 0 ? '—' : '$done/$total',
                          sub: 'priorities',
                          icon: Icons.check_circle_outline,
                          dark: dark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Habits',
                          value: '${store.habitsDoneToday}/${store.habits.length}',
                          sub: 'done today',
                          icon: Icons.local_fire_department_outlined,
                          dark: dark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          label: 'Streak',
                          value: '${momentum.bestStreak}',
                          sub: momentum.bestStreak == 1 ? 'day' : 'days',
                          icon: Icons.emoji_events_outlined,
                          dark: dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('YOUR SECTIONS', style: label(Surfaces.muted(dark))),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.1,
                    children: [
                      for (final section in sections)
                        _SectionTile(
                          title: section.title,
                          icon: _sectionIcon(section.key),
                          dark: dark,
                          onTap: () => onOpenSection(section.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                    child: ModuleCard(
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Surfaces.muted(dark)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('About us — website & socials',
                                style: body(13, Surfaces.bodyText(dark), weight: FontWeight.w600)),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: Surfaces.muted(dark)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: const Alignment(0, -0.62),
                    child: SizedBox(
                      width: double.infinity,
                      height: 118,
                      child: GreetingMascot(
                        avatarGender: store.avatarGender,
                        greeting: mascotGreeting,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final bool dark;
  const _StatTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Surfaces.accent(dark)),
          const SizedBox(height: 8),
          Text(value, style: display(18, Surfaces.heading(dark))),
          const SizedBox(height: 2),
          Text('$label · $sub',
              style: body(10, Surfaces.muted(dark), weight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool dark;
  final VoidCallback onTap;
  const _SectionTile({
    required this.title,
    required this.icon,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Surfaces.card(dark),
          border: Border.all(color: Surfaces.cardBorder(dark)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Surfaces.accent(dark)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: body(12.5, Surfaces.heading(dark), weight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
