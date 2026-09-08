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

  // ── Custom food types (shared list per household) ────────────────────────

  Stream<List<String>> categoriesStream(String householdId) => _db
      .collection('households')
      .doc(householdId)
      .snapshots()
      .map((s) {
        final list =
            (s.data()?['categories'] as List?)?.cast<String>() ?? const [];
        return list..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });

  Future<void> addCategory(String householdId, String name) => _db
      .collection('households')
      .doc(householdId)
      .set({
        'categories': FieldValue.arrayUnion([name]),
      }, SetOptions(merge: true));

  Future<void> removeCategory(String householdId, String name) => _db
      .collection('households')
      .doc(householdId)
      .set({
        'categories': FieldValue.arrayRemove([name]),
      }, SetOptions(merge: true));

  // Rename a custom food type and move every item (in BOTH the stash and the
  // shopping list) that used it to the new name — the same idea as
  // renameLocation, but customCategory lives on both collections.
  Future<void> renameCategory(
      String householdId, String oldName, String newName) async {
    await removeCategory(householdId, oldName);
    await addCategory(householdId, newName);
    final hh = _db.collection('households').doc(householdId);
    for (final col in ['items', 'shopping']) {
      final affected = await hh
          .collection(col)
          .where('customCategory', isEqualTo: oldName)
          .get();
      if (affected.docs.isEmpty) continue;
      final batch = _db.batch();
      for (final d in affected.docs) {
        batch.update(d.reference, {'customCategory': newName});
      }
      await batch.commit();
    }
  }

  // ── Custom locations (shared list per household) ─────────────────────────

  Stream<List<String>> locationsStream(String householdId) => _db
      .collection('households')
      .doc(householdId)
      .snapshots()
      .map((s) {
        final list =
            (s.data()?['locations'] as List?)?.cast<String>() ?? const [];
        return list..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });

  Future<void> addLocation(String householdId, String name) => _db
      .collection('households')
      .doc(householdId)
      .set({
        'locations': FieldValue.arrayUnion([name]),
      }, SetOptions(merge: true));

  Future<void> removeLocation(String householdId, String name) => _db
      .collection('households')
      .doc(householdId)
      .set({
        'locations': FieldValue.arrayRemove([name]),
      }, SetOptions(merge: true));

  // Rename a custom location and move every item that used it to the new name.
  Future<void> renameLocation(
      String householdId, String oldName, String newName) async {
    await removeLocation(householdId, oldName);
    await addLocation(householdId, newName);
    final affected = await _db
        .collection('households')
        .doc(householdId)
        .collection('items')
        .where('location', isEqualTo: oldName)
        .get();
    if (affected.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in affected.docs) {
      batch.update(d.reference, {'location': newName});
    }
    await batch.commit();
  }

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

  /// Bulk write for a screenshot import: creates [created] and overwrites
  /// [updated] (items merged into) in as few round-trips as possible.
  ///
  /// Firestore caps a batch at 500 operations, so this chunks. Chunks commit
  /// independently, which means a mid-way failure can leave a partial import —
  /// acceptable here because Undo works off the ids the caller already holds,
  /// and the alternative (a transaction) has the same 500-op limit anyway.
  Future<void> writeItemsBatch(
    String householdId, {
    List<InventoryItem> created = const [],
    List<InventoryItem> updated = const [],
  }) async {
    final ref =
        _db.collection('households').doc(householdId).collection('items');
    final ops = <void Function(WriteBatch)>[
      for (final i in created) (b) => b.set(ref.doc(i.id), i.toFirestore()),
      // merge:true so touching one item's quantity can't blank a field the
      // other phone set meanwhile — toFirestore() omits nulls, and a plain
      // set() would delete an expiry date added since this snapshot was read.
      for (final i in updated)
        (b) => b.set(ref.doc(i.id), i.toFirestore(), SetOptions(merge: true)),
    ];
    await _commitChunked(ops);
  }

  Future<void> deleteItemsBatch(
      String householdId, List<String> itemIds) async {
    final ref =
        _db.collection('households').doc(householdId).collection('items');
    await _commitChunked([
      for (final id in itemIds) (b) => b.delete(ref.doc(id)),
    ]);
  }

  static const _batchLimit = 500;

  Future<void> _commitChunked(List<void Function(WriteBatch)> ops) async {
    for (var i = 0; i < ops.length; i += _batchLimit) {
      final batch = _db.batch();
      for (final op in ops.skip(i).take(_batchLimit)) {
        op(batch);
      }
      // Offline, commit() applies locally but its future never resolves, which
      // would leave the caller spinning forever over rows already on screen.
      await batch.commit().timeout(_writeTimeout,
          onTimeout: () => throw NetworkTimeoutException());
    }
  }

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
    // Remember it in the catalog for quick reordering later. The catalog is a
    // convenience index only, so its failure must never break adding the item
    // — which is exactly what used to happen when a name held a '/'.
    try {
      await _recordCatalog(householdId, item);
    } catch (_) {}
  }

  Future<void> setShoppingChecked(
          String householdId, String itemId, bool checked) =>
      _shoppingRef(householdId).doc(itemId).update({'checked': checked});

  // Edit an existing shopping item (no catalog re-record).
  Future<void> updateShoppingItem(String householdId, ShoppingItem item) =>
      _shoppingRef(householdId).doc(item.id).set(item.toFirestore());

  Future<void> deleteShoppingItem(String householdId, String itemId) =>
      _shoppingRef(householdId).doc(itemId).delete();

  /// Bulk counterpart of [addShoppingItem] for a screenshot import. Catalog
  /// entries are still recorded (that's what makes these items reorderable),
  /// but after the batch so a slow catalog write can't hold up the list showing
  /// the new items.
  Future<void> writeShoppingBatch(
    String householdId, {
    List<ShoppingItem> created = const [],
    List<ShoppingItem> updated = const [],
  }) async {
    final ref = _shoppingRef(householdId);
    await _commitChunked([
      for (final i in created) (b) => b.set(ref.doc(i.id), i.toFirestore()),
      for (final i in updated)
        (b) => b.set(ref.doc(i.id), i.toFirestore(), SetOptions(merge: true)),
    ]);
    // Deliberately NOT awaited: 30 sequential catalog round-trips would hold the
    // Confirm button spinning long after the items are already in the list. The
    // catalog is only a reorder convenience, so a lost write costs nothing.
    for (final i in created) {
      _recordCatalog(householdId, i).catchError((_) {});
    }
  }

  Future<void> deleteShoppingBatch(
      String householdId, List<String> itemIds) async {
    final ref = _shoppingRef(householdId);
    await _commitChunked([
      for (final id in itemIds) (b) => b.delete(ref.doc(id)),
    ]);
  }

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
