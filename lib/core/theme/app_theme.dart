import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1A73E8);
  static const primaryDark = Color(0xFF1557B0);
  static const primaryLight = Color(0xFFE8F0FE);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);
  static const textOnPrimary = Colors.white;

  static const background = Color(0xFFF9FAFB);
  static const surface = Colors.white;
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFF3F4F6);

  static const shadow = Color(0x0D000000);

  // Commonly used blues across screens
  static const primaryBlue = Color(0xFF2563EB);
  static const primaryBlueLight = Color(0xFFEFF6FF);
  static const primaryBlueBorder = Color(0xFFBFDBFE);

  // Success greens used across booking/payment flows
  static const successGreen = Color(0xFF10B981);
  static const successGreenLight = Color(0xFFD1FAE5);
  static const successGreenBorder = Color(0xFFBBF7D0);

  // Error light variants
  static const errorLight = Color(0xFFFEF2F2);
  static const errorBorder = Color(0xFFFECACA);

  // Warning light variants
  static const warningLight = Color(0xFFFFFBEB);
  static const warningBorder = Color(0xFFFDE68A);
  static const warningText = Color(0xFF92400E);

  // Text variant used across screens
  static const textDark = Color(0xFF111827);
  static const textSoft = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  // Surface variants
  static const surfaceLight = Color(0xFFF8FAFC);
  static const surfaceSoft = Color(0xFFF0F7FF);
  static const surfaceGrey = Color(0xFFF1F5F9);

  // Misc
  static const darkSlate = Color(0xFF0F172A);
  static const warmGrey = Color(0xFFE2E8F0);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: AppColors.primary,
    textTheme: GoogleFonts.notoSansKhmerTextTheme(),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryLight,
      labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
  );
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets listPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  static SizedBox gapH(double h) => SizedBox(height: h);
  static SizedBox gapW(double w) => SizedBox(width: w);
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static BorderRadius circular(double r) => BorderRadius.circular(r);
  static BorderRadius get smR => circular(sm);
  static BorderRadius get mdR => circular(md);
  static BorderRadius get lgR => circular(lg);
  static BorderRadius get xlR => circular(xl);
}

class AppGradients {
  AppGradients._();

  static const primaryBlue = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkBlue = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  AppTextStyles._();

  static final cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.lgR,
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  );
}

// ─── Motion design tokens ─────────────────────────────────────

class AppAnimations {
  AppAnimations._();

  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration xslow = Duration(milliseconds: 700);

  // Curves
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;

  // Stagger helpers
  static Duration stagger(int index, {int ms = 60}) =>
      Duration(milliseconds: ms * index);
}

// ─── Shadow presets ───────────────────────────────────────────

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> glow(Color color, {double intensity = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: color.withValues(alpha: intensity * 0.4),
          blurRadius: 40,
          spreadRadius: 4,
          offset: const Offset(0, 12),
        ),
      ];
}

