import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Complete ThemeData definitions for light and dark modes.
class AppTheme {
  AppTheme._();

  // ──────────────────────── LIGHT THEME ────────────────────────
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'TTInterphasesPro',
        scaffoldBackgroundColor: ITMColors.lightBackground,
        colorScheme: ColorScheme.light(
          primary: ITMColors.gradientStart,
          secondary: ITMColors.gradientEnd,
          surface: ITMColors.lightSurface,
          error: ITMColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: ITMColors.lightTextPrimary,
          onError: Colors.white,
          outline: ITMColors.lightCardBorder,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: ITMColors.lightAppBar,
          foregroundColor: ITMColors.lightTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 2,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: ITMColors.lightCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ITMColors.lightCardBorder, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ITMColors.lightInputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ITMColors.lightInputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ITMColors.lightInputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: ITMColors.gradientStart, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ITMColors.gradientStart,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: ITMColors.lightDivider,
          thickness: 1,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: ITMColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: ITMColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ITMColors.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: ITMColors.gradientStart,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );

  // ──────────────────────── DARK THEME ────────────────────────
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'TTInterphasesPro',
        scaffoldBackgroundColor: ITMColors.darkBackground,
        colorScheme: ColorScheme.dark(
          primary: ITMColors.gradientEnd,
          secondary: ITMColors.gradientStart,
          surface: ITMColors.darkSurface,
          error: ITMColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: ITMColors.darkTextPrimary,
          onError: Colors.white,
          outline: ITMColors.darkCardBorder,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: ITMColors.darkAppBar,
          foregroundColor: ITMColors.darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 2,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: ITMColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ITMColors.darkCardBorder, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ITMColors.darkInputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ITMColors.darkInputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ITMColors.darkInputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: ITMColors.gradientEnd, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: ITMColors.darkTextTertiary),
          labelStyle: const TextStyle(color: ITMColors.darkTextSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ITMColors.gradientEnd,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: ITMColors.darkDivider,
          thickness: 1,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: ITMColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: ITMColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ITMColors.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          indicatorColor: ITMColors.gradientEnd,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: ITMColors.gradientEnd,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );
}
