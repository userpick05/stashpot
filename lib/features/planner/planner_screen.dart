import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/planner_providers.dart';
import '../../core/providers/recipe_providers.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../models/planned_meal.dart';
import '../recipes/recipe_detail_screen.dart';
import 'add_meal_sheet.dart';

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
    final now = DateTime.now();
    final d = DateTime(day.year, day.month, day.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(day);
  }

  Future<void> _openRecipe(String recipeId) async {
    // Await the first value so we don't falsely say "not saved" while loading.
    final recipes = await ref.read(recipesProvider.future);
    if (!mounted) return;
    final match = recipes.where((r) => r.id == recipeId).toList();
    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That recipe is no longer saved')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: match.first)),
    );
  }

  void _editMeal(PlannedMeal meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddMealSheet(date: meal.date, existing: meal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planner = ref.watch(plannerProvider);
    final meals = planner.valueOrNull ?? [];
    List<PlannedMeal> forDay(DateTime day) =>
        meals.where((m) => isSameDay(m.date, day)).toList()
          ..sort((a, b) => a.mealRank.compareTo(b.mealRank));
    final selectedMeals = forDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('Meal planner')),
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
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                      CalendarFormat.twoWeeks: '2 weeks',
                      CalendarFormat.week: 'Week',
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
                            Text(t, style: Theme.of(context).textTheme.bodySmall),
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
                        label: const Text('Add meal'),
                      ),
                    ],
                  ),
                ),

                if (selectedMeals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text('Nothing planned for this day',
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
                            m.notes != null && m.notes!.isNotEmpty
                                ? '${m.mealType} · ${m.notes}'
                                : m.mealType,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Tap the row to edit; tap the recipe button to open it.
                          onTap: () => _editMeal(m),
                          trailing: m.recipeId != null
                              ? IconButton(
                                  icon: const Icon(Icons.menu_book),
                                  tooltip: 'Open recipe',
                                  onPressed: () => _openRecipe(m.recipeId!),
                                )
                              : const Icon(Icons.edit, size: 18),
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
