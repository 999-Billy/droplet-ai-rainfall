import 'package:flutter/material.dart';

// The 5 selectable themes, as agreed
enum AppThemeOption {
  midnightNavy,
  oceanBlue,
  forestGreen,
  slateDark,
  sunriseAmber,
}

// A global, app-wide notifier — any widget can read the current theme
// or change it. ValueNotifier is built into Flutter, no extra package needed.
final ValueNotifier<AppThemeOption> themeNotifier = ValueNotifier(
  AppThemeOption.midnightNavy,
);

class AppThemeInfo {
  final String displayName;
  final ThemeData themeData;

  AppThemeInfo({required this.displayName, required this.themeData});
}

final Map<AppThemeOption, AppThemeInfo> appThemes = {
  AppThemeOption.midnightNavy: AppThemeInfo(
    displayName: "Midnight Navy",
    themeData: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1426),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E5C8A),
        brightness: Brightness.dark,
        surface: const Color(0xFF142136),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF142136),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B1426),
        elevation: 0,
      ),
      useMaterial3: true,
    ),
  ),
  AppThemeOption.oceanBlue: AppThemeInfo(
    displayName: "Ocean Blue",
    themeData: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFEFF6FC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1565C0),
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFEFF6FC),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      useMaterial3: true,
    ),
  ),
  AppThemeOption.forestGreen: AppThemeInfo(
    displayName: "Forest Green",
    themeData: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF1F8F0),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF1F8F0),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      useMaterial3: true,
    ),
  ),
  AppThemeOption.slateDark: AppThemeInfo(
    displayName: "Slate Dark",
    themeData: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1C1E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF607D8B),
        brightness: Brightness.dark,
        surface: const Color(0xFF26282B),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF26282B),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1C1E),
        elevation: 0,
      ),
      useMaterial3: true,
    ),
  ),
  AppThemeOption.sunriseAmber: AppThemeInfo(
    displayName: "Sunrise Amber",
    themeData: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFF8EE),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE6912C),
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFF8EE),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      useMaterial3: true,
    ),
  ),
};
