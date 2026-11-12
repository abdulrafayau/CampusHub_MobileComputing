import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LoopAir design tokens.
///
/// Direction: calm off-white canvas, borderless white cards with generous
/// radii, a deep navy "ink" for hero surfaces and active states, and a small
/// set of soft pastel tiles that give each section its own identity.
/// Flat colour only, no gradients. Headlines mix light and bold weights.
class AppColors {
  AppColors._();

  // Brand
  static const brand = Color(0xFF1F5FAE); // Air University blue
  static const brandDark = Color(0xFF17487F);
  static const brandTint = Color(0xFFE4EDF8);
  static const navy = Color(0xFF0F1E33); // hero / splash / active pill
  static const navySoft = Color(0xFF1B2D47);

  // Neutrals
  static const ink = Color(0xFF111622);
  static const body = Color(0xFF3B4253);
  static const muted = Color(0xFF6E7585);
  static const subtle = Color(0xFFA2A8B5);
  static const line = Color(0xFFE9EAEE);
  static const lineStrong = Color(0xFFD6D9E0);
  static const canvas = Color(0xFFF4F4F6);
  static const surface = Colors.white;
  static const sunken = Color(0xFFF0F1F4);

  // Pastel tiles (section identities)
  static const lavender = Color(0xFFDDDAF8);
  static const lavenderInk = Color(0xFF4B3FA8);
  static const butter = Color(0xFFF6E8B1);
  static const butterInk = Color(0xFF7A5B00);
  static const sage = Color(0xFFD3E8DC);
  static const sageInk = Color(0xFF256246);
  static const blush = Color(0xFFF5E1D8);
  static const blushInk = Color(0xFF8C3F22);
  static const sky = Color(0xFFD9E7F7);
  static const skyInk = Color(0xFF1F4F8A);

  // Semantic
  static const success = Color(0xFF14804A);
  static const successTint = Color(0xFFE3F3EA);
  static const warning = Color(0xFFB0620A);
  static const warningTint = Color(0xFFFCF0DD);
  static const danger = Color(0xFFC0362C);
  static const dangerTint = Color(0xFFFBE7E5);
  static const info = Color(0xFF2756C5);
  static const infoTint = Color(0xFFE6EDFC);

  // "Live now" accent
  static const live = Color(0xFFE0612A);
  static const liveTint = Color(0xFFFDEDE4);
}

class AppSpace {
  AppSpace._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const page = EdgeInsets.symmetric(horizontal: 20);
}

class AppRadius {
  AppRadius._();
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 28.0;
  static final card = BorderRadius.circular(md);
}

class AppText {
  AppText._();

  static TextStyle get _base => GoogleFonts.plusJakartaSans(color: AppColors.ink);

  /// Large editorial headline. Pair with [displayLight] in a Text.rich.
  static TextStyle get display => _base.copyWith(
      fontSize: 30, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.9);
  static TextStyle get displayLight => display.copyWith(fontWeight: FontWeight.w300);
  static TextStyle get title => _base.copyWith(
      fontSize: 21, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.5);
  static TextStyle get heading => _base.copyWith(
      fontSize: 16, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: -0.2);
  static TextStyle get bodyStrong =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);
  static TextStyle get body => _base.copyWith(
      fontSize: 14, fontWeight: FontWeight.w400, height: 1.55, color: AppColors.body);
  static TextStyle get small => _base.copyWith(
      fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4, color: AppColors.muted);
  static TextStyle get label => _base.copyWith(
      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.subtle);
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: 0.4);
  static TextStyle get number => _base.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      height: 1.1,
      fontFeatures: const [FontFeature.tabularFigures()]);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brand,
      onPrimary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    ).copyWith(surfaceTint: Colors.transparent),
    scaffoldBackgroundColor: AppColors.canvas,
  );

  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: AppText.heading,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: AppText.body.copyWith(color: AppColors.muted),
      hintStyle: AppText.body.copyWith(color: AppColors.subtle),
      prefixIconColor: AppColors.muted,
      suffixIconColor: AppColors.muted,
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.navy, 1.4),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.lineStrong,
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: AppText.bodyStrong.copyWith(fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.surface,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: AppText.bodyStrong.copyWith(fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        textStyle: AppText.bodyStrong,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.navy,
      side: BorderSide.none,
      labelStyle: AppText.small.copyWith(color: AppColors.body, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.lineStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md + 4)),
      titleTextStyle: AppText.heading.copyWith(fontSize: 18),
      contentTextStyle: AppText.body,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      contentTextStyle: AppText.body.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.ink,
      unselectedLabelColor: AppColors.muted,
      labelStyle: AppText.bodyStrong,
      unselectedLabelStyle: AppText.body.copyWith(fontWeight: FontWeight.w500),
      indicatorColor: AppColors.navy,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: AppColors.line,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.navy : AppColors.lineStrong),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
