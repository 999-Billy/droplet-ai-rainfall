import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'home_screen.dart';
import 'predict_screen.dart';
import 'compare_screen.dart';
import 'about_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PredictScreen(),
    CompareScreen(),
    AboutScreen(),
  ];

  final List<String> _titles = const [
    "Droplet AI",
    "Predict",
    "Compare",
    "About",
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_titles[_selectedIndex]),
        actions: [
          PopupMenuButton<AppThemeOption>(
            icon: Icon(
              Icons.palette_outlined,
              color: theme.colorScheme.primary,
            ),
            tooltip: "Change theme",
            onSelected: (selected) {
              themeNotifier.value = selected;
            },
            itemBuilder: (context) {
              return appThemes.entries.map((entry) {
                final isSelected = entry.key == themeNotifier.value;
                return PopupMenuItem<AppThemeOption>(
                  value: entry.key,
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 18,
                          color: theme.colorScheme.primary,
                        )
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(entry.value.displayName),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _screens[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Predict',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Compare',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
