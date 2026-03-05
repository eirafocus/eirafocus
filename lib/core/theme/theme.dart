import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Theme mode state ──────────────────────────────────────────
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ─── Theme definition ──────────────────────────────────────────
class EiraTheme {
  // Logo-derived greens
  static const Color emerald = Color(0xFF2E7D32); // deep logo green
  static const Color leaf = Color(0xFF43A047); // mid green
  static const Color mint = Color(0xFF66BB6A); // bright green
  static const Color forest = Color(0xFF1B5E20); // darkest green

  // Feature accent palette — all green-family
  static const Color breathingColor = Color(0xFF43A047); // leaf green
  static const Color meditationColor = Color(0xFF00897B); // teal green
  static const Color statsColor = Color(0xFF66BB6A); // mint green
  static const Color historyColor = Color(0xFF2E7D32); // deep emerald

  // ─── Text Theme ──────────────────────────────────────────────
  static TextTheme _textTheme(Color onSurface) {
    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -1.5),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: onSurface),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: onSurface.withAlpha(180)),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0.5),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onSurface.withAlpha(180)),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: onSurface.withAlpha(140), letterSpacing: 0.5),
      ),
    );
  }

  // ─── Light Theme ───────────────────────────────────────────────
  static ThemeData get lightTheme {
    const bg = Color(0xFFF6F9F4); // very light green-tinted white
    const surface = Colors.white;
    const onSurface = Color(0xFF111B11); // near-black green for strong contrast
    const muted = Color(0xFF3A4A3A);
    const outline = Color(0xFFDDE5DD); // green-tinted border

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: emerald,
        secondary: leaf,
        tertiary: meditationColor,
        surface: surface,
        onSurface: onSurface,
        outline: outline,
        primaryContainer: Color(0xFFE8F5E9),
        onPrimaryContainer: forest,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: _textTheme(onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(color: onSurface, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: const BorderSide(color: outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: emerald, width: 1.5)),
        hintStyle: GoogleFonts.inter(color: muted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: muted, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bg,
        side: const BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, color: onSurface, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1, space: 0),
      sliderTheme: SliderThemeData(
        activeTrackColor: emerald,
        inactiveTrackColor: emerald.withAlpha(35),
        thumbColor: emerald,
        overlayColor: emerald.withAlpha(25),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surface,
      ),
    );
  }

  // ─── Dark Theme ────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const bg = Color(0xFF0B110B); // very dark green-black
    const surface = Color(0xFF141E14); // dark green card
    const onSurface = Color(0xFFE8F0E8); // light green-white
    const muted = Color(0xFF8FA38F);
    const outline = Color(0xFF243024); // dark green border

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: mint,
        secondary: leaf,
        tertiary: meditationColor,
        surface: surface,
        onSurface: onSurface,
        outline: outline,
        primaryContainer: Color(0xFF1B3A1B),
        onPrimaryContainer: mint,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: _textTheme(onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(color: onSurface, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mint,
          foregroundColor: Color(0xFF0B110B),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: const BorderSide(color: outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: mint, width: 1.5)),
        hintStyle: GoogleFonts.inter(color: muted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: muted, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: const BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, color: onSurface, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.inter(color: bg, fontWeight: FontWeight.w500),
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1, space: 0),
      sliderTheme: SliderThemeData(
        activeTrackColor: mint,
        inactiveTrackColor: mint.withAlpha(35),
        thumbColor: mint,
        overlayColor: mint.withAlpha(25),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surface,
      ),
    );
  }

  // ─── Smooth page route ─────────────────────────────────────────
  static Route<T> smoothRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(curve),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curve),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }
}
