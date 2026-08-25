import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// A collage of what the user is working toward — a picked photo (saved from
/// Pinterest, a screenshot, anything in the gallery) with a word or sentence
/// captioning it, or a caption-only tile when there's no image yet.
class VisionBoardScreen extends StatelessWidget {
  const VisionBoardScreen({super.key});

  static const _hatchColors = [Brand.gold, Brand.violet, Brand.goldLight, Brand.mutedDark];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final items = store.visionItems;
        return Scaffold(
          body: Container(
            decoration: Surfaces.pageBackground(dark),
            child: SafeArea(
              child: FadeSlideIn(
                child: Column(
                  children: [
                    ScreenHeader(
                      icon: Icons.grid_view_rounded,
                      title: 'Vision board',
                      subtitle: 'Pin a photo with a word or sentence, or just the words.',
                      actions: [
                        IconButton(
                          onPressed: () => _addItem(context),
                          icon: Icon(Icons.add_circle_outline, color: Surfaces.accent(dark)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.grid_view_rounded,
                                        color: Surfaces.accent(dark), size: 30),
                                    const SizedBox(height: 16),
                                    Text('Nothing pinned yet',
                                        style: display(18, Surfaces.heading(dark))),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add a tile for anything you\'re working toward.',
                                      style: body(13, Surfaces.muted(dark)),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    GoldButton(
                                        labelText: 'Add your first tile',
                                        onPressed: () => _addItem(context)),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.92,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final item = items[i];
                                final color =
                                    _hatchColors[item.colorIndex % _hatchColors.length];
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(milliseconds: 260 + i * 40),
                                  curve: Curves.easeOutBack,
                                  builder: (context, t, child) => Transform.scale(
                                    scale: 0.85 + (t.clamp(0, 1) * 0.15),
                                    child: Opacity(opacity: t.clamp(0, 1), child: child),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onLongPress: () async {
                                      final remove = await _confirmRemove(context, item.caption);
                                      if (remove == true) {
                                        await store.removeVisionItem(item);
                                        if (context.mounted) toastSaved(context, label: 'Removed');
                                      }
                                    },
                                    child: Container(
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                            color: color.withValues(alpha: 0.35),
                                            width: 1.5),
                                        color: color.withValues(alpha: dark ? 0.08 : 0.1),
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (item.imagePath != null)
                                            Image.file(
                                              File(item.imagePath!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  CustomPaint(painter: _HatchPainter(color: color)),
                                            )
                                          else
                                            CustomPaint(painter: _HatchPainter(color: color)),
                                          if (item.imagePath != null)
                                            DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withValues(alpha: 0.55),
                                                  ],
                                                  stops: const [0.5, 1.0],
                                                ),
                                              ),
                                            ),
                                          if (item.caption.isNotEmpty)
                                            Positioned(
                                              left: 12,
                                              right: 12,
                                              bottom: 12,
                                              child: Text(
                                                item.caption,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: body(
                                                    13,
                                                    item.imagePath != null
                                                        ? Colors.white
                                                        : Surfaces.heading(dark),
                                                    weight: FontWeight.w700),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
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

  Future<bool?> _confirmRemove(BuildContext context, String caption) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            caption.isEmpty ? 'Remove this tile?' : 'Remove "$caption"?',
            style: display(16, Surfaces.heading(dark))),
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
  }

  Future<void> _addItem(BuildContext context) async {
    final controller = TextEditingController();
    final dark = Theme.of(context).brightness == Brightness.dark;
    String? pickedPath;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: Surfaces.card(dark),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New tile', style: display(18, Surfaces.heading(dark))),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final path = await _pickAndCopyImage();
                    if (path != null) setState(() => pickedPath = path);
                  },
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Brand.gold.withValues(alpha: 0.1),
                      border: Border.all(color: Brand.gold.withValues(alpha: 0.4)),
                    ),
                    child: pickedPath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: Surfaces.accent(dark)),
                              const SizedBox(height: 6),
                              Text('Add a photo from your gallery\n(optional)',
                                  textAlign: TextAlign.center,
                                  style: body(11.5, Surfaces.muted(dark))),
                            ],
                          )
                        : Image.file(File(pickedPath!), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: pickedPath == null,
                  textCapitalization: TextCapitalization.sentences,
                  style: body(14, Surfaces.bodyText(dark)),
                  decoration: const InputDecoration(
                      hintText: 'A word or sentence for this tile'),
                ),
                const SizedBox(height: 18),
                GoldButton(
                  labelText: 'Save tile',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      await store.addVisionItem(controller.text, imagePath: pickedPath);
      if (context.mounted) toastSaved(context);
    }
  }

  /// Opens the device gallery and copies the chosen image into app-local
  /// storage, so it keeps working even if the original is deleted from the
  /// gallery. Returns null on cancel or on any picker/copy failure.
  Future<String?> _pickAndCopyImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return null;
      final dir = await getApplicationDocumentsDirectory();
      final visionDir = Directory(p.join(dir.path, 'vision_board'));
      if (!await visionDir.exists()) await visionDir.create(recursive: true);
      final ext = p.extension(picked.path).isNotEmpty ? p.extension(picked.path) : '.jpg';
      final dest = p.join(
          visionDir.path, '${DateTime.now().microsecondsSinceEpoch}$ext');
      await File(picked.path).copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }
}

/// Diagonal hatch lines standing in for a photo, used when a tile has no
/// image yet.
class _HatchPainter extends CustomPainter {
  final Color color;
  const _HatchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    const gap = 10.0;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter oldDelegate) =>
      oldDelegate.color != color;
}
