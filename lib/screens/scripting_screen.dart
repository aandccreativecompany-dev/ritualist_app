import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Journaling (Brain Dump) — two writing modes in one place: a manifestation
/// script (write the outcome as if it's already true) or a free-form brain
/// dump (just let it out, no structure required). The vocabulary decision
/// (README): "manifestation" is "outcome engineering", and this screen's
/// user-facing name is "Journaling (Brain Dump)".
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
                      title: 'Journaling (Brain Dump)',
                      subtitle: 'Script an outcome, or just brain-dump what\'s on your mind.',
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
                                                child: Icon(
                                                    store.scripts[i].mode == 'dump'
                                                        ? Icons.psychology_alt_outlined
                                                        : Icons.auto_awesome,
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
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${store.scripts[i].mode == 'dump' ? 'Brain dump' : 'Script'} · ${_formatWhen(store.scripts[i].createdAt)}',
                                                      style: body(11,
                                                          Surfaces.accent(dark),
                                                          weight: FontWeight.w600),
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
    var mode = script?.mode ?? 'manifest';

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          final keyboard = MediaQuery.of(context).viewInsets.bottom;
          final isDump = mode == 'dump';
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, keyboard + 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height - keyboard - 80),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  // Opaque — see HabitEditorSheet's note on Surfaces.sheet.
                  color: Surfaces.sheet(dark),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(script == null ? 'New entry' : 'Edit entry',
                        style: display(18, Surfaces.heading(dark))),
                    const SizedBox(height: 10),
                    // Everything scrollable — including the mode chips — so
                    // that on a short/keyboard-heavy screen it's this area
                    // that shrinks and scrolls, never the Save button below
                    // it. A previous cut of this sheet put the chips outside
                    // the scroll area as fixed-height content; combined with
                    // a tall keyboard that could push the Save row's laid-out
                    // position below the visible viewport, hidden behind the
                    // keyboard even though it "existed" in the layout. Save
                    // now has nothing but this one Flexible above it.
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final entry in const [
                                  MapEntry('manifest', 'Manifestation script'),
                                  MapEntry('dump', 'Free brain dump'),
                                ])
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => setSheetState(() => mode = entry.key),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: mode == entry.key
                                            ? Surfaces.accent(dark).withValues(alpha: 0.16)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: mode == entry.key
                                              ? Surfaces.accent(dark)
                                              : Surfaces.accentBorder(dark),
                                          width: mode == entry.key ? 1.4 : 1,
                                        ),
                                      ),
                                      child: Text(entry.value,
                                          style: body(11.5,
                                              mode == entry.key
                                                  ? Surfaces.accent(dark)
                                                  : Surfaces.muted(dark),
                                              weight: FontWeight.w600)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: titleCtrl,
                              autofocus: true,
                              textCapitalization: TextCapitalization.sentences,
                              style: body(15, Surfaces.bodyText(dark),
                                  weight: FontWeight.w600),
                              decoration: InputDecoration(
                                  hintText:
                                      isDump ? 'Give it a quick title (optional)' : 'What outcome?'),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: bodyCtrl,
                              maxLines: 5,
                              minLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              style: body(14, Surfaces.bodyText(dark)),
                              decoration: InputDecoration(
                                  hintText: isDump
                                      ? 'Just let it out — no structure needed…'
                                      : 'Write it as if it already happened…'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Pinned outside the scroll area, on purpose — this is the
                    // save button users reported not being able to find; it now
                    // always stays visible above the keyboard instead of
                    // requiring a scroll past a 5-line text field to find it.
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
                                style: body(13, Colors.redAccent,
                                    weight: FontWeight.w600)),
                          ),
                        const Spacer(),
                        SizedBox(
                          width: script != null ? 140 : double.infinity,
                          child: GoldButton(
                            labelText: 'Save',
                            onPressed: () => Navigator.pop(context, 'save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );

    if (result == 'save') {
      if (script == null) {
        await store.addScript(titleCtrl.text, bodyCtrl.text, mode: mode);
      } else {
        await store.updateScript(script, titleCtrl.text, bodyCtrl.text, mode: mode);
      }
      if (context.mounted) toastSaved(context, label: 'Saved — see it above');
    }
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatWhen(DateTime dt) {
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '${_months[dt.month - 1]} ${dt.day} · $hour12:$minute $ampm';
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
            Text('Nothing here yet',
                style: display(18, Surfaces.heading(dark)),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Script an outcome as if it already happened, or just brain-dump what\'s on your mind.',
              style: body(13, Surfaces.muted(dark)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GoldButton(labelText: 'Write your first entry', onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}
