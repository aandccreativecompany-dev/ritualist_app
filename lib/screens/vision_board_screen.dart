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
                          child: Text('Vision board',
                              style: body(14, Surfaces.heading(dark),
                                  weight: FontWeight.w600)),
                        ),
                        IconButton(
                          onPressed: () => _addItem(context),
                          icon: Icon(Icons.add, color: Surfaces.accent(dark)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pin a saved photo (from Pinterest or anywhere) with a\n'
                        'word or sentence, or just the words on their own.',
                        style: body(12, Surfaces.muted(dark)),
                      ),
                    ),
                  ),
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
                              return InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onLongPress: () async {
                                  await store.removeVisionItem(item);
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
                              );
                            },
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

  Future<void> _addItem(BuildContext context) async {
    final controller = TextEditingController();
    final dark = Theme.of(context).brightness == Brightness.dark;
    String? pickedPath;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('New tile', style: display(18, Surfaces.heading(dark))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final path = await _pickAndCopyImage();
                  if (path != null) setState(() => pickedPath = path);
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
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
                decoration: const InputDecoration(
                    hintText: 'A word or sentence for this tile'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add')),
          ],
        ),
      ),
    );

    if (result == true) {
      await store.addVisionItem(controller.text, imagePath: pickedPath);
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
