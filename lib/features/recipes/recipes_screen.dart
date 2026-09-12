import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/recipe_providers.dart';
import '../../core/utils/recipe_tags.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../l10n/app_localizations.dart';
import '../../models/recipe.dart';
import 'add_recipe_manual_screen.dart';
import 'recipe_detail_screen.dart';
import 'recipe_tag_chips.dart';
import 'star_rating.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addByLink() async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    // Bottom sheet (not an AlertDialog — those black-screen via Impeller on
    // some devices, e.g. Pixel 10).
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.recipeAddByLinkTitle,
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: l.recipeAddByLinkHint,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(l.commonSave),
            ),
          ],
        ),
      ),
    );
    if (url == null) return;
    final u = url.trim();
    if (!u.startsWith('http')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.recipeLinkNeedsHttp)),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l.recipeSavingLink),
            duration: const Duration(seconds: 1)),
      );
    }
    try {
      final meta = await ref.read(linkPreviewServiceProvider).fetchMeta(u);
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      final hid = ref.read(householdIdProvider);
      if (uid == null || hid == null) return;
      await ref.read(firestoreServiceProvider).saveRecipe(
            hid,
            withAutoTags(Recipe(
              id: '',
              name: meta.name,
              imageUrl: meta.image,
              sourceUrl: u,
              addedAt: DateTime.now(),
              addedBy: uid,
            )),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.recipeSaved(meta.name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l.recipeLinkSaveFailed(e.toString())),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final recipes = ref.watch(recipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navRecipes),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: l.recipeWrite,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddRecipeManualScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: l.recipeAddByLinkTooltip,
            onPressed: _addByLink,
          ),
          IconButton(
            icon: const Icon(Icons.travel_explore),
            tooltip: l.findRecipesTitle,
            onPressed: () => context.push('/recipes/find'),
          ),
        ],
      ),
      body: recipes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.commonError(e.toString()))),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu,
                      size: 80, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(l.recipeEmptyTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(l.recipeEmptyHint),
                ],
              ),
            );
          }

          // Drop any selected tag that's no longer in use (e.g. after a delete)
          // so the filter can't get stuck on an empty result.
          final inUse = recipeTagsInUse(list);
          _selectedTags.removeWhere((t) => !inUse.contains(t));
          final filtered = filterRecipes(list,
              search: _search, selectedTags: _selectedTags);

          return Column(
            children: [
              _buildFilterBar(l, inUse),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(l.recipeNoMatches,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.outline)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _recipeCard(filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/recipes/find'),
        icon: const Icon(Icons.search),
        label: Text(l.findRecipesTitle),
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations l, List<String> inUse) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: l.recipeSearchHint,
              border: const OutlineInputBorder(),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        if (inUse.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final tag in inUse)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(recipeTagLabelOf(l, tag)),
                      selected: _selectedTags.contains(tag),
                      onSelected: (on) => setState(() =>
                          on ? _selectedTags.add(tag) : _selectedTags.remove(tag)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _recipeCard(Recipe r) {
    return SwipeToDelete(
      key: ValueKey(r.id),
      itemId: r.id,
      label: r.name,
      onDelete: () async {
        final hid = ref.read(householdIdProvider);
        if (hid != null) {
          await ref.read(firestoreServiceProvider).deleteRecipe(hid, r.id);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: r.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(r.imageUrl!,
                      width: 56, height: 56, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.restaurant, size: 40)),
                )
              : const Icon(Icons.restaurant, size: 40),
          title: Text(r.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: (r.score != null || r.tags.isNotEmpty)
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.score != null)
                        StarRating(stars: r.stars, count: r.likes),
                      if (r.tags.isNotEmpty) ...[
                        if (r.score != null) const SizedBox(height: 4),
                        RecipeTagChips(tags: r.tags),
                      ],
                    ],
                  ),
                )
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
          ),
        ),
      ),
    );
  }
}
