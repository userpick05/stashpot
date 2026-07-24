import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/planner_providers.dart';
import '../../core/providers/recipe_providers.dart';
import '../../core/update/update_service.dart';
import '../../core/update/update_sheet.dart';
import '../../core/utils/shopping_actions.dart';
import '../../core/widgets/invite_code_sheet.dart';
import '../../models/planned_meal.dart';
import '../recipes/recipe_detail_screen.dart';
import 'running_low_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check for an OTA update once when the home screen first appears.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (info != null && mounted) showUpdateSheet(context, info);
  }

  // Open the "running low?" picker, then add the chosen item (or free-text
  // name, if nothing in the pantry matched) to the shopping list AFTER the
  // sheet has fully closed (so the snackbar isn't shown mid route-transition,
  // which would leave it stuck on screen). Checks for a shopping-list
  // duplicate first and asks whether to skip or add anyway.
  Future<void> _openRunningLow() async {
    final pick = await showRunningLowSheet(context);
    if (pick == null || !mounted) return;
    if (pick.item != null) {
      await sendItemToShopping(context, ref, pick.item!, confirmIfDuplicate: true);
    } else if (pick.newName != null) {
      await addNameToShopping(context, ref, pick.newName!, confirmIfDuplicate: true);
    }
  }

  String _greeting(AppLocalizations l) {
    final h = DateTime.now().hour;
    if (h < 12) return l.homeGreetingMorning;
    if (h < 17) return l.homeGreetingAfternoon;
    return l.homeGreetingEvening;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final name = ref.watch(appUserProvider).valueOrNull?.displayName.split(' ').first;
    final pantry = ref.watch(inventoryProvider).valueOrNull ?? [];
    final expiring = ref.watch(expiringItemsProvider);
    final shopping = ref.watch(shoppingProvider).valueOrNull ?? [];
    final recipes = ref.watch(recipesProvider).valueOrNull ?? [];
    final meals = ref.watch(plannerProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.kitchen, color: scheme.primary, size: 26),
            const SizedBox(width: 8),
            Text(l.appTitle,
                style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: l.settingsInviteFriends,
            onPressed: () {
              final code = ref.read(householdIdProvider);
              if (code != null) showInviteCodeSheet(context, code);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l.settingsTitle,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ── Greeting ──────────────────────────────────────────────
            Text(
                name == null
                    ? _greeting(l)
                    : l.homeGreetingNamed(_greeting(l), name),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // ── Stat tiles ────────────────────────────────────────────
            Row(
              children: [
                _StatTile(
                  label: l.navPantry,
                  value: '${pantry.length}',
                  icon: Icons.kitchen,
                  color: scheme.primary,
                  onTap: () => context.go('/inventory'),
                ),
                const SizedBox(width: 10),
                _StatTile(
                  label: l.navShopping,
                  value: '${shopping.length}',
                  icon: Icons.shopping_cart,
                  color: Colors.teal,
                  onTap: () => context.go('/shopping'),
                ),
                const SizedBox(width: 10),
                _StatTile(
                  label: l.homeStatExpiring,
                  value: '${expiring.length}',
                  icon: Icons.warning_amber,
                  color: expiring.isEmpty ? Colors.grey : Colors.orange,
                  onTap: () => context.go('/inventory'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Running low? ──────────────────────────────────────────
            Card(
              margin: EdgeInsets.zero,
              color: scheme.secondaryContainer,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openRunningLow,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.remove_shopping_cart,
                          color: scheme.onSecondaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.homeRunningLow,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onSecondaryContainer)),
                            Text(l.homeRunningLowSubtitle,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSecondaryContainer)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: scheme.onSecondaryContainer),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── What's for dinner ─────────────────────────────────────
            _SectionCard(
              title: l.homeWhatsForDinner,
              trailing: TextButton(
                onPressed: () => context.go('/planner'),
                child: Text(l.navPlanner),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++)
                    _DinnerRow(
                      day: DateTime.now().add(Duration(days: i)),
                      meals: meals,
                      sameDay: _sameDay,
                      isLast: i == 2,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Recipe of the day ─────────────────────────────────────
            if (recipes.isNotEmpty) ...[
              Builder(builder: (context) {
                final dayOfYear =
                    DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
                final pick = recipes[dayOfYear % recipes.length];
                return _SectionCard(
                  title: l.homeRecipeOfTheDay,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: pick.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(pick.imageUrl!,
                                width: 56, height: 56, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.restaurant, size: 40)),
                          )
                        : const Icon(Icons.restaurant, size: 40),
                    title: Text(pick.name,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(recipe: pick)),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // ── Quick actions ─────────────────────────────────────────
            Text(l.homeQuickActions,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickAction(
                  icon: Icons.travel_explore,
                  label: l.homeFindRecipes,
                  onTap: () => context.push('/recipes/find'),
                ),
                _QuickAction(
                  icon: Icons.calendar_today,
                  label: l.homePlanAMeal,
                  onTap: () => context.go('/planner'),
                ),
                _QuickAction(
                  icon: Icons.shopping_cart,
                  label: l.homeShoppingList,
                  onTap: () => context.go('/shopping'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Add to pantry ─────────────────────────────────────────
            Text(l.homeAddToPantry,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AddAction(
                      icon: Icons.edit_note,
                      label: l.homeAddItem,
                      onTap: () => context.push('/inventory/add'),
                    ),
                    _AddAction(
                      icon: Icons.qr_code_scanner,
                      label: l.homeScan,
                      onTap: () => context.push('/inventory/add', extra: 'scan'),
                    ),
                    _AddAction(
                      icon: Icons.camera_alt,
                      label: l.homePhoto,
                      onTap: () => context.push('/inventory/add', extra: 'photo'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20)),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _DinnerRow extends StatelessWidget {
  final DateTime day;
  final List<PlannedMeal> meals;
  final bool Function(DateTime, DateTime) sameDay;
  final bool isLast;
  const _DinnerRow({
    required this.day,
    required this.meals,
    required this.sameDay,
    required this.isLast,
  });

  String _label(AppLocalizations l) {
    final now = DateTime.now();
    final diff = DateTime(day.year, day.month, day.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (diff == 0) return l.homeToday;
    if (diff == 1) return l.homeTomorrow;
    // Short weekday name from the active locale rather than a hardcoded
    // English array. Chinese is served as generic 'zh', so nudge the date
    // symbols to zh_TW for Traditional forms (falls back to 'zh' if absent).
    final dateLocale =
        l.localeName.startsWith('zh') ? 'zh_TW' : l.localeName;
    return DateFormat.E(dateLocale).format(day);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dinners = meals
        .where((m) => sameDay(m.date, day) && m.mealType == 'Dinner')
        .map((m) => m.title)
        .toList();
    final text = dinners.isEmpty ? l.homeNothingPlanned : dinners.join(', ');
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(_label(l),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(text,
                style: dinners.isEmpty
                    ? TextStyle(color: Theme.of(context).colorScheme.outline)
                    : null),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _AddAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AddAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.primaryContainer,
              child: Icon(icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
