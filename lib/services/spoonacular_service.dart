import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_details.dart';
import '../models/recipe_hit.dart';

class SpoonacularService {
  // Injected at build time via --dart-define-from-file=secrets.json
  static const _apiKey = String.fromEnvironment('SPOONACULAR_API_KEY');
  static const _base = 'https://api.spoonacular.com';
  static const _timeout = Duration(seconds: 20);

  final http.Client _client;
  SpoonacularService([http.Client? client]) : _client = client ?? http.Client();

  bool get isConfigured => _apiKey.isNotEmpty;

  void _ensureKey() {
    if (!isConfigured) {
      throw Exception(
          'Spoonacular API key not set. Rebuild with --dart-define-from-file=secrets.json');
    }
  }

  /// Search real web recipes by dish name / keywords.
  Future<List<RecipeHit>> search(String query) async {
    _ensureKey();
    final uri = Uri.parse('$_base/recipes/complexSearch').replace(queryParameters: {
      'query': query,
      'addRecipeInformation': 'true',
      'number': '15',
      'sort': 'popularity',
      'apiKey': _apiKey,
    });
    final results = await _getResults(uri);
    return results.map(RecipeHit.fromJson).toList();
  }

  /// "What can I make from my pantry?" — ranks by ingredients you already have.
  Future<List<RecipeHit>> searchByPantry(List<String> ingredients) async {
    _ensureKey();
    final uri = Uri.parse('$_base/recipes/complexSearch').replace(queryParameters: {
      'includeIngredients': ingredients.take(60).join(','),
      'addRecipeInformation': 'true',
      'fillIngredients': 'true',
      'sort': 'max-used-ingredients',
      'number': '15',
      'apiKey': _apiKey,
    });
    final results = await _getResults(uri);
    return results.map(RecipeHit.fromJson).toList();
  }

  /// Full recipe data (ingredients + instructions) for one recipe.
  Future<RecipeDetails> getDetails(int id) async {
    _ensureKey();
    final uri = Uri.parse('$_base/recipes/$id/information').replace(queryParameters: {
      'includeNutrition': 'true',
      'apiKey': _apiKey,
    });
    final resp = await _client.get(uri).timeout(_timeout);
    if (resp.statusCode == 402) {
      throw Exception('Daily Spoonacular quota reached — try again tomorrow');
    }
    if (resp.statusCode != 200) {
      throw Exception('Could not load recipe (HTTP ${resp.statusCode})');
    }
    return RecipeDetails.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> _getResults(Uri uri) async {
    final resp = await _client.get(uri).timeout(_timeout);
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw Exception('Spoonacular key rejected (HTTP ${resp.statusCode})');
    }
    if (resp.statusCode == 402) {
      throw Exception('Daily Spoonacular quota reached — try again tomorrow');
    }
    if (resp.statusCode != 200) {
      throw Exception('Search failed (HTTP ${resp.statusCode})');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return (json['results'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  }
}
