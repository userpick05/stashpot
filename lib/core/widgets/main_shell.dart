import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  // Paths + icons are fixed; labels come from the active locale at build time.
  static const _tabs = [
    (path: '/home', icon: Icons.home),
    (path: '/inventory', icon: Icons.kitchen),
    (path: '/shopping', icon: Icons.shopping_cart),
    (path: '/recipes', icon: Icons.restaurant_menu),
    (path: '/planner', icon: Icons.calendar_today),
  ];

  static String _labelFor(AppLocalizations l, String path) => switch (path) {
        '/home' => l.navHome,
        '/inventory' => l.navPantry,
        '/shopping' => l.navShopping,
        '/recipes' => l.navRecipes,
        _ => l.navPlanner,
      };

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final selected = _selectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              label: _labelFor(l, t.path),
            ),
        ],
      ),
    );
  }
}
