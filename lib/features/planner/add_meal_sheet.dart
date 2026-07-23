import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/recipe_providers.dart';
import '../../core/utils/labels.dart';
import '../../l10n/app_localizations.dart';
import '../../models/planned_meal.dart';

/// Bottom sheet to plan a meal for a given day, or edit an existing one —
/// type a name or pick a saved recipe, with optional notes.
class AddMealSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final PlannedMeal? existing;
  const AddMealSheet({super.key, required this.date, this.existing});

  @override
  ConsumerState<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends ConsumerState<AddMealSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  // STORED value — never localized, only displayed via mealTypeLabelOf().
  String _mealType = 'Dinner';
  String? _recipeId;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _notesCtrl.text = e.notes ?? '';
      _mealType = e.mealType;
      _recipeId = e.recipeId;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRecipe() async {
    // Await the stream's first value so we don't falsely report "no recipes"
    // while they're still loading.
    final recipes = await ref.read(recipesProvider.future);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    if (recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.mealNoSavedRecipes)),
      );
      return;
    }
    final picked = await showModalBottomSheet<({String id, String name})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(l.mealPickRecipe,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final r in recipes)
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: Text(r.name),
                onTap: () => Navigator.pop(ctx, (id: r.id, name: r.name)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _titleCtrl.text = picked.name;
        _recipeId = picked.id;
      });
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).mealEnterOrPick)),
      );
      return;
    }
    final hid = ref.read(householdIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (hid == null || uid == null) return;

    setState(() => _saving = true);
    try {
      final e = widget.existing;
      await ref.read(firestoreServiceProvider).savePlannedMeal(
            hid,
            PlannedMeal(
              id: e?.id ?? '',
              date: e?.date ?? widget.date,
              title: title,
              mealType: _mealType,
              recipeId: _recipeId,
              notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              addedAt: e?.addedAt ?? DateTime.now(),
              addedBy: e?.addedBy ?? uid,
            ),
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_isEditing ? l.mealEditTitle : l.mealPlanTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              // `type` stays the stored English key; only the chip label is
              // localized.
              for (final type in PlannedMeal.mealOrder)
                ChoiceChip(
                  label: Text(mealTypeLabelOf(l, type)),
                  selected: _mealType == type,
                  onSelected: (_) => setState(() => _mealType = type),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_recipeId != null) setState(() => _recipeId = null); // typed over a picked recipe
            },
            decoration: InputDecoration(
              labelText: l.mealFieldLabel,
              hintText: l.mealFieldHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickRecipe,
            icon: const Icon(Icons.menu_book),
            label: Text(l.mealChooseSavedRecipe),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.mealNotesLabel,
              hintText: l.mealNotesHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEditing ? l.mealSaveChanges : l.mealAddToPlan),
          ),
        ],
      ),
    );
  }
}
