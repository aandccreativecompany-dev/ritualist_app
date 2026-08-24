import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Icon lookup for `kHabitIconNames` — kept alongside the model so a saved
/// icon name always resolves to something even if the curated set changes.
const Map<String, IconData> kHabitIcons = {
  'edit_note': Icons.edit_note,
  'directions_walk': Icons.directions_walk,
  'self_improvement': Icons.self_improvement,
  'water_drop': Icons.water_drop_outlined,
  'menu_book': Icons.menu_book_outlined,
  'bedtime': Icons.bedtime_outlined,
  'no_cell': Icons.phonelink_erase_outlined,
  'restaurant': Icons.restaurant_outlined,
  'fitness_center': Icons.fitness_center,
  'favorite': Icons.favorite_outline,
  'wb_sunny': Icons.wb_sunny_outlined,
  'volunteer_activism': Icons.volunteer_activism_outlined,
};

IconData habitIconFor(int index) =>
    kHabitIcons[kHabitIconNames[index % kHabitIconNames.length]] ??
    Icons.edit_note;

/// A rotation of on-brand colors a habit can be tagged with.
const List<Color> kHabitColors = [
  Brand.gold,
  Brand.violet,
  Brand.goldDeep,
  Brand.mutedDark,
  Brand.goldLight,
];

Color habitColorFor(int index) => kHabitColors[index % kHabitColors.length];

/// Small colored circle carrying a habit's icon — used on the home card and
/// the detail screen so a habit reads at a glance, not just as a line of text.
class HabitBadge extends StatelessWidget {
  final int iconIndex;
  final int colorIndex;
  final double size;
  const HabitBadge({
    super.key,
    required this.iconIndex,
    required this.colorIndex,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final color = habitColorFor(colorIndex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(habitIconFor(iconIndex), color: color, size: size * 0.52),
    );
  }
}

/// The card shell every module on the home stack sits in.
class ModuleCard extends StatelessWidget {
  final String? eyebrow;
  final Widget child;
  final bool accent;
  final EdgeInsets padding;

  const ModuleCard({
    super.key,
    this.eyebrow,
    required this.child,
    this.accent = false,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color:
            accent ? Surfaces.accentCard(dark) : Surfaces.card(dark),
        border: Border.all(
            color: accent
                ? Surfaces.accentBorder(dark)
                : Surfaces.cardBorder(dark)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(eyebrow!.toUpperCase(), style: label(Surfaces.eyebrow(dark))),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  final String labelText;
  final VoidCallback onPressed;

  const GoldButton({super.key, required this.labelText, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Surfaces.accent(dark),
          foregroundColor: Brand.deep,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          textStyle: body(14.5, Brand.deep, weight: FontWeight.w700),
        ),
        child: Text(labelText),
      ),
    );
  }
}

class CheckSquare extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;
  final double size;

  const CheckSquare({
    super.key,
    required this.checked,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = Surfaces.accent(dark);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checked ? accent : Colors.transparent,
          border: Border.all(
              color: checked ? accent : accent.withValues(alpha: 0.45),
              width: 1.5),
          borderRadius: BorderRadius.circular(7),
        ),
        child: checked
            ? Icon(Icons.check, size: size * 0.62, color: Brand.deep)
            : null,
      ),
    );
  }
}

/// Bottom-sheet editor for a habit's name, icon and color — used both when
/// adding a new habit and when restyling an existing one. Pops
/// `(name, iconIndex, colorIndex)` on save, or null if dismissed.
class HabitEditorSheet extends StatefulWidget {
  final String initialName;
  final int initialIcon;
  final int initialColor;
  const HabitEditorSheet({
    super.key,
    this.initialName = '',
    this.initialIcon = 0,
    this.initialColor = 0,
  });

  @override
  State<HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<HabitEditorSheet> {
  late final _controller = TextEditingController(text: widget.initialName);
  late int _icon = widget.initialIcon;
  late int _color = widget.initialColor;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: Surfaces.card(dark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.initialName.isEmpty ? 'New habit' : 'Edit habit',
                style: display(18, Surfaces.heading(dark))),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: body(15, Surfaces.bodyText(dark), weight: FontWeight.w600),
              decoration: const InputDecoration(hintText: 'Walk 30 minutes'),
            ),
            const SizedBox(height: 18),
            Text('ICON', style: label(Surfaces.eyebrow(dark))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < kHabitIconNames.length; i++)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _icon = i),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _icon == i
                            ? habitColorFor(_color).withValues(alpha: 0.22)
                            : Colors.transparent,
                        border: Border.all(
                          color: _icon == i
                              ? habitColorFor(_color)
                              : Surfaces.muted(dark).withValues(alpha: 0.25),
                          width: _icon == i ? 2 : 1,
                        ),
                      ),
                      child: Icon(habitIconFor(i),
                          size: 18,
                          color: _icon == i
                              ? habitColorFor(_color)
                              : Surfaces.muted(dark)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('COLOR', style: label(Surfaces.eyebrow(dark))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: [
                for (var i = 0; i < kHabitColors.length; i++)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _color = i),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kHabitColors[i],
                        border: Border.all(
                          color: _color == i
                              ? Surfaces.heading(dark)
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            GoldButton(
              labelText: widget.initialName.isEmpty ? 'Add habit' : 'Save',
              onPressed: () {
                if (_controller.text.trim().isEmpty) return;
                Navigator.pop(context, (_controller.text, _icon, _color));
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Hand-rolled gold-on-ink toggle, matching the designed switches.
class BrandSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const BrandSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = Surfaces.accent(dark);
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 44,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 44,
            height: 25,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value
                  ? accent
                  : Surfaces.muted(dark).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: value ? Brand.deep : Surfaces.muted(dark),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
