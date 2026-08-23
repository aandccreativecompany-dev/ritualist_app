import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// A grid of captioned placeholders — no photo picker in v0.1 (no raster
/// assets, per the design bundle), so each tile is a hatched placeholder the
/// user labels with what it stands for.
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
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: color.withValues(alpha: 0.35),
                                        width: 1.5),
                                    color: color.withValues(alpha: dark ? 0.08 : 0.1),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(
                                            painter: _HatchPainter(color: color)),
                                      ),
                                      Positioned(
                                        left: 12,
                                        right: 12,
                                        bottom: 12,
                                        child: Text(
                                          item.caption,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: body(13, Surfaces.heading(dark),
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
    final caption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New tile', style: display(18, Surfaces.heading(dark))),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'What are you working toward?'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Add')),
        ],
      ),
    );
    if (caption != null) await store.addVisionItem(caption);
  }
}

/// Diagonal hatch lines standing in for a photo — matches the design's
/// "hatched placeholders where user photographs go".
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
