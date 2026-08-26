import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Browse all 25 curated vision-board layouts, grouped into 5 categories.
/// Tapping one applies its shape/size recipe to the user's existing tiles.
class VisionLayoutsScreen extends StatelessWidget {
  const VisionLayoutsScreen({super.key});

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
                    const ScreenHeader(
                      icon: Icons.dashboard_customize_outlined,
                      title: 'Board layouts',
                      subtitle: '25 curated arrangements, grouped by feel.',
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          for (final category in kVisionLayoutCategories) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10, top: 8),
                              child: Text(category.toUpperCase(),
                                  style: label(Surfaces.eyebrow(dark))),
                            ),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.05,
                              children: [
                                for (final layout in kVisionLayouts
                                    .where((l) => l.category == category))
                                  _LayoutCard(layout: layout, dark: dark),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
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
}

class _LayoutCard extends StatelessWidget {
  final VisionLayoutSpec layout;
  final bool dark;
  const _LayoutCard({required this.layout, required this.dark});

  @override
  Widget build(BuildContext context) {
    final current = store.visionBoardLayoutName == layout.name;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: store.visionItems.isEmpty
          ? null
          : () async {
              await store.applyVisionLayout(layout);
              if (context.mounted) {
                toastSaved(context, label: 'Layout applied');
              }
            },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Surfaces.card(dark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: current ? Surfaces.accent(dark) : Surfaces.cardBorder(dark),
            width: current ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(child: _LayoutPreview(layout: layout, dark: dark)),
            const SizedBox(height: 8),
            Text(layout.name,
                style: body(12, Surfaces.heading(dark), weight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

/// A tiny schematic preview of a layout's slot recipe — proportionally sized
/// rectangles, not real content, just enough to suggest the arrangement.
class _LayoutPreview extends StatelessWidget {
  final VisionLayoutSpec layout;
  final bool dark;
  const _LayoutPreview({required this.layout, required this.dark});

  @override
  Widget build(BuildContext context) {
    final accent = Surfaces.accent(dark);
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        for (final slot in layout.slots.take(6))
          Container(
            width: 18.0 * slot.$2,
            height: 18.0 * slot.$3,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.22),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(slot.$1 == 'circle' ? 20 : 4),
            ),
          ),
      ],
    );
  }
}
