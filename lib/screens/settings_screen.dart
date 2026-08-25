import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'lock_screen.dart';
import 'module_picker_screen.dart';
import 'weekly_review_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _export(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: store.exportJson()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Backup copied. Paste it somewhere safe.')));
  }

  Future<void> _import(BuildContext context) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restore a backup',
            style: display(18, Surfaces.heading(dark))),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
              hintText: 'Paste your backup text here'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Restore')),
        ],
      ),
    );
    if (raw == null || raw.trim().isEmpty) return;
    final ok = await store.importJson(raw);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Backup restored.'
            : "That doesn't look like a Prakriyā backup.")));
  }

  Future<void> _retakeQuiz(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retake the setup quiz?'),
        content: const Text(
            'Your tasks, habits and history stay put — only your preset and card picks reset.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Retake')),
        ],
      ),
    );
    if (confirmed != true) return;
    await store.retakeOnboarding();
    if (!context.mounted) return;
    // The root widget swaps to OnboardingScreen on its own once
    // onboardingComplete flips — just pop back to it.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    final user = await AuthService.instance.signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (user != null) {
      toastSaved(context, label: 'Signed in — syncing your data');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't sign in — try again.")));
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    await AuthService.instance.signOut();
    if (!mounted) return;
    setState(() => _busy = false);
    toastSaved(context, label: 'Signed out');
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                  children: [
                    const ScreenHeader(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('APPEARANCE', style: label(Surfaces.muted(dark))),
                          const SizedBox(height: 12),
                          ModuleCard(
                            child: Column(
                              children: [
                                for (final option in const [
                                  ['system', 'Follow the phone'],
                                  ['light', 'Always light'],
                                  ['dark', 'Always dark'],
                                ])
                                  InkWell(
                                    onTap: () async {
                                      await store.setThemeMode(option[0]);
                                      if (context.mounted) toastSaved(context);
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(option[1],
                                                style: body(
                                                    13.5, Surfaces.bodyText(dark),
                                                    weight: FontWeight.w500)),
                                          ),
                                          if (store.state.themeMode == option[0])
                                            Icon(Icons.check,
                                                size: 18,
                                                color: Surfaces.accent(dark)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text('YOUR RITUAL', style: label(Surfaces.muted(dark))),
                          const SizedBox(height: 12),
                          ModuleCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                _NavRow(
                                  icon: Icons.view_agenda_outlined,
                                  title: 'Customize your cards',
                                  subtitle: 'Reorder or hide what shows on Today',
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => const ModulePickerScreen())),
                                ),
                                _divider(dark),
                                _NavRow(
                                  icon: Icons.insights_outlined,
                                  title: 'Weekly momentum review',
                                  subtitle: 'The last 7 days, at a glance',
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => const WeeklyReviewScreen())),
                                ),
                                _divider(dark),
                                _NavRow(
                                  icon: Icons.replay_outlined,
                                  title: 'Retake the setup quiz',
                                  subtitle: 'Reset your preset and card picks',
                                  onTap: () => _retakeQuiz(context),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text('JOURNAL LOCK', style: label(Surfaces.muted(dark))),
                          const SizedBox(height: 12),
                          ModuleCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Local only — a privacy nudge for your evening reflection, not encryption.',
                                  style: body(12.5, Surfaces.muted(dark)),
                                ),
                                const SizedBox(height: 16),
                                if (store.hasPin) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text('Unlock with biometrics',
                                            style: body(13.5, Surfaces.bodyText(dark),
                                                weight: FontWeight.w500)),
                                      ),
                                      Switch(
                                        value: store.biometricEnabled,
                                        activeTrackColor: Surfaces.accent(dark),
                                        onChanged: (v) async {
                                          await store.setBiometricEnabled(v);
                                          if (context.mounted) toastSaved(context);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton(
                                    onPressed: () async {
                                      await store.clearPin();
                                      if (context.mounted) {
                                        toastSaved(context, label: 'PIN removed');
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        alignment: Alignment.centerLeft),
                                    child: Text('Remove PIN lock',
                                        style: body(13, Colors.redAccent,
                                            weight: FontWeight.w600)),
                                  ),
                                ] else
                                  GoldButton(
                                    labelText: 'Set a PIN',
                                    onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const LockScreen(mode: LockMode.setup))),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text('ACCOUNT', style: label(Surfaces.muted(dark))),
                          const SizedBox(height: 12),
                          ModuleCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (AuthService.instance.isSignedIn) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.account_circle,
                                          size: 36, color: Brand.gold),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AuthService.instance.currentUser
                                                      ?.displayName ??
                                                  'Signed in',
                                              style: body(14,
                                                  Surfaces.heading(dark),
                                                  weight: FontWeight.w700),
                                            ),
                                            Text(
                                              AuthService.instance.currentUser
                                                      ?.email ??
                                                  '',
                                              style: body(
                                                  11.5, Surfaces.muted(dark)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Your data syncs to this account and follows you to any device you sign into.',
                                    style: body(12, Surfaces.muted(dark)),
                                  ),
                                  const SizedBox(height: 14),
                                  TextButton(
                                    onPressed: _busy ? null : _signOut,
                                    style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        alignment: Alignment.centerLeft),
                                    child: Text('Sign out',
                                        style: body(13, Colors.redAccent,
                                            weight: FontWeight.w600)),
                                  ),
                                ] else ...[
                                  Text(
                                    'Sign in with Google to back your data up and sync it across your devices. Optional — everything works fully offline without it.',
                                    style: body(12.5, Surfaces.muted(dark)),
                                  ),
                                  const SizedBox(height: 16),
                                  GoldButton(
                                    labelText: _busy
                                        ? 'Signing in…'
                                        : 'Sign in with Google',
                                    onPressed: _busy ? () {} : _signIn,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text('YOUR DATA', style: label(Surfaces.muted(dark))),
                          const SizedBox(height: 12),
                          ModuleCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    AuthService.instance.isSignedIn
                                        ? 'Synced to your account, plus stored on this phone. You can still keep a manual backup below.'
                                        : 'Everything stays on this phone. There is no account and nothing is uploaded, so a lost or wiped phone loses your entries unless you keep a backup.',
                                    style: body(12.5, Surfaces.muted(dark))),
                                const SizedBox(height: 16),
                                GoldButton(
                                    labelText: 'Copy a backup',
                                    onPressed: () => _export(context)),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () => _import(context),
                                  child: Text('Restore from a backup',
                                      style: body(13, Surfaces.accent(dark),
                                          weight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text('ABOUT', style: label(Surfaces.muted(dark))),
                          const SizedBox(height: 12),
                          ModuleCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Prakriyā 0.2.4',
                                    style: body(13.5, Surfaces.bodyText(dark),
                                        weight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text('A & C Creative Company',
                                    style: body(12.5, Surfaces.muted(dark))),
                              ],
                            ),
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

Widget _divider(bool dark) => Divider(
      height: 1,
      color: Surfaces.cardBorder(dark),
      indent: 52,
    );

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: Surfaces.accent(dark), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: body(13.5, Surfaces.bodyText(dark),
                          weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: body(11.5, Surfaces.muted(dark))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Surfaces.muted(dark), size: 18),
          ],
        ),
      ),
    );
  }
}
