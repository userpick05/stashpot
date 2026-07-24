import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/recipe.dart';

/// Write your own recipe (name, ingredients, steps). Stored directly on the
/// recipe doc — no web source.
class AddRecipeManualScreen extends ConsumerStatefulWidget {
  final Recipe? existing; // edit a manual recipe
  const AddRecipeManualScreen({super.key, this.existing});

  @override
  ConsumerState<AddRecipeManualScreen> createState() =>
      _AddRecipeManualScreenState();
}

class _AddRecipeManualScreenState extends ConsumerState<AddRecipeManualScreen> {
  final _nameCtrl = TextEditingController();
  final _servingsCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _stepsCtrl = TextEditingController();
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _servingsCtrl.text = e.servings?.toString() ?? '';
      _ingredientsCtrl.text = e.ingredients.join('\n');
      _stepsCtrl.text = e.steps.join('\n');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingsCtrl.dispose();
    _ingredientsCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.recipeManualNeedName)),
      );
      return;
    }
    final hid = ref.read(householdIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (hid == null || uid == null) return;

    List<String> lines(String s) =>
        s.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    setState(() => _saving = true);
    try {
      final e = widget.existing;
      final recipe = Recipe(
        id: e?.id ?? '',
        name: name,
        servings: int.tryParse(_servingsCtrl.text.trim()),
        ingredients: lines(_ingredientsCtrl.text),
        steps: lines(_stepsCtrl.text),
        addedAt: e?.addedAt ?? DateTime.now(),
        addedBy: e?.addedBy ?? uid,
      );
      await ref.read(firestoreServiceProvider).saveRecipe(hid, recipe);
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l.commonError(err.toString())),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l.recipeManualEditTitle : l.recipeWrite),
        actions: [
          TextButton(
              onPressed: _saving ? null : _save, child: Text(l.commonSave)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.recipeManualNameLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _servingsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l.recipeManualServingsLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ingredientsCtrl,
            minLines: 4,
            maxLines: null,
            decoration: InputDecoration(
              labelText: l.recipeManualIngredientsLabel,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _stepsCtrl,
            minLines: 4,
            maxLines: null,
            decoration: InputDecoration(
              labelText: l.recipeManualStepsLabel,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.recipeManualSave),
          ),
        ],
      ),
    );
  }
}
