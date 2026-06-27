import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/planned_meal.dart';
import 'auth_providers.dart';

final plannerProvider = StreamProvider<List<PlannedMeal>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  if (householdId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).plannerStream(householdId);
});
