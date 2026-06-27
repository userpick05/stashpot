import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/open_food_facts_service.dart';
import '../../services/gemini_service.dart';
import '../../services/storage_service.dart';

final openFoodFactsServiceProvider =
    Provider<OpenFoodFactsService>((_) => OpenFoodFactsService());

final geminiServiceProvider = Provider<GeminiService>((_) => GeminiService());

final storageServiceProvider = Provider<StorageService>((_) => StorageService());
