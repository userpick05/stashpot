import 'package:flutter/material.dart';

import '../../core/utils/category_icons.dart';
import '../../core/utils/labels.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';

/// A food-type dropdown shared by the pantry and shopping editors. Offers the
/// built-in categories, any user-defined food types for the household, and an
/// "Add food type…" entry. Values are opaque string KEYS (an enum name, a
/// `custom:<name>` marker, or the add sentinel) so built-ins and custom types
/// can live in one `DropdownButtonFormField<String>`.
class FoodTypeField extends StatelessWidget {
  final ItemCategory category;
  final String? customCategory;
  final List<String> customTypes; // household's user-defined types
  final ValueChanged<ItemCategory> onBuiltin;
  final ValueChanged<String> onCustom;
  final VoidCallback onAddNew;

  const FoodTypeField({
    super.key,
    required this.category,
    required this.customCategory,
    required this.customTypes,
    required this.onBuiltin,
    required this.onCustom,
    required this.onAddNew,
  });

  static const _addSentinel = '__add_food_type__';
  static String _customKey(String name) => 'custom:$name';

  String get _value => (customCategory != null && customCategory!.isNotEmpty)
      ? _customKey(customCategory!)
      : category.name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Offer built-ins (plus the item's own legacy category if it isn't in the
    // pickable set), then the household's custom types, then "add".
    final builtins = kPickableCategories.contains(category)
        ? kPickableCategories
        : [...kPickableCategories, category];
    // Case-insensitive dedup, keeping the FIRST spelling. The item's own custom
    // value goes first so its exact casing is the one rendered — guaranteeing
    // [_value] matches exactly one menu item (else the dropdown asserts).
    final customs = <String>[];
    final seenLower = <String>{};
    for (final name in [
      if (customCategory != null && customCategory!.isNotEmpty) customCategory!,
      ...customTypes,
    ]) {
      final key = name.trim().toLowerCase();
      if (key.isEmpty || !seenLower.add(key)) continue;
      customs.add(name.trim());
    }

    return DropdownButtonFormField<String>(
      initialValue: _value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l.addItemFoodTypeLabel,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final c in builtins)
          DropdownMenuItem(
            value: c.name,
            child: Row(children: [
              Icon(categoryIcon(c), size: 18),
              const SizedBox(width: 8),
              Text(categoryLabelOf(l, c)),
            ]),
          ),
        for (final name in customs)
          DropdownMenuItem(
            value: _customKey(name),
            child: Row(children: [
              const Icon(Icons.sell_outlined, size: 18),
              const SizedBox(width: 8),
              Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        DropdownMenuItem(
          value: _addSentinel,
          child: Row(children: [
            const Icon(Icons.add, size: 18),
            const SizedBox(width: 8),
            Text(l.addItemAddFoodType),
          ]),
        ),
      ],
      onChanged: (v) {
        if (v == null) return;
        if (v == _addSentinel) {
          onAddNew();
        } else if (v.startsWith('custom:')) {
          onCustom(v.substring('custom:'.length));
        } else {
          final c = ItemCategory.values.firstWhere((e) => e.name == v,
              orElse: () => ItemCategory.other);
          onBuiltin(c);
        }
      },
    );
  }
}

/// Prompt for a new food-type name. Returns the trimmed name, or null if the
/// user cancelled or it collides with a built-in category's key.
/// A bottom sheet, not a dialog (Impeller black-screens dialogs on this HW).
Future<String?> promptNewFoodType(
  BuildContext context, {
  List<String> existing = const [],
}) async {
  final l = AppLocalizations.of(context);
  final ctrl = TextEditingController();
  final name = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.addItemNewFoodTypeTitle,
              style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: l.addItemNewFoodTypeHint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(l.commonAdd),
            ),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  // Don't shadow a built-in enum name (collides with the dropdown's keys) or a
  // built-in's display label (would look like a duplicate group).
  if (ItemCategory.values.any((c) => c.name.toLowerCase() == lower) ||
      kPickableCategories.any(
          (c) => categoryLabelOf(l, c).toLowerCase() == lower)) {
    return null;
  }
  // Reuse an existing custom type that differs only by case, so we never create
  // "Pet" and "pet" as two types.
  for (final e in existing) {
    if (e.trim().toLowerCase() == lower) return e.trim();
  }
  return trimmed;
}
