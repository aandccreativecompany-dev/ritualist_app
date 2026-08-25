import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'lock_screen.dart';

/// The day's close — three "what did I achieve" lines and a gratitude
/// prompt, locked behind the journal PIN if one is set.
class EveningReflectionScreen extends StatefulWidget {
  const EveningReflectionScreen({super.key});

  @override
  State<EveningReflectionScreen> createState() =>
      _EveningReflectionScreenState();
}

class _EveningReflectionScreenState extends State<EveningReflectionScreen> {
  late final List<TextEditingController> _achievements;
  late final TextEditingController _gratitude;

  @override
  void initState() {
    super.initState();
    final entry = store.todaysJournal;
    final a = entry.achievements;
    _achievements = List.generate(
        3, (i) => TextEditingController(text: i < a.length ? a[i] : ''));
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

  Future<void> _save() async {
    await store.saveTodaysJournal(
        _achievements.map((c) => c.text).toList(), _gratitude.text);
    if (mounted) toastSaved(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: Surfaces.pageBackground(dark),
        child: SafeArea(
          child: FadeSlideIn(
            child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
            children: [
              const ScreenHeader(
                icon: Icons.nights_stay_outlined,
                title: 'Evening reflection',
                subtitle: 'Two minutes, then close the day.',
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
              ModuleCard(
                eyebrow: 'What three things did I achieve today?',
                child: Column(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      TextField(
                        controller: _achievements[i],
                        textCapitalization: TextCapitalization.sentences,
                        style: body(14, Surfaces.bodyText(dark)),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          prefixText: '${i + 1}.  ',
                          prefixStyle: body(14, Surfaces.muted(dark),
                              weight: FontWeight.w700),
                          hintText: 'Something that counted, big or small',
                          hintStyle: body(13.5, Surfaces.muted(dark)),
                        ),
                      ),
                      if (i < 2)
                        Divider(
                            height: 14,
                            color: Surfaces.muted(dark).withValues(alpha: 0.15)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ModuleCard(
                eyebrow: 'Things I am grateful for',
                child: TextField(
                  controller: _gratitude,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: body(14, Surfaces.bodyText(dark)),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'What are you grateful for today?',
                    hintStyle: body(13.5, Surfaces.muted(dark)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GoldButton(labelText: 'Save', onPressed: _save),
              const SizedBox(height: 18),
              Center(
                child: TextButton.icon(
                  onPressed: () => _manageLock(context),
                  icon: Icon(Icons.lock_outline,
                      size: 16, color: Surfaces.muted(dark)),
                  label: Text(
                    store.hasPin ? 'Journal lock is on' : 'Lock this journal',
                    style: body(12, Surfaces.muted(dark), weight: FontWeight.w600),
                  ),
                ),
              ),
                ]),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _manageLock(BuildContext context) async {
    if (store.hasPin) {
      final remove = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove journal lock?'),
          content: const Text('Your reflection will open without a PIN.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep it')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove')),
          ],
        ),
      );
      if (remove == true) await store.clearPin();
    } else {
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LockScreen(mode: LockMode.setup)));
      setState(() {});
    }
  }
}
