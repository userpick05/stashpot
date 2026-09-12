import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/shopping/add_shopping_item_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../../models/shopping_item.dart';
import '../providers/inventory_providers.dart';
import '../widget/quick_add_widget.dart';

class MainShell extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  StreamSubscription<Uri?>? _widgetSub;
  bool _openingQuickAdd = false;

  @override
  void initState() {
    super.initState();
    // The shell only mounts once the user is signed in with a household, so by
    // now the app is ready to act on a home-screen widget tap.
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) _handleQuickAdd();
    });
    _widgetSub = HomeWidget.widgetClicked.listen((_) => _handleQuickAdd());
  }

  @override
  void dispose() {
    _widgetSub?.cancel();
    super.dispose();
  }

  // Tapping the widget opens the shopping tab with the add sheet. The sheet is
  // self-contained, so we show it straight from the shell rather than depending
  // on the shopping screen being mounted and listening.
  Future<void> _handleQuickAdd() async {
    if (_openingQuickAdd || !mounted) return;
    _openingQuickAdd = true;
    if (GoRouterState.of(context).matchedLocation != '/shopping') {
      context.go('/shopping');
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      _openingQuickAdd = false;
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AddShoppingItemSheet(),
    );
    _openingQuickAdd = false;
  }

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = MainShell._tabs.indexWhere((t) => loc.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // Keep the home-screen widget's "to buy" count in step with the list, in
    // the app's current language.
    ref.listen<AsyncValue<List<ShoppingItem>>>(shoppingProvider, (_, next) {
      final items = next.valueOrNull;
      if (items != null) {
        QuickAddWidget.setText(
          countText: l.widgetItemsToBuy(items.where((i) => !i.checked).length),
          addLabel: l.widgetAddToShopping,
        );
      }
    });

    final selected = _selectedIndex(context);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(MainShell._tabs[i].path),
        destinations: [
          for (final t in MainShell._tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              label: MainShell._labelFor(l, t.path),
            ),
        ],
      ),
    );
  }
}
