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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back,
                              color: Surfaces.bodyText(dark)),
                        ),
                        Expanded(
                          child: Text('Scripting',
                              style: body(14, Surfaces.heading(dark),
                                  weight: FontWeight.w600)),
                        ),
                        IconButton(
                          onPressed: () => _editScript(context, null),
                          icon: Icon(Icons.add, color: Surfaces.accent(dark)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: store.scripts.isEmpty
                        ? _Empty(onCreate: () => _editScript(context, null))
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                            children: [
                              Text(
                                'Write the outcome you want as if it already happened. Be specific — how it feels, what changed.',
                                style: body(12.5, Surfaces.muted(dark)),
                              ),
                              const SizedBox(height: 18),
                              for (final script in store.scripts)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _editScript(context, script),
                                    child: ModuleCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            script.title.isEmpty
                                                ? 'Untitled'
                                                : script.title,
                                            style: display(
                                                16, Surfaces.heading(dark)),
                                          ),
                                          if (script.body.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              script.body,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: body(
                                                  13, Surfaces.bodyText(dark)),
                                            ),
                                          ],
                                        ],
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
      backgroundColor: dark ? const Color(0xFF1B0F33) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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
                      if (context.mounted) Navigator.pop(context);
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
    );

    if (result == 'save') {
      if (script == null) {
        await store.addScript(titleCtrl.text, bodyCtrl.text);
      } else {
        await store.updateScript(script, titleCtrl.text, bodyCtrl.text);
      }
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
