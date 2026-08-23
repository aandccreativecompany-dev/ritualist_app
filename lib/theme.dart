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
    primary: dark ? Brand.gold : Brand.goldLight,
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

  static Color cardBorder(bool dark) => dark
      ? Brand.gold.withValues(alpha: 0.18)
      : Brand.base.withValues(alpha: 0.10);

  static Color accentCard(bool dark) =>
      dark ? Brand.gold.withValues(alpha: 0.07) : Brand.creamCard;

  static Color accentBorder(bool dark) => dark
      ? Brand.gold.withValues(alpha: 0.28)
      : Brand.goldLight.withValues(alpha: 0.42);

  static Color accent(bool dark) => dark ? Brand.gold : Brand.goldLight;
  static Color accentText(bool dark) => dark ? Brand.goldPale : Brand.base;
  static Color heading(bool dark) => dark ? Colors.white : Brand.base;
  static Color bodyText(bool dark) => dark ? Brand.bodyDark : Brand.base;
  static Color muted(bool dark) => dark ? Brand.mutedDark : Brand.mutedLight;
  static Color eyebrow(bool dark) => dark ? Brand.gold : Brand.goldDeep;

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
