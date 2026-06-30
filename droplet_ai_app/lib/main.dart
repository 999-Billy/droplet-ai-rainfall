import 'package:flutter/material.dart';
import 'theme/app_themes.dart';
import 'screens/main_nav_screen.dart';

void main() {
  runApp(const DropletAIApp());
}

class DropletAIApp extends StatelessWidget {
  const DropletAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeOption>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          title: 'Droplet AI',
          debugShowCheckedModeBanner: false,
          theme: appThemes[currentTheme]!.themeData,
          home: const MainNavScreen(),
        );
      },
    );
  }
}
