import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/recipe.dart';
import '../../services/link_preview_service.dart';
import '../../services/recipe_import_service.dart';
import '../../services/spoonacular_service.dart';
import 'auth_providers.dart';

final spoonacularServiceProvider =
    Provider<SpoonacularService>((_) => SpoonacularService());

final linkPreviewServiceProvider =
    Provider<LinkPreviewService>((_) => LinkPreviewService());

final recipeImportServiceProvider =
    Provider<RecipeImportService>((_) => RecipeImportService());

final recipesProvider = StreamProvider<List<Recipe>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  if (householdId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).recipesStream(householdId);
});
