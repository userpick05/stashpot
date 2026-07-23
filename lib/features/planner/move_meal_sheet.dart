import 'package:flutter/material.dart';
import '../../core/utils/labels.dart';
import '../../l10n/app_localizations.dart';
import '../../models/planned_meal.dart';

/// Bottom sheet that lets you pick a new day for a planned meal. Returns the
/// chosen day (local midnight) via Navigator.pop, or null if cancelled.
/// Uses an inline CalendarDatePicker (not a dialog) to stay clear of the
/// AlertDialog/Impeller black-screen issue on this device.
class MoveMealSheet extends StatefulWidget {
  final PlannedMeal meal;
  const MoveMealSheet({super.key, required this.meal});

  @override
  State<MoveMealSheet> createState() => _MoveMealSheetState();
}

class _MoveMealSheetState extends State<MoveMealSheet> {
  late DateTime _selected = DateTime(
    widget.meal.date.year,
    widget.meal.date.month,
    widget.meal.date.day,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              l.mealMoveTitle(widget.meal.title),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              // The stored English key is only ever displayed through
              // mealTypeLabelOf — never interpolated raw.
              l.mealMoveSwapHint(mealTypeLabelOf(l, widget.meal.mealType)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            CalendarDatePicker(
              initialDate: _selected,
              firstDate: DateTime.utc(2022, 1, 1),
              lastDate: DateTime.utc(2032, 12, 31),
              onDateChanged: (d) => setState(() => _selected = d),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, _selected),
              icon: const Icon(Icons.event_available),
              label: Text(l.mealMoveConfirm),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
