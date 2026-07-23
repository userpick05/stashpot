import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/recipe_providers.dart';
import '../../core/utils/pantry_match.dart';
import '../../l10n/app_localizations.dart';
import '../../models/recipe.dart';
import '../../models/recipe_details.dart';
import '../../models/shopping_item.dart';
import 'add_recipe_manual_screen.dart';
import 'star_rating.dart';

/// Shows a recipe in-app: ingredients (with pantry cross-check + add-to-list)
/// and instructions. Full data is fetched from Spoonacular when available.
class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  RecipeDetails? _details;
  bool _loading = false;
  String? _error;
  bool _saved = false;

  Recipe get recipe => widget.recipe;

  /// PantryMatch only tokenizes Latin script, so a translated recipe carries a
  /// separate matchName. Check both, since the shopping list may hold either.
  static bool _inList(RecipeIngredient i, List<String> names) =>
      PantryMatch.hasIngredient(i.matchName, names) ||
      (i.matchName != i.name && PantryMatch.hasIngredient(i.name, names));

  @override
  void initState() {
    super.initState();
    _saved = recipe.id.isNotEmpty;
    final hasSource = recipe.spoonacularId != null || recipe.sourceUrl != null;
    if (recipe.ingredients.isNotEmpty || recipe.steps.isNotEmpty) {
      // Hand-entered recipe, or a saved link whose content we already fetched.
      _details = RecipeDetails(
        id: 0,
        title: recipe.name,
        image: recipe.imageUrl,
        servings: recipe.servings,
        ingredients: [
          for (var i = 0; i < recipe.ingredients.length; i++)
            RecipeIngredient(
              name: recipe.ingredients[i],
              original: recipe.ingredients[i],
              matchName: i < recipe.matchNames.length
                  ? recipe.matchNames[i]
                  : null,
            )
        ],
        steps: recipe.steps,
        aiTranslated: recipe.detailsAi,
      );
    }
    if (_details == null && hasSource) {
      // Set here, not in _load: the load is deferred a frame (below), and
      // without this the first build would flash the "couldn't read a recipe"
      // card before the spinner appears.
      _loading = true;
    }
    if (hasSource) {
      // Deferred a frame: reading the locale needs Localizations, which isn't
      // available during initState.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _init();
      });
    }
  }

  /// Decides whether the stored content is good enough to show as-is.
  Future<void> _init() async {
    final stored = _details;
    if (stored != null) {
      final lang = Localizations.localeOf(context).languageCode;
      // Stored content in the reader's language (or hand-entered, which has no
      // language stamp) — show it, no network, works offline.
      if (recipe.detailsLang == null || recipe.detailsLang == lang) return;
      // Saved in the other language: re-fetch so this reader gets their own.
      // The stored copy stays on screen meanwhile.
    }
    await _load();
  }

  Future<void> _load({bool force = false}) async {
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      RecipeDetails? d;
      if (recipe.spoonacularId != null) {
        // Found via search → pull from Spoonacular by id.
        d = await ref.read(spoonacularServiceProvider).getDetails(recipe.spoonacularId!);
      } else if (recipe.sourceUrl != null) {
        // Saved as a link → read the recipe straight off the page, translated
        // into the app's language if the page is in another one.
        d = await ref.read(recipeImportServiceProvider).fetchDetails(
            recipe.sourceUrl!,
            languageCode: lang,
            forceRefresh: force);
      }
      // Keep whatever we already had if the refetch came back empty — a failed
      // language refresh shouldn't blank out a recipe that was on screen.
      if (mounted) setState(() => _details = d ?? _details);
      if (d != null) unawaited(_storeDetails(d, lang));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// A link recipe is saved as soon as it's pasted, so its content arrives
  /// later — write it back onto the doc here. Reopening then reads from
  /// Firestore: instant, offline-capable, and no repeat translation bill.
  ///
  /// Link recipes only. Spoonacular details are re-fetched cheaply and carry
  /// nutrition and cook time the recipe doc has nowhere to put, so caching them
  /// here would quietly lose them.
  Future<void> _storeDetails(RecipeDetails d, String lang) async {
    if (!_saved ||
        recipe.sourceUrl == null ||
        recipe.spoonacularId != null ||
        !d.hasContent ||
        recipe.detailsLang == lang) {
      return;
    }
    final hid = ref.read(householdIdProvider);
    if (hid == null) return;
    try {
      await ref
          .read(firestoreServiceProvider)
          .saveRecipe(hid, _withDetails(recipe, d, lang));
    } catch (_) {
      // Purely a cache — a failed write just means we fetch again next time.
    }
  }

  Recipe _withDetails(Recipe r, RecipeDetails d, String lang) => r.copyWith(
        ingredients: d.ingredients.map((i) => i.original).toList(),
        // Only worth storing when they differ from the displayed lines; that's
        // exactly the translated case, where PantryMatch needs the Latin side.
        matchNames: d.ingredients.any((i) => i.matchName != i.name)
            ? d.ingredients.map((i) => i.matchName).toList()
            : const [],
        steps: d.steps,
        servings: d.servings,
        detailsLang: lang,
        detailsAi: d.aiTranslated || d.aiExtracted,
      );

  Future<void> _open() async {
    final url = recipe.sourceUrl ?? _details?.sourceUrl;
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _save() async {
    final hid = ref.read(householdIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (hid == null || uid == null) return;
    var toSave = recipe;
    final d = _details;
    if (d != null &&
        d.hasContent &&
        recipe.sourceUrl != null &&
        recipe.spoonacularId == null) {
      toSave = _withDetails(
          recipe, d, Localizations.localeOf(context).languageCode);
    }
    await ref.read(firestoreServiceProvider).saveRecipe(hid, toSave);
    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).recipeSaved(recipe.name))),
      );
    }
  }

  // Delete immediately + pop, with an Undo snackbar (no confirm dialog —
  // AlertDialogs black-screen via Impeller on some devices).
  Future<void> _delete() async {
    final hid = ref.read(householdIdProvider);
    if (hid == null) return;
    final svc = ref.read(firestoreServiceProvider);
    // Capture before popping so the snackbar lives on the app-level messenger
    // (showing it on a screen we're about to pop leaves it stuck).
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = AppLocalizations.of(context);
    await svc.deleteRecipe(hid, recipe.id);
    if (!mounted) return;
    navigator.pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(l.recipeRemoved(recipe.name)),
          action: SnackBarAction(
            label: l.commonUndo,
            onPressed: () => svc.saveRecipe(hid, recipe),
          ),
        ),
      );
  }

  Future<void> _addToShopping(List<String> names) async {
    final hid = ref.read(householdIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (hid == null || uid == null || names.isEmpty) return;
    final l = AppLocalizations.of(context);
    final svc = ref.read(firestoreServiceProvider);
    for (final n in names) {
      await svc.addShoppingItem(
        hid,
        ShoppingItem(
          id: const Uuid().v4(),
          name: n,
          quantity: 1,
          note: l.recipeShoppingNote(recipe.name),
          checked: false,
          addedAt: DateTime.now(),
          addedBy: uid,
        ),
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.recipeAddedToShopping(names.length))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pantryNames =
        (ref.watch(inventoryProvider).valueOrNull ?? []).map((i) => i.name).toList();
    final shoppingNames =
        (ref.watch(shoppingProvider).valueOrNull ?? []).map((i) => i.name).toList();
    final d = _details;
    final ingredients = d?.ingredients ?? const <RecipeIngredient>[];
    final missing =
        ingredients.where((i) => !_inList(i, pantryNames)).toList();
    final haveCount = ingredients.length - missing.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            (d?.title.isNotEmpty ?? false) ? d!.title : recipe.name,
            overflow: TextOverflow.ellipsis),
        actions: [
          if (recipe.sourceUrl != null || d?.sourceUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: l.recipeOpenOriginalTooltip,
              onPressed: _open,
            ),
          if (_saved && recipe.isManual)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l.recipeEditTooltip,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddRecipeManualScreen(existing: recipe),
                ),
              ),
            ),
          if (_saved)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l.commonDelete,
                onPressed: _delete)
          else
            IconButton(
                icon: const Icon(Icons.bookmark_add),
                tooltip: l.commonSave,
                onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if ((d?.image ?? recipe.imageUrl) != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network((d?.image ?? recipe.imageUrl)!,
                  height: 200, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (recipe.score != null) StarRating(stars: recipe.stars, count: recipe.likes),
              const Spacer(),
              if (d?.servings != null) ...[
                const Icon(Icons.people_outline, size: 18),
                const SizedBox(width: 4),
                Text('${d!.servings}'),
                const SizedBox(width: 12),
              ],
              if (d?.readyInMinutes != null) ...[
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 4),
                Text(l.recipeMinutes(d!.readyInMinutes!)),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // ── Nutrition (per serving), when available ────────────────────
          if (d?.nutrition != null && !d!.nutrition!.isEmpty) ...[
            _NutritionRow(nutrition: d.nutrition!),
            const SizedBox(height: 16),
          ],

          // Machine translation isn't always right — say so rather than
          // passing AI text off as what the page actually said.
          // Only once there's actual AI-produced content on screen — never
          // hovering above a spinner or a "couldn't read this page" card.
          if (d != null &&
              (d.aiTranslated || d.aiExtracted) &&
              d.hasContent &&
              !_loading &&
              _error == null) ...[
            Row(
              children: [
                Icon(Icons.translate,
                    size: 16, color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.recipeAiTranslated,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Body state: always shows exactly one of these ──────────────
          if (_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l.recipeReadingPage,
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            )
          else if (ingredients.isEmpty && (d?.steps.isEmpty ?? true))
            // Failed to load, OR no structured data (link recipe / empty
            // details). Only when there's nothing to show — a failed refresh
            // shouldn't replace a recipe already on screen with an error.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(_error != null ? Icons.wifi_off : Icons.menu_book, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    _error != null
                        ? l.recipeLoadFailed
                        : l.recipeNoStructuredData,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (recipe.spoonacularId != null || recipe.sourceUrl != null)
                        FilledButton.icon(
                            onPressed: () => _load(force: true),
                            icon: const Icon(Icons.refresh),
                            label: Text(l.commonRetry)),
                      if ((recipe.sourceUrl ?? d?.sourceUrl) != null)
                        OutlinedButton.icon(
                            onPressed: _open,
                            icon: const Icon(Icons.open_in_new),
                            label: Text(l.recipeOpenInBrowser)),
                    ],
                  ),
                ],
              ),
            )
          else ...[
            // Ingredients + cross-check
            Row(
              children: [
                Text(l.recipeIngredients,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(l.recipeHaveCount(haveCount, ingredients.length),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            if (missing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(l.recipeAddMissing(missing.length)),
                  onPressed: () => _addToShopping(missing.map((i) => i.name).toList()),
                ),
              ),
            for (final ing in ingredients)
              _IngredientRow(
                ingredient: ing,
                inPantry: _inList(ing, pantryNames),
                onList: _inList(ing, shoppingNames),
                onAdd: () => _addToShopping([ing.name]),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.playlist_add),
              label: Text(l.recipeAddAllIngredients),
              onPressed: () => _addToShopping(ingredients.map((i) => i.name).toList()),
            ),
            const SizedBox(height: 20),
            if (d != null && d.steps.isNotEmpty) ...[
              Text(l.recipeInstructions,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (var i = 0; i < d.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(d.steps[i])),
                    ],
                  ),
                ),
            ],
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final RecipeIngredient ingredient;
  final bool inPantry;
  final bool onList;
  final VoidCallback onAdd;
  const _IngredientRow({
    required this.ingredient,
    required this.inPantry,
    required this.onList,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            inPantry ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: inPantry ? Colors.green : scheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(ingredient.original)),
          if (!inPantry)
            // Solid, colored cart once it's on the shopping list — lasting
            // confirmation beyond the transient snackbar. Still tappable to
            // add another.
            IconButton(
              icon: Icon(
                onList ? Icons.shopping_cart : Icons.add_shopping_cart,
                size: 20,
                color: onList ? scheme.primary : null,
              ),
              tooltip: onList
                  ? l.recipeOnListTooltip
                  : l.recipeAddToShoppingTooltip,
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final Nutrition nutrition;
  const _NutritionRow({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Display labels only — the Spoonacular field names used to look these up
    // (in recipe_details.dart) stay English.
    final stats = <(String, String?)>[
      (l.recipeCalories, nutrition.calories),
      (l.recipeProtein, nutrition.protein),
      (l.recipeCarbs, nutrition.carbs),
      (l.recipeFat, nutrition.fat),
    ].where((s) => s.$2 != null).toList();
    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(l.recipeNutritionTitle,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Row(
            children: [
              for (final s in stats)
                Expanded(
                  child: Column(
                    children: [
                      Text(s.$2!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 2),
                      Text(s.$1,
                          style: TextStyle(fontSize: 12, color: scheme.outline)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
