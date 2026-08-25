import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Outcome engineering — writing the outcome you want as if it's already true.
/// The vocabulary decision (README): "manifestation" is "outcome engineering",
/// and the writing exercise itself is "scripting".
class ScriptingScreen extends StatelessWidget {
  const ScriptingScreen({super.key});

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
                    ScreenHeader(
                      icon: Icons.auto_awesome,
                      title: 'Scripting',
                      subtitle: 'Write the outcome as if it already happened.',
                      actions: [
                        IconButton(
                          onPressed: () => _editScript(context, null),
                          icon: Icon(Icons.add_circle_outline, color: Surfaces.accent(dark)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: store.scripts.isEmpty
                          ? _Empty(onCreate: () => _editScript(context, null))
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                              children: [
                                for (var i = 0; i < store.scripts.length; i++)
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: Duration(milliseconds: 260 + i * 50),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, t, child) => Transform.translate(
                                      offset: Offset(0, (1 - t.clamp(0, 1)) * 12),
                                      child: Opacity(opacity: t.clamp(0, 1), child: child),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => _editScript(context, store.scripts[i]),
                                        child: ModuleCard(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: Surfaces.accent(dark)
                                                      .withValues(alpha: 0.16),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.auto_awesome,
                                                    color: Surfaces.accent(dark), size: 17),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      store.scripts[i].title.isEmpty
                                                          ? 'Untitled'
                                                          : store.scripts[i].title,
                                                      style: display(
                                                          16, Surfaces.heading(dark)),
                                                    ),
                                                    if (store.scripts[i].body.isNotEmpty) ...[
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        store.scripts[i].body,
                                                        maxLines: 3,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: body(
                                                            13, Surfaces.bodyText(dark)),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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

  Future<void> _editScript(BuildContext context, Script? script) async {
    final titleCtrl = TextEditingController(text: script?.title ?? '');
    final bodyCtrl = TextEditingController(text: script?.body ?? '');
    final dark = Theme.of(context).brightness == Brightness.dark;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: BoxDecoration(
            color: Surfaces.card(dark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(script == null ? 'New script' : 'Edit script',
                  style: display(18, Surfaces.heading(dark))),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: body(15, Surfaces.bodyText(dark), weight: FontWeight.w600),
                decoration: const InputDecoration(hintText: 'What outcome?'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: body(14, Surfaces.bodyText(dark)),
                decoration: const InputDecoration(
                    hintText: 'Write it as if it already happened…'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (script != null)
                    TextButton(
                      onPressed: () async {
                        await store.removeScript(script);
                        if (context.mounted) {
                          Navigator.pop(context);
                          toastSaved(context, label: 'Removed');
                        }
                      },
                      child: Text('Delete',
                          style: body(13, Colors.redAccent, weight: FontWeight.w600)),
                    ),
                  const Spacer(),
                  GoldButton(
                    labelText: 'Save',
                    onPressed: () => Navigator.pop(context, 'save'),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );

    if (result == 'save') {
      if (script == null) {
        await store.addScript(titleCtrl.text, bodyCtrl.text);
      } else {
        await store.updateScript(script, titleCtrl.text, bodyCtrl.text);
      }
      if (context.mounted) toastSaved(context);
    }
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onCreate;
  const _Empty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Surfaces.accent(dark), size: 30),
            const SizedBox(height: 16),
            Text('Nothing scripted yet',
                style: display(18, Surfaces.heading(dark)),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Write the outcome you want, as if it already happened.',
              style: body(13, Surfaces.muted(dark)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GoldButton(labelText: 'Write your first script', onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}
