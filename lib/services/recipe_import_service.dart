import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_details.dart';

/// Reads a recipe directly from a web page's schema.org JSON-LD (the same
/// structured data Google uses). Lightweight — JSON-LD only, no AI, no full-page
/// scraping — so it won't freeze the UI. Returns null if the page has no recipe.
class RecipeImportService {
  final http.Client _client;
  RecipeImportService([http.Client? client]) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 15);

  Future<RecipeDetails?> fetchDetails(String url) async {
    final resp = await _client.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0 (compatible; Stashpot/1.0)'},
    ).timeout(_timeout);

    if (resp.statusCode != 200) {
      throw Exception('Could not fetch the page (HTTP ${resp.statusCode})');
    }

    final node = _findRecipeNode(resp.body);
    if (node == null) return null;
    return _detailsFromJsonLd(node, url);
  }

  Map? _findRecipeNode(String html) {
    final scripts = RegExp(
      r'<script[^>]*type=["' "'" r']application/ld\+json["' "'" r'][^>]*>(.*?)</script>',
      dotAll: true,
      caseSensitive: false,
    ).allMatches(html);

    for (final m in scripts) {
      try {
        final found = _search(jsonDecode(m.group(1)!.trim()));
        if (found != null) return found;
      } catch (_) {
        // malformed block — keep looking
      }
    }
    return null;
  }

  Map? _search(dynamic node) {
    if (node is List) {
      for (final n in node) {
        final r = _search(n);
        if (r != null) return r;
      }
    } else if (node is Map) {
      final type = node['@type'];
      final isRecipe = type == 'Recipe' || (type is List && type.contains('Recipe'));
      if (isRecipe) return node;
      if (node['@graph'] != null) return _search(node['@graph']);
    }
    return null;
  }

  RecipeDetails _detailsFromJsonLd(Map node, String url) {
    final ingredients = (node['recipeIngredient'] as List?)
            ?.map((e) => _strip(e.toString()))
            .where((s) => s.isNotEmpty)
            .map((line) => RecipeIngredient(name: line, original: line))
            .toList() ??
        const <RecipeIngredient>[];

    return RecipeDetails(
      id: 0,
      title: _strip((node['name'] ?? '').toString()),
      image: _firstImage(node['image']),
      sourceUrl: url,
      servings: _parseYield(node['recipeYield']),
      ingredients: ingredients,
      steps: _parseInstructions(node['recipeInstructions']),
      nutrition: Nutrition.fromJsonLd(node['nutrition']),
    );
  }

  String? _firstImage(dynamic img) {
    if (img is String) return img;
    if (img is Map) return img['url']?.toString();
    if (img is List && img.isNotEmpty) return _firstImage(img.first);
    return null;
  }

  int? _parseYield(dynamic y) {
    if (y is int) return y;
    if (y is List && y.isNotEmpty) return _parseYield(y.first);
    if (y is String) {
      final m = RegExp(r'\d+').firstMatch(y);
      return m != null ? int.tryParse(m.group(0)!) : null;
    }
    return null;
  }

  List<String> _parseInstructions(dynamic instr) {
    final steps = <String>[];
    void add(dynamic x) {
      if (x is String) {
        final t = _strip(x);
        if (t.isNotEmpty) steps.add(t);
      } else if (x is Map) {
        if (x['@type'] == 'HowToSection' && x['itemListElement'] is List) {
          for (final e in x['itemListElement']) {
            add(e);
          }
        } else if (x['text'] != null) {
          final t = _strip(x['text'].toString());
          if (t.isNotEmpty) steps.add(t);
        }
      }
    }

    if (instr is String) {
      for (final line in instr.split(RegExp(r'\n+'))) {
        final t = _strip(line);
        if (t.isNotEmpty) steps.add(t);
      }
    } else if (instr is List) {
      for (final e in instr) {
        add(e);
      }
    }
    return steps;
  }

  String _strip(String s) => _unescape(
        s.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim(),
      );

  String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}
