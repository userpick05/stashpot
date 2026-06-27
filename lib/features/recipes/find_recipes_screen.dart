import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/recipe_providers.dart';
import '../../models/recipe_hit.dart';
import 'recipe_detail_screen.dart';
import 'star_rating.dart';

class FindRecipesScreen extends ConsumerStatefulWidget {
  const FindRecipesScreen({super.key});

  @override
  ConsumerState<FindRecipesScreen> createState() => _FindRecipesScreenState();
}

class _FindRecipesScreenState extends ConsumerState<FindRecipesScreen> {
  final _searchCtrl = TextEditingController();
  List<RecipeHit> _results = [];
  bool _loading = false;
  String? _error;
  bool _pantryMode = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<List<RecipeHit>> Function() op, {required bool pantry}) async {
    setState(() {
      _loading = true;
      _error = null;
      _pantryMode = pantry;
    });
    try {
      final r = await op();
      if (!mounted) return;
      setState(() => _results = r);
      if (r.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No recipes found — try different terms')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    // If they pasted a link, preview it as a card with a Save button.
    if (q.startsWith('http')) {
      _previewLink(q);
      return;
    }
    _run(() => ref.read(spoonacularServiceProvider).search(q), pantry: false);
  }

  Future<void> _previewLink(String url) async {
    setState(() {
      _loading = true;
      _error = null;
      _pantryMode = false;
    });
    try {
      final meta = await ref.read(linkPreviewServiceProvider).fetchMeta(url);
      if (!mounted) return;
      setState(() {
        _results = [
          RecipeHit(id: 0, title: meta.name, image: meta.image, sourceUrl: url),
        ];
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fromPantry() {
    final names = (ref.read(inventoryProvider).valueOrNull ?? []).map((i) => i.name).toList();
    if (names.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your pantry is empty — add some items first')),
      );
      return;
    }
    _run(() => ref.read(spoonacularServiceProvider).searchByPantry(names), pantry: true);
  }

  Future<void> _open(RecipeHit h) async {
    final url = h.sourceUrl;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No web link for this recipe')),
      );
      return;
    }
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  void _view(RecipeHit h) {
    final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: h.toRecipe(uid))),
    );
  }

  Future<void> _save(RecipeHit h) async {
    final householdId = ref.read(householdIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (householdId == null || uid == null) return;
    await ref.read(firestoreServiceProvider).saveRecipe(householdId, h.toRecipe(uid));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "${h.title}"'), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find recipes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Search a dish, or paste a recipe link',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: TextButton(onPressed: _search, child: const Text('Search')),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _fromPantry,
                  icon: const Icon(Icons.kitchen),
                  label: const Text('What can I make from my pantry?'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Lookup failed: $_error', textAlign: TextAlign.center),
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Search for a dish, or tap "What can I make"\nfor ideas from what you have.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.outline),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, i) => _HitCard(
                          hit: _results[i],
                          pantryMode: _pantryMode,
                          onView: () => _view(_results[i]),
                          onOpen: () => _open(_results[i]),
                          onSave: () => _save(_results[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _HitCard extends StatelessWidget {
  final RecipeHit hit;
  final bool pantryMode;
  final VoidCallback onView;
  final VoidCallback onOpen;
  final VoidCallback onSave;

  const _HitCard({
    required this.hit,
    required this.pantryMode,
    required this.onView,
    required this.onOpen,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hit.image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(hit.image!,
                      width: 72, height: 72, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, size: 48)),
                )
              else
                const Icon(Icons.restaurant, size: 48),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hit.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (hit.score != null) StarRating(stars: hit.stars, count: hit.likes),
                    if (pantryMode && hit.missedCount != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          hit.missedCount == 0
                              ? 'You have everything!'
                              : 'Missing ${hit.missedCount} ingredient(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: hit.missedCount == 0 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'Open in browser',
                    onPressed: onOpen,
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_add_outlined),
                    tooltip: 'Save',
                    onPressed: onSave,
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
