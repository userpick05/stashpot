import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/planner_providers.dart';
import '../../core/providers/recipe_providers.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../l10n/app_localizations.dart';
import '../../models/planned_meal.dart';
import '../recipes/recipe_detail_screen.dart';
import 'add_meal_sheet.dart';
import 'meal_roulette_sheet.dart';
import 'move_meal_sheet.dart';

/// Color for each meal type's calendar dot + legend.
Color mealTypeColor(String type) => switch (type) {
      'Breakfast' => Colors.orange,
      'Lunch' => Colors.green,
      'Dinner' => Colors.indigo,
      _ => Colors.purple, // Snack
    };

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  String _dayLabel(DateTime day) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final d = DateTime(day.year, day.month, day.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return l.plannerToday;
    if (diff == 1) return l.plannerTomorrow;
    if (diff == -1) return l.plannerYesterday;
    // Locale-aware "Wednesday, 23 July" / "7月23日星期三".
    return DateFormat.MMMMEEEEd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(day);
  }

  Future<void> _openRecipe(String recipeId) async {
    // Await the first value so we don't falsely say "not saved" while loading.
    final recipes = await ref.read(recipesProvider.future);
    if (!mounted) return;
    final match = recipes.where((r) => r.id == recipeId).toList();
    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).plannerRecipeGone)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: match.first)),
    );
  }

  /// Show a snackbar safely on this device: on the next frame (not mid
  /// route-change/rebuild) with an explicit backstop timer, so it can't skip
  /// the callback that arms auto-dismiss and stick forever (see shopping_actions).
  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger.hideCurrentSnackBar();
      final controller = messenger.showSnackBar(
        SnackBar(duration: const Duration(seconds: 4), content: Text(message)),
      );
      Future.delayed(
          const Duration(seconds: 4, milliseconds: 300), controller.close);
    });
  }

  void _editMeal(PlannedMeal meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddMealSheet(date: meal.date, existing: meal),
    );
  }

  /// Move a meal to another day. If the destination already has a meal of the
  /// same type, the two swap places instead of one overwriting the other.
  Future<void> _moveMeal(PlannedMeal meal) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MoveMealSheet(meal: meal),
    );
    if (picked == null || !mounted) return;
    final target = DateTime(picked.year, picked.month, picked.day);
    final origin = DateTime(meal.date.year, meal.date.month, meal.date.day);
    if (isSameDay(target, origin)) return; // no change

    final hid = ref.read(householdIdProvider);
    if (hid == null) return;
    final fs = ref.read(firestoreServiceProvider);
    final all = ref.read(plannerProvider).valueOrNull ?? [];

    // An existing meal of the same type on the target day gets swapped back.
    final occupant = all
        .where((m) =>
            m.id != meal.id &&
            m.mealType == meal.mealType &&
            isSameDay(m.date, target))
        .toList();

    await fs.savePlannedMeal(hid, meal.copyWith(date: target));
    if (occupant.isNotEmpty) {
      await fs.savePlannedMeal(hid, occupant.first.copyWith(date: origin));
    }

    if (!mounted) return;
    final l = AppLocalizations.of(context);
    setState(() => _selectedDay = target); // follow the meal to its new day
    _showSnack(occupant.isNotEmpty
        ? l.plannerSwapped(meal.title, occupant.first.title)
        : l.plannerMoved(meal.title, _dayLabel(target)));
  }

  Future<void> _openRoulette() async {
    final added = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const MealRouletteSheet(),
    );
    if (added != null && added > 0 && mounted) {
      _showSnack(AppLocalizations.of(context).plannerAddedMeals(added));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final planner = ref.watch(plannerProvider);
    final meals = planner.valueOrNull ?? [];
    List<PlannedMeal> forDay(DateTime day) =>
        meals.where((m) => isSameDay(m.date, day)).toList()
          ..sort((a, b) => a.mealRank.compareTo(b.mealRank));
    final selectedMeals = forDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.plannerTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.casino),
            tooltip: l.rouletteTooltip,
            onPressed: _openRoulette,
          ),
        ],
      ),
      body: planner.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Card(
                  margin: const EdgeInsets.all(8),
                  child: TableCalendar<PlannedMeal>(
                    firstDay: DateTime.utc(2022, 1, 1),
                    lastDay: DateTime.utc(2032, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _format,
                    locale: localeTag,
                    availableCalendarFormats: {
                      CalendarFormat.month: l.plannerFormatMonth,
                      CalendarFormat.twoWeeks: l.plannerFormatTwoWeeks,
                      CalendarFormat.week: l.plannerFormatWeek,
                    },
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: forDay,
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    onDaySelected: (selected, focused) => setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    }),
                    onFormatChanged: (f) => setState(() => _format = f),
                    onPageChanged: (focused) => _focusedDay = focused,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders<PlannedMeal>(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        // One dot per distinct meal type planned that day.
                        final types = <String>{for (final m in events) m.mealType};
                        final ordered = PlannedMeal.mealOrder
                            .where(types.contains)
                            .toList();
                        return Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final t in ordered)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                  decoration: BoxDecoration(
                                    color: mealTypeColor(t),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Legend
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      for (final t in PlannedMeal.mealOrder)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: mealTypeColor(t), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Text(mealTypeLabelOf(l, t),
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Selected day's meals
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      Text(_dayLabel(_selectedDay),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.primary)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => AddMealSheet(date: _selectedDay),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l.plannerAddMeal),
                      ),
                    ],
                  ),
                ),

                if (selectedMeals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(l.plannerNothingPlanned,
                        style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  )
                else
                  for (final m in selectedMeals)
                    SwipeToDelete(
                      key: ValueKey(m.id),
                      itemId: m.id,
                      label: m.title,
                      onDelete: () async {
                        final hid = ref.read(householdIdProvider);
                        if (hid != null) {
                          await ref
                              .read(firestoreServiceProvider)
                              .deletePlannedMeal(hid, m.id);
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: mealTypeColor(m.mealType).withValues(alpha: 0.18),
                            child: Icon(_mealIcon(m.mealType),
                                size: 20, color: mealTypeColor(m.mealType)),
                          ),
                          title: Text(m.title),
                          subtitle: Text(
                            // Display only — m.mealType stays the stored
                            // English key ('Breakfast'/'Lunch'/…).
                            m.notes != null && m.notes!.isNotEmpty
                                ? '${mealTypeLabelOf(l, m.mealType)} · ${m.notes}'
                                : mealTypeLabelOf(l, m.mealType),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Tap the row to edit; the buttons move / open recipe.
                          onTap: () => _editMeal(m),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.event_repeat),
                                tooltip: l.plannerMoveTooltip,
                                onPressed: () => _moveMeal(m),
                              ),
                              if (m.recipeId != null)
                                IconButton(
                                  icon: const Icon(Icons.menu_book),
                                  tooltip: l.plannerOpenRecipeTooltip,
                                  onPressed: () => _openRecipe(m.recipeId!),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
    );
  }

  IconData _mealIcon(String type) => switch (type) {
        'Breakfast' => Icons.free_breakfast,
        'Lunch' => Icons.lunch_dining,
        'Dinner' => Icons.dinner_dining,
        _ => Icons.bakery_dining,
      };
}
