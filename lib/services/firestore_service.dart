import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/catalog_item.dart';
import '../models/household.dart';
import '../models/inventory_item.dart';
import '../models/planned_meal.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';

/// Thrown when a write can't reach the server in time. Lets the UI show a
/// readable message instead of spinning forever.
class NetworkTimeoutException implements Exception {
  @override
  String toString() =>
      "Couldn't reach the server. Check your connection and try again.";
}

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  static const _writeTimeout = Duration(seconds: 15);

  // Ensures /users/{uid} exists and is complete. Self-heals accounts that were
  // registered before the Firestore database existed (their user doc was never
  // written). Pulls name/email from the signed-in Firebase Auth user.
  Map<String, dynamic> _userDocFields() {
    final u = FirebaseAuth.instance.currentUser;
    return {
      if (u?.email != null) 'email': u!.email,
      if (u?.displayName != null && u!.displayName!.isNotEmpty)
        'displayName': u.displayName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // ── Household ────────────────────────────────────────────────────────────

  Future<Household> createHousehold({
    required String uid,
    required String name,
  }) async {
    final ref = _db.collection('households').doc();
    final household = Household(
      id: ref.id,
      name: name,
      memberUids: [uid],
      createdBy: uid,
      createdAt: DateTime.now(),
    );
    final batch = _db.batch();
    batch.set(ref, household.toFirestore());
    // set+merge (not update) so it creates the user doc if it's missing.
    batch.set(
      _db.collection('users').doc(uid),
      {..._userDocFields(), 'householdId': ref.id},
      SetOptions(merge: true),
    );
    await batch.commit().timeout(_writeTimeout,
        onTimeout: () => throw NetworkTimeoutException());
    return household;
  }

  Future<void> joinHousehold({
    required String uid,
    required String householdId,
  }) async {
    final ref = _db.collection('households').doc(householdId);
    final snap = await ref.get().timeout(_writeTimeout,
        onTimeout: () => throw NetworkTimeoutException());
    if (!snap.exists) {
      throw Exception('Household not found. Check your invite code.');
    }

    final batch = _db.batch();
    batch.update(ref, {
      'memberUids': FieldValue.arrayUnion([uid]),
    });
    batch.set(
      _db.collection('users').doc(uid),
      {..._userDocFields(), 'householdId': householdId},
      SetOptions(merge: true),
    );
    await batch.commit().timeout(_writeTimeout,
        onTimeout: () => throw NetworkTimeoutException());
  }

  // ── Stores (shared list per household) ───────────────────────────────────

  Stream<List<String>> storesStream(String householdId) => _db
      .collection('households')
      .doc(householdId)
      .snapshots()
      .map((s) {
        final list = (s.data()?['stores'] as List?)?.cast<String>() ?? const [];
        return list..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });

  Future<void> addStore(String householdId, String name) => _db
      .collection('households')
      .doc(householdId)
      .update({
        'stores': FieldValue.arrayUnion([name]),
      });

  Future<void> removeStore(String householdId, String name) => _db
      .collection('households')
      .doc(householdId)
      .update({
        'stores': FieldValue.arrayRemove([name]),
      });

  // ── Inventory ────────────────────────────────────────────────────────────

  Stream<List<InventoryItem>> inventoryStream(String householdId) => _db
      .collection('households')
      .doc(householdId)
      .collection('items')
      .orderBy('addedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(InventoryItem.fromFirestore).toList());

  Future<void> addItem(String householdId, InventoryItem item) => _db
      .collection('households')
      .doc(householdId)
      .collection('items')
      .doc(item.id.isEmpty ? null : item.id)
      .set(item.toFirestore());

  Future<void> updateItem(String householdId, InventoryItem item) => _db
      .collection('households')
      .doc(householdId)
      .collection('items')
      .doc(item.id)
      .update(item.toFirestore());

  Future<void> deleteItem(String householdId, String itemId) => _db
      .collection('households')
      .doc(householdId)
      .collection('items')
      .doc(itemId)
      .delete();

  // ── Shopping list (shared per household) ─────────────────────────────────

  CollectionReference<Map<String, dynamic>> _shoppingRef(String householdId) =>
      _db.collection('households').doc(householdId).collection('shopping');

  Stream<List<ShoppingItem>> shoppingStream(String householdId) =>
      _shoppingRef(householdId)
          .orderBy('addedAt', descending: false)
          .snapshots()
          .map((s) => s.docs.map(ShoppingItem.fromFirestore).toList());

  Future<void> addShoppingItem(String householdId, ShoppingItem item) async {
    await _shoppingRef(householdId).doc(item.id).set(item.toFirestore());
    // Remember it in the catalog for quick reordering later.
    await _recordCatalog(householdId, item);
  }

  Future<void> setShoppingChecked(
          String householdId, String itemId, bool checked) =>
      _shoppingRef(householdId).doc(itemId).update({'checked': checked});

  // Edit an existing shopping item (no catalog re-record).
  Future<void> updateShoppingItem(String householdId, ShoppingItem item) =>
      _shoppingRef(householdId).doc(item.id).set(item.toFirestore());

  Future<void> deleteShoppingItem(String householdId, String itemId) =>
      _shoppingRef(householdId).doc(itemId).delete();

  // Removes every checked-off item in one batch.
  Future<void> clearCheckedShopping(String householdId) async {
    final snap = await _shoppingRef(householdId)
        .where('checked', isEqualTo: true)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  // ── Catalog (previously-added items, for reordering) ─────────────────────

  CollectionReference<Map<String, dynamic>> _catalogRef(String householdId) =>
      _db.collection('households').doc(householdId).collection('catalog');

  Future<void> _recordCatalog(String householdId, ShoppingItem item) {
    final id = CatalogItem.idFor(item.name);
    if (id.isEmpty) return Future.value();
    return _catalogRef(householdId).doc(id).set({
      'name': item.name,
      if (item.store != null) 'store': item.store,
      'quantity': item.quantity,
      if (item.note != null) 'note': item.note,
      'timesAdded': FieldValue.increment(1),
      'lastAddedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<CatalogItem>> catalogStream(String householdId) =>
      _catalogRef(householdId)
          .snapshots()
          .map((s) => s.docs.map(CatalogItem.fromFirestore).toList());

  Future<void> deleteCatalogItem(String householdId, String catalogId) =>
      _catalogRef(householdId).doc(catalogId).delete();

  // ── Recipes (shared per household) ───────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _recipesRef(String householdId) =>
      _db.collection('households').doc(householdId).collection('recipes');

  Stream<List<Recipe>> recipesStream(String householdId) =>
      _recipesRef(householdId)
          .orderBy('addedAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(Recipe.fromFirestore).toList());

  Future<void> saveRecipe(String householdId, Recipe recipe) {
    final ref = recipe.id.isEmpty
        ? _recipesRef(householdId).doc()
        : _recipesRef(householdId).doc(recipe.id);
    return ref.set(recipe.toFirestore());
  }

  Future<void> deleteRecipe(String householdId, String recipeId) =>
      _recipesRef(householdId).doc(recipeId).delete();

  // ── Meal planner (shared per household) ──────────────────────────────────

  CollectionReference<Map<String, dynamic>> _plannerRef(String householdId) =>
      _db.collection('households').doc(householdId).collection('planner');

  Stream<List<PlannedMeal>> plannerStream(String householdId) =>
      _plannerRef(householdId)
          .orderBy('date')
          .snapshots()
          .map((s) => s.docs.map(PlannedMeal.fromFirestore).toList());

  Future<void> savePlannedMeal(String householdId, PlannedMeal meal) {
    final ref = meal.id.isEmpty
        ? _plannerRef(householdId).doc()
        : _plannerRef(householdId).doc(meal.id);
    return ref.set(meal.toFirestore());
  }

  Future<void> deletePlannedMeal(String householdId, String mealId) =>
      _plannerRef(householdId).doc(mealId).delete();
}
