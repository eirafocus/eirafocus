import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme mode state ──────────────────────────────────────────
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ─── Accent color state ────────────────────────────────────────
class AccentColorPreset {
  final String name;
  final Color primary;
  final Color primaryLight; // for dark mode
  final Color breathing;
  final Color meditation;
  final Color stats;
  final Color history;

  const AccentColorPreset({
    required this.name,
    required this.primary,
    required this.primaryLight,
    required this.breathing,
    required this.meditation,
    required this.stats,
    required this.history,
  });

  static const List<AccentColorPreset> presets = [
    AccentColorPreset(
      name: 'Emerald',
      primary: Color(0xFF2E7D32),
      primaryLight: Color(0xFF66BB6A),
      breathing: Color(0xFF43A047),
      meditation: Color(0xFF00897B),
      stats: Color(0xFF66BB6A),
      history: Color(0xFF2E7D32),
    ),
    AccentColorPreset(
      name: 'Ocean',
      primary: Color(0xFF1565C0),
      primaryLight: Color(0xFF64B5F6),
      breathing: Color(0xFF1E88E5),
      meditation: Color(0xFF0097A7),
      stats: Color(0xFF42A5F5),
      history: Color(0xFF1565C0),
    ),
    AccentColorPreset(
      name: 'Lavender',
      primary: Color(0xFF6A1B9A),
      primaryLight: Color(0xFFBA68C8),
      breathing: Color(0xFF8E24AA),
      meditation: Color(0xFF5C6BC0),
      stats: Color(0xFFAB47BC),
      history: Color(0xFF6A1B9A),
    ),
    AccentColorPreset(
      name: 'Sunset',
      primary: Color(0xFFE65100),
      primaryLight: Color(0xFFFF8A65),
      breathing: Color(0xFFF4511E),
      meditation: Color(0xFFFF6F00),
      stats: Color(0xFFFF7043),
      history: Color(0xFFE65100),
    ),
    AccentColorPreset(
      name: 'Rose',
      primary: Color(0xFFC62828),
      primaryLight: Color(0xFFEF5350),
      breathing: Color(0xFFE53935),
      meditation: Color(0xFFAD1457),
      stats: Color(0xFFEF5350),
      history: Color(0xFFC62828),
    ),
    AccentColorPreset(
      name: 'Teal',
      primary: Color(0xFF00695C),
      primaryLight: Color(0xFF4DB6AC),
      breathing: Color(0xFF00897B),
      meditation: Color(0xFF00838F),
      stats: Color(0xFF26A69A),
      history: Color(0xFF00695C),
    ),
  ];
}

class AccentColorNotifier extends Notifier<int> {
  @override
  int build() {
    _loadSaved();
    return 0; // default: Emerald
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('accent_color_index') ?? 0;
    if (idx != state && idx >= 0 && idx < AccentColorPreset.presets.length) {
      state = idx;
    }
  }

  Future<void> setIndex(int idx) async {
    if (idx >= 0 && idx < AccentColorPreset.presets.length) {
      state = idx;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('accent_color_index', idx);
    }
  }
}

final accentColorProvider =
    NotifierProvider<AccentColorNotifier, int>(AccentColorNotifier.new);

// ─── Theme definition ──────────────────────────────────────────
class EiraTheme {
  // Logo-derived greens (defaults)
  static const Color emerald = Color(0xFF2E7D32);
  static const Color leaf = Color(0xFF43A047);
  static const Color mint = Color(0xFF66BB6A);
  static const Color forest = Color(0xFF1B5E20);

  // Active accent — updated by provider
  static AccentColorPreset _accent = AccentColorPreset.presets[0];
  static void setAccent(int index) {
    if (index >= 0 && index < AccentColorPreset.presets.length) {
      _accent = AccentColorPreset.presets[index];
    }
  }

  // Feature accent palette — dynamic
  static Color get breathingColor => _accent.breathing;
  static Color get meditationColor => _accent.meditation;
  static Color get statsColor => _accent.stats;
  static Color get historyColor => _accent.history;

  // ─── Text Theme ──────────────────────────────────────────────
  static TextTheme _textTheme(Color onSurface) {
    const emojiFont = ['Apple Color Emoji', 'Noto Color Emoji'];
    TextStyle? _e(TextStyle? s) => s?.copyWith(
      fontFamilyFallback: [...(s.fontFamilyFallback ?? []), ...emojiFont],
    );

    final base = GoogleFonts.interTextTheme(
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

    return base.copyWith(
      displayLarge: _e(base.displayLarge),
      displayMedium: _e(base.displayMedium),
      headlineLarge: _e(base.headlineLarge),
      headlineMedium: _e(base.headlineMedium),
      titleLarge: _e(base.titleLarge),
      titleMedium: _e(base.titleMedium),
      titleSmall: _e(base.titleSmall),
      bodyLarge: _e(base.bodyLarge),
      bodyMedium: _e(base.bodyMedium),
      bodySmall: _e(base.bodySmall),
      labelLarge: _e(base.labelLarge),
      labelMedium: _e(base.labelMedium),
      labelSmall: _e(base.labelSmall),
    );
  }

  // ─── Light Theme ───────────────────────────────────────────────
  static ThemeData get lightTheme {
    const bg = Color(0xFFF7F8F6);
    const surface = Colors.white;
    const onSurface = Color(0xFF1A1A1A);
    const muted = Color(0xFF4A4A4A);
    const outline = Color(0xFFE0E0E0);
    final primary = _accent.primary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: _accent.breathing,
        tertiary: _accent.meditation,
        surface: surface,
        onSurface: onSurface,
        outline: outline,
        primaryContainer: primary.withAlpha(25),
        onPrimaryContainer: primary,
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
          backgroundColor: primary,
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
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 1.5)),
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
        activeTrackColor: primary,
        inactiveTrackColor: primary.withAlpha(35),
        thumbColor: primary,
        overlayColor: primary.withAlpha(25),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surface,
      ),
    );
  }

  // ─── Dark Theme ────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const bg = Color(0xFF181819);
    const surface = Color(0xFF222224);
    const onSurface = Color(0xFFE8E8E8);
    const muted = Color(0xFF8F8F8F);
    const outline = Color(0xFF2E2E30);
    final primary = _accent.primaryLight;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: _accent.breathing,
        tertiary: _accent.meditation,
        surface: surface,
        onSurface: onSurface,
        outline: outline,
        primaryContainer: primary.withAlpha(30),
        onPrimaryContainer: primary,
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
          backgroundColor: primary,
          foregroundColor: const Color(0xFF0F0F0F),
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
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 1.5)),
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
        activeTrackColor: primary,
        inactiveTrackColor: primary.withAlpha(35),
        thumbColor: primary,
        overlayColor: primary.withAlpha(25),
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
