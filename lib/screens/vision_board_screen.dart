import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'vision_layouts_screen.dart';

/// A collage of what the user is working toward — a picked photo (saved from
/// Pinterest, a screenshot, anything in the gallery) with a word or sentence
/// captioning it, or a caption-only tile when there's no image yet. Every
/// tile can now have its own shape and size (long-press or tap "Customize"),
/// and a gallery of 25 curated layouts can restyle the whole board in one tap.
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
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const VisionLayoutsScreen())),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: Surfaces.accent(dark).withValues(alpha: 0.10),
                                    border:
                                        Border.all(color: Surfaces.accent(dark).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.dashboard_customize_outlined,
                                          size: 16, color: Surfaces.accent(dark)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          store.visionBoardLayoutName == null
                                              ? 'Browse 25 board layouts'
                                              : 'Layout: ${store.visionBoardLayoutName}',
                                          style: body(12.5, Surfaces.accent(dark),
                                              weight: FontWeight.w700),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(Icons.chevron_right,
                                          size: 16, color: Surfaces.accent(dark)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                              child: StaggeredGrid.count(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                children: [
                                  for (var i = 0; i < items.length; i++)
                                    StaggeredGridTile.count(
                                      crossAxisCellCount: items[i].spanX.clamp(1, 2),
                                      mainAxisCellCount: items[i].spanY.clamp(1, 2),
                                      child: _VisionTile(
                                        item: items[i],
                                        index: i,
                                        color: _hatchColors[items[i].colorIndex % _hatchColors.length],
                                        dark: dark,
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
      },
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

class _VisionTile extends StatelessWidget {
  final VisionItem item;
  final int index;
  final Color color;
  final bool dark;
  const _VisionTile({required this.item, required this.index, required this.color, required this.dark});

  @override
  Widget build(BuildContext context) {
    final shape = item.shape.isEmpty ? store.visionBoardShape : item.shape;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openCustomizer(context),
      onLongPress: () async {
        final remove = await _confirmRemove(context, item.caption);
        if (remove == true) {
          await store.removeVisionItem(item);
          if (context.mounted) toastSaved(context, label: 'Removed');
        }
      },
      child: ClipPath(
        clipper: _shapeClipper(shape),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
            color: color.withValues(alpha: dark ? 0.08 : 0.1),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.imagePath != null)
                Align(
                  alignment: Alignment(
                      (item.imageOffsetX - 0.5) * 2, (item.imageOffsetY - 0.5) * 2),
                  child: Transform.scale(
                    scale: item.imageZoom,
                    child: Image.file(
                      File(item.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          CustomPaint(painter: _HatchPainter(color: color)),
                    ),
                  ),
                )
              else
                CustomPaint(painter: _HatchPainter(color: color)),
              if (item.imagePath != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
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
                    style: body(13, item.imagePath != null ? Colors.white : Surfaces.heading(dark),
                        weight: FontWeight.w700),
                  ),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.tune, size: 15, color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmRemove(BuildContext context, String caption) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(caption.isEmpty ? 'Remove this tile?' : 'Remove "$caption"?',
            style: display(16, Surfaces.heading(dark))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
  }

  void _openCustomizer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TileCustomizerSheet(item: item),
    );
  }
}

/// Per-tile editor: pick a shape, pick a size, and — when there's a photo —
/// drag to recentre it and use a slider to zoom, so the image stays well
/// composed no matter what shape or size the tile ends up as.
class _TileCustomizerSheet extends StatefulWidget {
  final VisionItem item;
  const _TileCustomizerSheet({required this.item});

  @override
  State<_TileCustomizerSheet> createState() => _TileCustomizerSheetState();
}

class _TileCustomizerSheetState extends State<_TileCustomizerSheet> {
  late String _shape;
  late int _spanX;
  late int _spanY;
  late double _offsetX;
  late double _offsetY;
  late double _zoom;

  static const _sizeOptions = [
    ('Small', 1, 1),
    ('Wide', 2, 1),
    ('Tall', 1, 2),
    ('Large', 2, 2),
  ];

  @override
  void initState() {
    super.initState();
    _shape = widget.item.shape.isEmpty ? store.visionBoardShape : widget.item.shape;
    _spanX = widget.item.spanX;
    _spanY = widget.item.spanY;
    _offsetX = widget.item.imageOffsetX;
    _offsetY = widget.item.imageOffsetY;
    _zoom = widget.item.imageZoom;
  }

  Future<void> _save() async {
    await store.updateVisionItemStyle(
      widget.item,
      shape: _shape,
      spanX: _spanX,
      spanY: _spanY,
      imageOffsetX: _offsetX,
      imageOffsetY: _offsetY,
      imageZoom: _zoom,
    );
    if (mounted) {
      Navigator.pop(context);
      toastSaved(context, label: 'Tile updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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
              Text('Customize tile', style: display(18, Surfaces.heading(dark))),
              const SizedBox(height: 16),
              if (widget.item.imagePath != null) ...[
                Text('DRAG TO REPOSITION · PINCH TO ZOOM',
                    style: label(Surfaces.eyebrow(dark))),
                const SizedBox(height: 8),
                ClipPath(
                  clipper: _shapeClipper(_shape),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _offsetX = (_offsetX + details.delta.dx / 200).clamp(0.0, 1.0);
                        _offsetY = (_offsetY + details.delta.dy / 200).clamp(0.0, 1.0);
                      });
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      color: Colors.black12,
                      child: Align(
                        alignment: Alignment((_offsetX - 0.5) * 2, (_offsetY - 0.5) * 2),
                        child: Transform.scale(
                          scale: _zoom,
                          child: Image.file(File(widget.item.imagePath!), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.zoom_out, size: 16, color: Surfaces.muted(dark)),
                    Expanded(
                      child: Slider(
                        value: _zoom,
                        min: 1.0,
                        max: 2.5,
                        activeColor: Surfaces.accent(dark),
                        onChanged: (v) => setState(() => _zoom = v),
                      ),
                    ),
                    Icon(Icons.zoom_in, size: 16, color: Surfaces.muted(dark)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text('SHAPE', style: label(Surfaces.eyebrow(dark))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in kVisionShapes)
                    _Chip(
                      label: kVisionShapeLabels[s] ?? s,
                      selected: _shape == s,
                      dark: dark,
                      onTap: () => setState(() => _shape = s),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('SIZE', style: label(Surfaces.eyebrow(dark))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (name, sx, sy) in _sizeOptions)
                    _Chip(
                      label: name,
                      selected: _spanX == sx && _spanY == sy,
                      dark: dark,
                      onTap: () => setState(() {
                        _spanX = sx;
                        _spanY = sy;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              GoldButton(labelText: 'Save changes', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Surfaces.accent(dark).withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Surfaces.accent(dark) : Surfaces.accentBorder(dark),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(label,
            style: body(11.5, selected ? Surfaces.accent(dark) : Surfaces.muted(dark),
                weight: FontWeight.w600)),
      ),
    );
  }
}

CustomClipper<Path> _shapeClipper(String shape) {
  switch (shape) {
    case 'circle':
      return const _CircleClipper();
    case 'star':
      return const _StarClipper();
    case 'heart':
      return const _HeartClipper();
    case 'hexagon':
      return const _HexagonClipper();
    case 'diamond':
      return const _DiamondClipper();
    case 'roundedRect':
      return const _RoundedSquareClipper();
    default:
      return const _RoundedSquareClipper();
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

/// A heart shape built from two circular lobes and two curves to a bottom
/// point, scaled to fill the tile.
class _HeartClipper extends CustomClipper<Path> {
  const _HeartClipper();
  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final path = Path();
    path.moveTo(w / 2, h * 0.30);
    path.cubicTo(w * 0.1, -h * 0.05, -w * 0.1, h * 0.45, w / 2, h * 0.98);
    path.cubicTo(w * 1.1, h * 0.45, w * 0.9, -h * 0.05, w / 2, h * 0.30);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HexagonClipper extends CustomClipper<Path> {
  const _HexagonClipper();
  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (-90 + i * 60) * math.pi / 180;
      final point = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
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

class _DiamondClipper extends CustomClipper<Path> {
  const _DiamondClipper();
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
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
  bool shouldRepaint(covariant _HatchPainter oldDelegate) => oldDelegate.color != color;
}
