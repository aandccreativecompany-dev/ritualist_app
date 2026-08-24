import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'module_picker_screen.dart';

/// First-run flow: welcome, a short quiz that sets a preset, then the module
/// picker. Runs once — retakeable later from Settings (README: "Onboarding:
/// a one-time quiz sets a preset... Retakeable from Settings").
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

const _focusOptions = [
  ('doing', 'Getting things done', 'Top 3, habits, focus'),
  ('outcome', 'Engineering an outcome', 'Scripting, vision board'),
  ('consistent', 'Staying consistent', 'Streaks, gentle reminders'),
  ('steady', 'Feeling steadier', 'Mood, gratitude, reflection'),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;
  final Set<String> _focus = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFocus(String id) {
    setState(() {
      if (_focus.contains(id)) {
        _focus.remove(id);
      } else if (_focus.length < 2) {
        _focus.add(id);
      }
    });
  }

  String _presetFromFocus() {
    if (_focus.contains('outcome')) return kPresetManifest;
    if (_focus.contains('doing') && !_focus.contains('steady')) return kPresetFocus;
    return kPresetBalance;
  }

  void _next() {
    if (_step == 2) {
      store.completeOnboarding(
        focusAreas: _focus.toList(),
        preset: _presetFromFocus(),
      );
      widget.onDone();
      return;
    }
    setState(() => _step++);
    _pageController.animateToPage(_step,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageController.animateToPage(_step,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: Surfaces.pageBackground(dark),
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _WelcomeStep(onStart: _next),
              _QuizStep(
                selected: _focus,
                onToggle: _toggleFocus,
                onBack: _back,
                onNext: _next,
              ),
              _ModuleStep(onBack: _back, onDone: _next),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onStart;
  const _WelcomeStep({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wb_twilight, color: Surfaces.accent(dark), size: 64),
                  const SizedBox(height: 24),
                  Text('PRAKRIYĀ',
                      style: display(30, Surfaces.heading(dark))
                          .copyWith(letterSpacing: .5)),
                  const SizedBox(height: 10),
                  Text('GROWTH MINDSET, MADE PRACTICAL',
                      style: label(Surfaces.accent(dark))),
                  const SizedBox(height: 22),
                  Text(
                    'A daily planner that holds both sides: real tasks and real mindset work. Set it up once — it opens on today, every day after.',
                    textAlign: TextAlign.center,
                    style: body(14, Surfaces.bodyText(dark), height: 1.7),
                  ),
                ],
              ),
            ),
          ),
          GoldButton(labelText: "Let's set it up", onPressed: onStart),
          const SizedBox(height: 10),
          Text('No account needed — everything stays on this phone.',
              style: body(11.5, Surfaces.muted(dark)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _QuizStep extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onBack;
  final VoidCallback onNext;
  const _QuizStep({
    required this.selected,
    required this.onToggle,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back, color: Surfaces.bodyText(dark))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 0.5,
                    minHeight: 3,
                    backgroundColor: Surfaces.muted(dark).withValues(alpha: 0.16),
                    valueColor: AlwaysStoppedAnimation(Surfaces.accent(dark)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('2/3', style: body(11, Surfaces.muted(dark), weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 22),
          Text('WHAT MATTERS MOST RIGHT NOW', style: label(Surfaces.eyebrow(dark))),
          const SizedBox(height: 12),
          Text('What are you here to work on?',
              style: display(23, Surfaces.heading(dark))),
          const SizedBox(height: 8),
          Text('Pick up to two. You can change this any time in Settings.',
              style: body(12.5, Surfaces.muted(dark))),
          const SizedBox(height: 22),
          Expanded(
            child: ListView(
              children: [
                for (final option in _focusOptions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FocusCard(
                      title: option.$2,
                      subtitle: option.$3,
                      selected: selected.contains(option.$1),
                      onTap: () => onToggle(option.$1),
                    ),
                  ),
              ],
            ),
          ),
          GoldButton(labelText: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _FocusCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Surfaces.accent(dark)
                : Surfaces.accent(dark).withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
          color: selected
              ? Surfaces.accent(dark).withValues(alpha: 0.09)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: body(15, Surfaces.heading(dark), weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: body(12, Surfaces.muted(dark))),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: Surfaces.accent(dark), shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 13, color: Brand.deep),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModuleStep extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onDone;
  const _ModuleStep({required this.onBack, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back, color: Surfaces.bodyText(dark))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 1,
                    minHeight: 3,
                    backgroundColor: Surfaces.muted(dark).withValues(alpha: 0.16),
                    valueColor: AlwaysStoppedAnimation(Surfaces.accent(dark)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('3/3', style: body(11, Surfaces.muted(dark), weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 22),
          Text('Your daily cards', style: display(23, Surfaces.heading(dark))),
          const SizedBox(height: 8),
          Text('Based on your answers. Drag to reorder, switch off what you don\'t want.',
              style: body(12.5, Surfaces.muted(dark))),
          const SizedBox(height: 20),
          const Expanded(child: SingleChildScrollView(child: ModulePickerBody())),
          GoldButton(labelText: 'Start using Prakriyā', onPressed: onDone),
        ],
      ),
    );
  }
}
