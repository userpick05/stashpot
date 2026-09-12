import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/recipe_providers.dart';
import '../../core/utils/recipe_tags.dart';
import '../../l10n/app_localizations.dart';

/// Pick the tags for a recipe. Returns the chosen tags, or null if dismissed
/// without saving. A bottom sheet (not a dialog — Impeller black-screens
/// dialogs on some devices, e.g. the Pixel 10).
Future<List<String>?> showRecipeTagPicker(
  BuildContext context,
  WidgetRef ref, {
  required List<String> initial,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RecipeTagPickerSheet(initial: initial),
  );
}

class _RecipeTagPickerSheet extends ConsumerStatefulWidget {
  final List<String> initial;
  const _RecipeTagPickerSheet({required this.initial});

  @override
  ConsumerState<_RecipeTagPickerSheet> createState() =>
      _RecipeTagPickerSheetState();
}

class _RecipeTagPickerSheetState extends ConsumerState<_RecipeTagPickerSheet> {
  late final Set<String> _selected = {...widget.initial};
  final _newTagCtrl = TextEditingController();

  @override
  void dispose() {
    _newTagCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCustom() async {
    final l = AppLocalizations.of(context);
    final name = _newTagCtrl.text.trim();
    if (name.isEmpty) return;
    final lower = name.toLowerCase();
    final custom = ref.read(customRecipeTagsProvider).valueOrNull ?? const [];
    // Don't let a custom tag clash with a built-in (key or its localized label)
    // or an existing custom tag — that would split into look-alike groups.
    final clash = kRecipeTagKeys.any((k) => k == lower) ||
        kRecipeTagKeys.any((k) => recipeTagLabelOf(l, k).toLowerCase() == lower) ||
        custom.any((t) => t.toLowerCase() == lower);
    if (clash) {
      // Already exists — just select it rather than erroring.
      final existing = [...kRecipeTagKeys, ...custom].firstWhere(
        (t) => t.toLowerCase() == lower ||
            recipeTagLabelOf(l, t).toLowerCase() == lower,
        orElse: () => name,
      );
      setState(() {
        _selected.add(existing);
        _newTagCtrl.clear();
      });
      return;
    }
    final hid = ref.read(householdIdProvider);
    if (hid != null) {
      await ref.read(firestoreServiceProvider).addRecipeTag(hid, name);
    }
    setState(() {
      _selected.add(name);
      _newTagCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final custom = ref.watch(customRecipeTagsProvider).valueOrNull ?? const [];
    // Selected custom tags that Firestore hasn't echoed back yet still need a
    // chip, so union the stored customs with any selected non-built-ins.
    final customTags = <String>{
      ...custom,
      for (final t in _selected)
        if (!isBuiltInRecipeTag(t)) t,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    Widget chip(String tag) => FilterChip(
          label: Text(recipeTagLabelOf(l, tag)),
          selected: _selected.contains(tag),
          onSelected: (on) => setState(
              () => on ? _selected.add(tag) : _selected.remove(tag)),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.recipeTagsPickTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [for (final k in kRecipeTagKeys) chip(k)],
                  ),
                  if (customTags.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(l.recipeTagsYours,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [for (final t in customTags) chip(t)],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newTagCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l.recipeTagsAddHint,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addCustom(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                tooltip: l.recipeTagsAdd,
                onPressed: _addCustom,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _selected.toList()),
              child: Text(l.commonSave),
            ),
          ),
        ],
      ),
    );
  }
}
