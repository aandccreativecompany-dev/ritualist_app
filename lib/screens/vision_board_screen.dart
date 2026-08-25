import 'dart:io';
import 'dart:math' as math;

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
                    if (items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                        child: _ShapePicker(dark: dark),
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
                                    child: ClipPath(
                                      clipper: _shapeClipper(store.visionBoardShape),
                                      child: Container(
                                      decoration: BoxDecoration(
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
            child: SingleChildScrollView(
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

CustomClipper<Path> _shapeClipper(String shape) {
  switch (shape) {
    case 'circle':
      return const _CircleClipper();
    case 'star':
      return const _StarClipper();
    default:
      return const _RoundedSquareClipper();
  }
}

/// Segmented control letting the user pick how vision board tiles are
/// clipped: a friendly rounded square, a circle, or a star.
class _ShapePicker extends StatelessWidget {
  final bool dark;
  const _ShapePicker({required this.dark});

  static const _options = [
    ('square', Icons.crop_square_rounded, 'Square'),
    ('circle', Icons.circle_outlined, 'Circle'),
    ('star', Icons.star_outline_rounded, 'Star'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = store.visionBoardShape;
    return Row(
      children: [
        for (final (value, icon, labelText) in _options)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                await store.setVisionBoardShape(value);
                if (context.mounted) toastSaved(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: current == value
                      ? Surfaces.accent(dark).withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: current == value
                        ? Surfaces.accent(dark)
                        : Surfaces.accentBorder(dark),
                    width: current == value ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 15,
                        color:
                            current == value ? Surfaces.accent(dark) : Surfaces.muted(dark)),
                    const SizedBox(width: 5),
                    Text(labelText,
                        style: body(11.5,
                            current == value ? Surfaces.accent(dark) : Surfaces.muted(dark),
                            weight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundedSquareClipper extends CustomClipper<Path> {
  const _RoundedSquareClipper();
  @override
  Path getClip(Size size) => Path()
    ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(18)));
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CircleClipper extends CustomClipper<Path> {
  const _CircleClipper();
  @override
  Path getClip(Size size) {
    final side = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    return Path()..addOval(Rect.fromCenter(center: center, width: side, height: side));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Five-point star, inscribed in the tile so it still reads clearly at
/// grid-tile size.
class _StarClipper extends CustomClipper<Path> {
  const _StarClipper();
  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2;
    final innerRadius = outerRadius * 0.42;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (-90 + i * 36) * math.pi / 180;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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
