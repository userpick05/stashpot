import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/recipe_providers.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../models/recipe.dart';
import 'add_recipe_manual_screen.dart';
import 'recipe_detail_screen.dart';
import 'star_rating.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  Future<void> _addByLink(BuildContext context, WidgetRef ref) async {
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
            Text('Add recipe by link',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'Paste a recipe URL',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (url == null) return;
    final u = url.trim();
    if (!u.startsWith('http')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a full link starting with http')),
        );
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving link…'), duration: Duration(seconds: 1)),
      );
    }
    try {
      final meta = await ref.read(linkPreviewServiceProvider).fetchMeta(u);
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      final hid = ref.read(householdIdProvider);
      if (uid == null || hid == null) return;
      await ref.read(firestoreServiceProvider).saveRecipe(
            hid,
            Recipe(
              id: '',
              name: meta.name,
              imageUrl: meta.image,
              sourceUrl: u,
              addedAt: DateTime.now(),
              addedBy: uid,
            ),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved "${meta.name}"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save link: $e'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Write a recipe',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddRecipeManualScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Add by link',
            onPressed: () => _addByLink(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.travel_explore),
            tooltip: 'Find recipes',
            onPressed: () => context.push('/recipes/find'),
          ),
        ],
      ),
      body: recipes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu,
                      size: 80, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No saved recipes yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Tap "Find recipes" to search the web'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
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
                    subtitle: r.score != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: StarRating(stars: r.stars, count: r.likes),
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/recipes/find'),
        icon: const Icon(Icons.search),
        label: const Text('Find recipes'),
      ),
    );
  }
}
