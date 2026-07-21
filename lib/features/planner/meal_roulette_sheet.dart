import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/planner_providers.dart';
import '../../models/planned_meal.dart';
import 'planner_screen.dart' show mealTypeColor;

/// One proposed fill: a day + meal type, drawn from a past meal.
class _Pick {
  final DateTime day;
  final String type;
  final PlannedMeal source; // past meal we're copying (title/recipe/notes)
  const _Pick({required this.day, required this.type, required this.source});
}

/// "Meal roulette" — auto-fills the next N days with a random assortment drawn
/// from your PAST meals of each chosen type. Only fills EMPTY slots. You preview
/// the picks, re-roll if you don't like them, then add them all to the planner.
class MealRouletteSheet extends ConsumerStatefulWidget {
  const MealRouletteSheet({super.key});

  @override
  ConsumerState<MealRouletteSheet> createState() => _MealRouletteSheetState();
}

class _MealRouletteSheetState extends ConsumerState<MealRouletteSheet> {
  int _days = 5;
  final Set<String> _types = {'Dinner'};
  final _rng = Random();

  List<_Pick>? _preview; // null until first roll
  List<String> _emptyTypes = []; // chosen types with no history to draw from
  bool _saving = false;

  // Meal types the roulette offers (Snack excluded — plan was B/L/D).
  static const _offered = ['Breakfast', 'Lunch', 'Dinner'];

  /// Distinct past meals of [type] (deduped by title, case-insensitive).
  List<PlannedMeal> _poolFor(String type, List<PlannedMeal> all) {
    final seen = <String>{};
    final pool = <PlannedMeal>[];
    for (final m in all) {
      if (m.mealType != type) continue;
      final key = m.title.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      pool.add(m);
    }
    return pool;
  }

  void _roll() {
    final all = ref.read(plannerProvider).valueOrNull ?? [];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final picks = <_Pick>[];
    final empty = <String>[];

    for (final type in _offered.where(_types.contains)) {
      final pool = _poolFor(type, all);
      if (pool.isEmpty) {
        empty.add(type);
        continue;
      }
      final bag = [...pool]..shuffle(_rng);
      var idx = 0;
      for (var i = 0; i < _days; i++) {
        final day = start.add(Duration(days: i));
        // Only fill an EMPTY slot — never clobber a meal set on purpose.
        final occupied =
            all.any((m) => m.mealType == type && _sameDay(m.date, day));
        if (occupied) continue;
        if (idx >= bag.length) {
          bag.shuffle(_rng);
          idx = 0;
        }
        picks.add(_Pick(day: day, type: type, source: bag[idx++]));
      }
    }

    picks.sort((a, b) {
      final byDay = a.day.compareTo(b.day);
      if (byDay != 0) return byDay;
      return PlannedMeal.mealOrder
          .indexOf(a.type)
          .compareTo(PlannedMeal.mealOrder.indexOf(b.type));
    });
    setState(() {
      _preview = picks;
      _emptyTypes = empty;
    });
  }

  Future<void> _apply() async {
    final hid = ref.read(householdIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    final picks = _preview;
    if (hid == null || uid == null || picks == null || picks.isEmpty) return;

    setState(() => _saving = true);
    final fs = ref.read(firestoreServiceProvider);
    try {
      for (final p in picks) {
        await fs.savePlannedMeal(
          hid,
          PlannedMeal(
            id: '',
            date: p.day,
            title: p.source.title,
            mealType: p.type,
            recipeId: p.source.recipeId,
            notes: p.source.notes,
            addedAt: DateTime.now(),
            addedBy: uid,
          ),
        );
      }
      if (mounted) Navigator.pop(context, picks.length);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(day.year, day.month, day.day).difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(day);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.casino),
                  const SizedBox(width: 8),
                  Text('Meal roulette',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Auto-fill empty days with a random pick from meals you have planned before.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 16),

              // How many days
              Row(
                children: [
                  const Text('Fill the next'),
                  const Spacer(),
                  IconButton.outlined(
                    onPressed: _days > 1
                        ? () => setState(() {
                              _days--;
                              _preview = null; // count changed — re-roll needed
                            })
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$_days',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  IconButton.outlined(
                    onPressed: _days < 14
                        ? () => setState(() {
                              _days++;
                              _preview = null; // count changed — re-roll needed
                            })
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 6),
                  Text(_days == 1 ? 'day' : 'days'),
                ],
              ),
              const SizedBox(height: 12),

              // Which meals
              const Text('Fill which meals?'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final type in _offered)
                    FilterChip(
                      label: Text(type),
                      selected: _types.contains(type),
                      onSelected: (on) => setState(() {
                        if (on) {
                          _types.add(type);
                        } else {
                          _types.remove(type);
                        }
                        _preview = null; // selection changed — re-roll needed
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Preview
              if (preview != null) ...[
                const Divider(),
                if (_emptyTypes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No ${_emptyTypes.join(' or ')} meals in your planner yet — plan a few first so the roulette has something to draw from.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                // A chosen type had history but every target slot was already full.
                if (preview.isEmpty &&
                    _types.any((t) => !_emptyTypes.contains(t)))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Those days are already planned for the meals you picked — nothing to fill.',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                if (preview.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${preview.length} to add',
                        style: Theme.of(context).textTheme.labelLarge),
                  ),
                  for (final p in preview)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            mealTypeColor(p.type).withValues(alpha: 0.18),
                        child: Icon(Icons.restaurant_menu,
                            size: 14, color: mealTypeColor(p.type)),
                      ),
                      title: Text(p.source.title),
                      subtitle: Text('${_dayLabel(p.day)} · ${p.type}'),
                    ),
                ],
                const SizedBox(height: 8),
              ],

              // Actions
              if (preview == null)
                FilledButton.icon(
                  onPressed: _types.isEmpty ? null : _roll,
                  icon: const Icon(Icons.casino),
                  label: const Text('Roll'),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _roll,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Re-roll'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (_saving || preview.isEmpty) ? null : _apply,
                        icon: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.playlist_add_check),
                        label: const Text('Add to planner'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
