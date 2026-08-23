import 'package:flutter/material.dart';

import '../theme.dart';

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
