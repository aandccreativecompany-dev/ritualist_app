import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens, lifted from the Ritualist design set.
class Brand {
  static const deep = Color(0xFF150C28);
  static const base = Color(0xFF1B0F33);
  static const violet = Color(0xFF4C2A85);
  static const gold = Color(0xFFF2B93B);
  static const goldLight = Color(0xFFE0A419);
  static const goldDeep = Color(0xFFB07E10);
  static const goldPale = Color(0xFFFFE9A8);
  static const cream = Color(0xFFFAF4E9);
  static const creamCard = Color(0xFFFFF7E4);
  static const bodyDark = Color(0xFFE8DFFA);
  static const mutedDark = Color(0xFF8A7BB5);
  static const mutedLight = Color(0xFF9C93AE);
}

/// One selectable app accent color — swaps in for the gold used everywhere
/// an "accent" surface is requested (icons, chips, highlights, the primary
/// button color's glow). [dark]/[light] are the two brightness variants,
/// [pale] is the soft tint used for accent text on a dark background, and
/// [deep] is the darker variant used for eyebrow labels on a light
/// background — mirrors the roles Brand.gold's four shades already played.
class AccentPalette {
  final String id;
  final String label;
  final Color dark;
  final Color light;
  final Color pale;
  final Color deep;
  const AccentPalette({
    required this.id,
    required this.label,
    required this.dark,
    required this.light,
    required this.pale,
    required this.deep,
  });
}

const kAccentPalettes = [
  AccentPalette(
    id: 'gold',
    label: 'Gold',
    dark: Brand.gold,
    light: Brand.goldLight,
    pale: Brand.goldPale,
    deep: Brand.goldDeep,
  ),
  AccentPalette(
    id: 'rose',
    label: 'Rose',
    dark: Color(0xFFF08BA0),
    light: Color(0xFFD9536F),
    pale: Color(0xFFFBD9E1),
    deep: Color(0xFFB23A54),
  ),
  AccentPalette(
    id: 'amethyst',
    label: 'Amethyst',
    dark: Color(0xFFC79BF0),
    light: Color(0xFF9B5DE5),
    pale: Color(0xFFE9D9FB),
    deep: Color(0xFF6E31B0),
  ),
  AccentPalette(
    id: 'emerald',
    label: 'Emerald',
    dark: Color(0xFF6FDCA8),
    light: Color(0xFF23A870),
    pale: Color(0xFFCFF7E4),
    deep: Color(0xFF17754D),
  ),
  AccentPalette(
    id: 'sky',
    label: 'Sky',
    dark: Color(0xFF7FC8F8),
    light: Color(0xFF2E9BE6),
    pale: Color(0xFFD6EEFD),
    deep: Color(0xFF1B6FA8),
  ),
  AccentPalette(
    id: 'coral',
    label: 'Coral',
    dark: Color(0xFFFF9770),
    light: Color(0xFFF06A3F),
    pale: Color(0xFFFFDECE),
    deep: Color(0xFFB8481F),
  ),
];

/// The currently selected accent, module-level so [Surfaces] (a pure,
/// no-context helper used everywhere) can read it without needing access
/// to the store — store.dart calls [setAccentId] whenever the user changes
/// it in Settings, then notifies listeners so every AnimatedBuilder(store)
/// screen repaints with the new colors.
String _accentId = 'gold';

void setAccentId(String id) {
  if (kAccentPalettes.any((p) => p.id == id)) _accentId = id;
}

String get currentAccentId => _accentId;

AccentPalette get currentAccent =>
    kAccentPalettes.firstWhere((p) => p.id == _accentId, orElse: () => kAccentPalettes.first);

TextStyle display(double size, Color color) =>
    GoogleFonts.archivoBlack(fontSize: size, color: color, height: 1.25);

TextStyle body(double size, Color color,
        {FontWeight weight = FontWeight.w400, double height = 1.55}) =>
    GoogleFonts.inter(
        fontSize: size, color: color, fontWeight: weight, height: height);

TextStyle label(Color color) => GoogleFonts.inter(
    fontSize: 10,
    color: color,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
    height: 1.4);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.violet,
    brightness: brightness,
    primary: dark ? currentAccent.dark : currentAccent.light,
    surface: dark ? Brand.base : Brand.cream,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? Brand.deep : Brand.cream,
    splashFactory: InkSparkle.splashFactory,
    textTheme: GoogleFonts.interTextTheme(
        brightness == Brightness.dark ? ThemeData.dark().textTheme : null),
  );
}

/// Surfaces used by the card stack.
class Surfaces {
  static Color card(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.04) : Colors.white;

  /// A fully opaque surface for anything that floats above other content —
  /// modal bottom sheets, dialogs — where [card]'s near-transparent dark-mode
  /// fill let whatever's underneath bleed through and made the sheet's own
  /// text unreadable.
  static Color sheet(bool dark) => dark ? Brand.base : Colors.white;

  static Color cardBorder(bool dark) => dark
      ? currentAccent.dark.withValues(alpha: 0.18)
      : Brand.base.withValues(alpha: 0.10);

  static Color accentCard(bool dark) =>
      dark ? currentAccent.dark.withValues(alpha: 0.07) : Brand.creamCard;

  static Color accentBorder(bool dark) => dark
      ? currentAccent.dark.withValues(alpha: 0.28)
      : currentAccent.light.withValues(alpha: 0.42);

  static Color accent(bool dark) => dark ? currentAccent.dark : currentAccent.light;
  static Color accentText(bool dark) => dark ? currentAccent.pale : Brand.base;
  static Color heading(bool dark) => dark ? Colors.white : Brand.base;
  static Color bodyText(bool dark) => dark ? Brand.bodyDark : Brand.base;
  static Color muted(bool dark) => dark ? Brand.mutedDark : Brand.mutedLight;
  static Color eyebrow(bool dark) => dark ? currentAccent.dark : currentAccent.deep;

  static BoxDecoration pageBackground(bool dark) {
    if (!dark) return const BoxDecoration(color: Brand.cream);
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Brand.deep, Brand.base, Brand.violet],
        stops: [0.0, 0.45, 1.0],
      ),
    );
  }
}
