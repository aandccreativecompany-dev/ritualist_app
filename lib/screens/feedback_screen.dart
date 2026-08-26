import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _feedbackEmail = 'aandccreativecompany@gmail.com';

/// Lets a user send feedback or a fix request straight to the company inbox.
/// The app has no backend of its own, so "send" opens the device's mail app
/// with the message pre-filled, addressed to us — the user still taps send
/// there themselves, same as any mailto link. That's stated plainly in the
/// screen so it's never a surprise.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _controller = TextEditingController();
  String _kind = 'Feedback';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(BuildContext context) async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    final subject = Uri.encodeComponent('Prakriyā $_kind');
    final body = Uri.encodeComponent(
        '$message\n\n—\nSent from Prakriyā${store.userName.isEmpty ? '' : ' by ${store.userName}'}');
    final uri = Uri.parse('mailto:$_feedbackEmail?subject=$subject&body=$body');
    final opened = await launchUrl(uri);
    if (!context.mounted) return;
    if (opened) {
      toastSaved(context, label: 'Opened your mail app — tap send there');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No mail app found — email us directly at $_feedbackEmail')));
    }
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
                  icon: Icons.forum_outlined,
                  title: 'Feedback',
                  subtitle: 'Tell us what to fix or what you\'d love to see next.',
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ModuleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('THIS IS ABOUT', style: label(Surfaces.eyebrow(dark))),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final kind in const ['Feedback', 'A bug', 'A feature request'])
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => setState(() => _kind = kind),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _kind == kind
                                        ? Surfaces.accent(dark).withValues(alpha: 0.16)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _kind == kind
                                          ? Surfaces.accent(dark)
                                          : Surfaces.accentBorder(dark),
                                      width: _kind == kind ? 1.4 : 1,
                                    ),
                                  ),
                                  child: Text(kind,
                                      style: body(11.5,
                                          _kind == kind
                                              ? Surfaces.accent(dark)
                                              : Surfaces.muted(dark),
                                          weight: FontWeight.w600)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _controller,
                          maxLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          style: body(14, Surfaces.bodyText(dark)),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'What happened, or what would help?',
                            hintStyle: body(13, Surfaces.muted(dark)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This opens your mail app with a message addressed to us ($_feedbackEmail) — you send it from there.',
                          style: body(11.5, Surfaces.muted(dark)),
                        ),
                        const SizedBox(height: 16),
                        GoldButton(
                          labelText: 'Open in mail app',
                          onPressed: () => _send(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
