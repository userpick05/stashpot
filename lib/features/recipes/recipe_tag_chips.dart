import 'package:flutter/material.dart';

import '../../core/utils/recipe_tags.dart';
import '../../l10n/app_localizations.dart';

/// Read-only row of a recipe's tags, shown on list cards and the detail screen.
class RecipeTagChips extends StatelessWidget {
  final List<String> tags;
  const RecipeTagChips({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final t in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              recipeTagLabelOf(l, t),
              style: TextStyle(fontSize: 11, color: scheme.onSecondaryContainer),
            ),
          ),
      ],
    );
  }
}
