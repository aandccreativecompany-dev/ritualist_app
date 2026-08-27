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
    // A FULL SCREEN, not a bottom sheet — deliberately. Earlier builds kept
    // this a modal sheet and tried to keep the Save button above a
    // variable-height on-screen keyboard via ConstrainedBox/Flexible height
    // math; that math kept losing the fight on some devices/keyboards, and
    // the Save button ended up laid out behind the keyboard, invisible. A
    // full screen with Save/Delete pinned in the AppBar sidesteps the whole
    // problem: the AppBar never resizes for the keyboard, so those actions
    // are always on screen, full stop — no height math to get wrong.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ScriptEditorScreen(script: script)),
    );
  }
}

class _ScriptEditorScreen extends StatefulWidget {
  final Script? script;
  const _ScriptEditorScreen({this.script});

  @override
  State<_ScriptEditorScreen> createState() => _ScriptEditorScreenState();
}

class _ScriptEditorScreenState extends State<_ScriptEditorScreen> {
  late final _titleCtrl = TextEditingController(text: widget.script?.title ?? '');
  late final _bodyCtrl = TextEditingController(text: widget.script?.body ?? '');
  late String _mode = widget.script?.mode ?? 'manifest';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final script = widget.script;
    if (script == null) {
      await store.addScript(_titleCtrl.text, _bodyCtrl.text, mode: _mode);
    } else {
      await store.updateScript(script, _titleCtrl.text, _bodyCtrl.text, mode: _mode);
    }
    if (mounted) {
      Navigator.pop(context);
      toastSaved(context, label: 'Saved — see it above');
    }
  }

  Future<void> _delete() async {
    final script = widget.script;
    if (script == null) return;
    await store.removeScript(script);
    if (mounted) {
      Navigator.pop(context);
      toastSaved(context, label: 'Removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isDump = _mode == 'dump';
    return Scaffold(
      backgroundColor: dark ? Brand.deep : Brand.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Surfaces.heading(dark)),
        title: Text(widget.script == null ? 'New entry' : 'Edit entry',
            style: display(17, Surfaces.heading(dark))),
        // Save/Delete live here, in the AppBar — this row never moves and is
        // never covered by the keyboard, on any device.
        actions: [
          if (widget.script != null)
            IconButton(
              tooltip: 'Delete',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          IconButton(
            tooltip: 'Save',
            onPressed: _save,
            icon: Icon(Icons.check_circle, color: Surfaces.accent(dark), size: 28),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: Surfaces.pageBackground(dark),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
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
                        onTap: () => setState(() => _mode = entry.key),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _mode == entry.key
                                ? Surfaces.accent(dark).withValues(alpha: 0.16)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _mode == entry.key
                                  ? Surfaces.accent(dark)
                                  : Surfaces.accentBorder(dark),
                              width: _mode == entry.key ? 1.4 : 1,
                            ),
                          ),
                          child: Text(entry.value,
                              style: body(11.5,
                                  _mode == entry.key
                                      ? Surfaces.accent(dark)
                                      : Surfaces.muted(dark),
                                  weight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: body(15, Surfaces.bodyText(dark), weight: FontWeight.w600),
                  decoration: InputDecoration(
                      hintText:
                          isDump ? 'Give it a quick title (optional)' : 'What outcome?'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: null,
                  minLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  style: body(14, Surfaces.bodyText(dark)),
                  decoration: InputDecoration(
                      hintText: isDump
                          ? 'Just let it out — no structure needed…'
                          : 'Write it as if it already happened…'),
                ),
                const SizedBox(height: 24),
                // A second, always-reachable Save action at the bottom of the
                // scroll content too — belt-and-suspenders alongside the
                // AppBar one, per the explicit ask for a visible save/edit/
                // delete button with an icon.
                GoldButton(
                  labelText: widget.script == null ? 'Save entry' : 'Save changes',
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
