import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    (path: '/home', icon: Icons.home, label: 'Home'),
    (path: '/inventory', icon: Icons.kitchen, label: 'Pantry'),
    (path: '/shopping', icon: Icons.shopping_cart, label: 'Shopping'),
    (path: '/recipes', icon: Icons.restaurant_menu, label: 'Recipes'),
    (path: '/planner', icon: Icons.calendar_today, label: 'Planner'),
  ];

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}
