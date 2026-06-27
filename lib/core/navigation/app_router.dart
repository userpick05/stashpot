import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/join_household_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/inventory/add_item_screen.dart';
import '../../models/inventory_item.dart';
import '../../features/shopping/shopping_screen.dart';
import '../../features/recipes/recipes_screen.dart';
import '../../features/recipes/find_recipes_screen.dart';
import '../../features/planner/planner_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Refresh the router whenever auth OR the user's Firestore doc changes,
  // so setting a householdId (e.g. after creating one) re-runs the redirect.
  final notifier = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => notifier.value++);
  ref.listen(appUserProvider, (_, __) => notifier.value++);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final appUserState = ref.read(appUserProvider);
      final loc = state.matchedLocation;

      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = loc == '/login' || loc == '/register';
      final isSetupRoute = loc == '/join';

      // Not signed in → only auth routes allowed.
      if (!isLoggedIn) return isAuthRoute ? null : '/login';

      // Signed in but the user doc is still loading → wait, don't bounce.
      if (appUserState.isLoading) return null;

      final hasHousehold = appUserState.valueOrNull?.householdId != null;

      if (isAuthRoute) return hasHousehold ? '/home' : '/join';
      if (hasHousehold && isSetupRoute) return '/home';
      if (!hasHousehold && !isSetupRoute) return '/join';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/join', builder: (_, __) => const JoinHouseholdScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (_, __) => const InventoryScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, state) =>
                    AddItemScreen(autoStart: state.extra as String?),
              ),
              GoRoute(
                path: 'edit',
                builder: (_, state) =>
                    AddItemScreen(existing: state.extra as InventoryItem?),
              ),
            ],
          ),
          GoRoute(
            path: '/shopping',
            builder: (_, __) => const ShoppingScreen(),
          ),
          GoRoute(
            path: '/recipes',
            builder: (_, __) => const RecipesScreen(),
            routes: [
              GoRoute(path: 'find', builder: (_, __) => const FindRecipesScreen()),
            ],
          ),
          GoRoute(
            path: '/planner',
            builder: (_, __) => const PlannerScreen(),
          ),
        ],
      ),
    ],
    initialLocation: '/login',
  );
});
