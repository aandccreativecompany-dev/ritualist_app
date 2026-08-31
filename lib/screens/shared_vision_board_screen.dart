import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/auth_service.dart';
import '../services/shared_board_service.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// A live, text-only shared board others can add their own points to,
/// using a short share code. Deliberately text-only — see
/// SharedBoardService's doc comment for why photos aren't part of this.
class SharedVisionBoardScreen extends StatefulWidget {
  const SharedVisionBoardScreen({super.key});

  @override
  State<SharedVisionBoardScreen> createState() => _SharedVisionBoardScreenState();
}

class _SharedVisionBoardScreenState extends State<SharedVisionBoardScreen> {
  bool _loading = false;
  List<(String, String)> _points = [];

  @override
  void initState() {
    super.initState();
    if (store.sharedBoardCode != null) _refresh();
  }

  Future<void> _refresh() async {
    final code = store.sharedBoardCode;
    if (code == null) return;
    setState(() => _loading = true);
    final points = await SharedBoardService.instance.fetchPoints(code);
    if (mounted) {
      setState(() {
        _points = points;
        _loading = false;
      });
    }
  }

  Future<bool> _ensureSignedIn(BuildContext context) async {
    if (AuthService.instance.isSignedIn) return true;
    final signIn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign in to continue'),
        content: const Text(
            'Shared boards use your Google sign-in so points are attributed to someone, not left anonymous.',
            textAlign: TextAlign.justify),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign in')),
        ],
      ),
    );
    if (signIn != true) return false;
    final user = await AuthService.instance.signInWithGoogle();
    return user != null;
  }

  Future<void> _createBoard(BuildContext context) async {
    if (!await _ensureSignedIn(context)) return;
    final titleCtrl = TextEditingController();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Name your board', style: display(16, Surfaces.heading(dark))),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g. Our 2027 vision'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, titleCtrl.text),
              child: const Text('Create')),
        ],
      ),
    );
    if (title == null || title.trim().isEmpty) return;
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final code = await SharedBoardService.instance
          .createBoard(title: title.trim(), ownerUid: uid);
      await store.setSharedBoard(code, title.trim());
      if (mounted) {
        setState(() => _points = []);
        toastSaved(context, label: 'Board created');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't create the board — check your connection.")));
      }
    }
  }

  Future<void> _joinBoard(BuildContext context) async {
    final codeCtrl = TextEditingController();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join a shared board', style: display(16, Surfaces.heading(dark))),
        content: TextField(
          controller: codeCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'Enter the 6-character code'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, codeCtrl.text), child: const Text('Join')),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    final title = await SharedBoardService.instance.joinBoard(code);
    if (title == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("That code didn't match a board.")));
      }
      return;
    }
    await store.setSharedBoard(code.trim().toUpperCase(), title);
    await _refresh();
  }

  Future<void> _addPoint(BuildContext context) async {
    if (!await _ensureSignedIn(context)) return;
    final code = store.sharedBoardCode;
    if (code == null) return;
    final controller = TextEditingController();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add a point', style: display(16, Surfaces.heading(dark))),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'What would you add to this vision?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text), child: const Text('Add')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    final name = AuthService.instance.currentUser?.displayName ?? 'Someone';
    try {
      await SharedBoardService.instance.addPoint(code: code, text: text.trim(), addedByName: name);
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Couldn't add that — try again.")));
      }
    }
  }

  Future<void> _leaveBoard() async {
    await store.setSharedBoard(null, null);
    if (mounted) setState(() => _points = []);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final code = store.sharedBoardCode;
    final title = store.sharedBoardTitle;

    return Scaffold(
      body: Container(
        decoration: Surfaces.pageBackground(dark),
        child: SafeArea(
          child: FadeSlideIn(
            child: Column(
              children: [
                ScreenHeader(
                  icon: Icons.groups_outlined,
                  title: 'Shared board',
                  subtitle: code == null
                      ? 'Create one, or join with a code someone shared with you.'
                      : 'Anyone with the code can add their own point.',
                  actions: [
                    if (code != null)
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _refresh,
                        icon: Icon(Icons.refresh, color: Surfaces.accent(dark)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: code == null
                      ? _JoinOrCreate(onCreate: () => _createBoard(context), onJoin: () => _joinBoard(context))
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          color: Surfaces.accent(dark),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                            children: [
                              ModuleCard(
                                accent: true,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title ?? 'Shared board',
                                        style: display(17, Surfaces.heading(dark))),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text('Code: $code',
                                            style: body(13, Surfaces.accentText(dark),
                                                weight: FontWeight.w700)),
                                        const SizedBox(width: 10),
                                        InkWell(
                                          onTap: () => SharePlus.instance.share(ShareParams(
                                              text: 'Join my vision board on Prakriyā! Use code: $code')),
                                          child: Icon(Icons.ios_share,
                                              size: 16, color: Surfaces.accent(dark)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GoldButton(
                                              labelText: 'Add a point',
                                              onPressed: () => _addPoint(context)),
                                        ),
                                        const SizedBox(width: 10),
                                        TextButton(
                                          onPressed: _leaveBoard,
                                          child: Text('Leave',
                                              style: body(12.5, Colors.redAccent,
                                                  weight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_loading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              else if (_points.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text('Nothing added yet — be the first.',
                                        style: body(13, Surfaces.muted(dark))),
                                  ),
                                )
                              else
                                for (final point in _points)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ModuleCard(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.auto_awesome,
                                              size: 16, color: Surfaces.accent(dark)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(point.$1,
                                                    style: body(13.5, Surfaces.bodyText(dark))),
                                                if (point.$2.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text('— ${point.$2}',
                                                      style: body(11, Surfaces.muted(dark))),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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

class _JoinOrCreate extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _JoinOrCreate({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, color: Surfaces.accent(dark), size: 30),
            const SizedBox(height: 16),
            Text('No shared board yet', style: display(18, Surfaces.heading(dark)), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Start a new one, or join with a code someone sent you.',
                style: body(13, Surfaces.muted(dark)), textAlign: TextAlign.center),
            const SizedBox(height: 22),
            GoldButton(labelText: 'Create a shared board', onPressed: onCreate),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onJoin,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                side: BorderSide(color: Surfaces.accentBorder(dark)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Join with a code', style: body(13.5, Surfaces.accent(dark), weight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
