import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/scanning_providers.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/labels.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';
import '../../models/scanned_item.dart';
import '../../models/shopping_item.dart';
import 'store_picker_sheet.dart';

/// Reads the picked screenshots, then lets the user review before anything is
/// written.
///
/// Nothing is saved until they confirm, because OCR gets things wrong and a bad
/// bulk import is tedious to unpick. Every row can be unchecked, edited, or sent
/// somewhere other than the master destination — the common real case being "I
/// got most of this order (→ pantry) but two things were out of stock
/// (→ shopping list)".
class ImportReviewScreen extends ConsumerStatefulWidget {
  final List<XFile> images;

  /// Where the flow was launched from, used as the initial master destination.
  final ImportDestination initialDestination;

  const ImportReviewScreen({
    super.key,
    required this.images,
    required this.initialDestination,
  });

  @override
  ConsumerState<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends ConsumerState<ImportReviewScreen> {
  List<ScannedItem> _items = [];
  String? _store;
  late ImportDestination _master;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  /// True once the user has set the store themselves, so a later scan result
  /// can't quietly overwrite their choice.
  bool _storeChosen = false;

  /// How each row resolved to a target document on the FIRST confirm attempt.
  ///
  /// Retry safety hinges on this. A commit that times out has still been applied
  /// to the local Firestore cache, so re-reading `_pantryMatch` on a retry would
  /// find the row's own just-written document and treat its new quantity as the
  /// base — doubling it. Because the write sets an ABSOLUTE quantity, replaying
  /// it with the same base is idempotent; so the base is captured once and
  /// reused for the life of this screen.
  final Map<ScannedItem, _Resolved> _plan = {};

  @override
  void initState() {
    super.initState();
    _master = widget.initialDestination;
    // Deferred a frame: reading the locale needs Localizations, which isn't
    // available during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scan();
    });
  }

  Future<void> _scan() async {
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = <Uint8List>[];
      for (final x in widget.images) {
        bytes.add(await x.readAsBytes());
      }
      final result = await ref
          .read(shoppingScanServiceProvider)
          .scan(bytes, languageCode: lang);
      if (!mounted) return;
      final seen = <String, ScannedItem>{};
      for (final item in result.items) {
        final key = item.productKey;
        final first = seen[key];
        if (first != null) {
          first.duplicateInScan = true;
          item.duplicateInScan = true;
          // Keep the first, uncheck the repeat — summing two readings of what is
          // probably one line is the error the prompt explicitly forbids.
          item.selected = false;
        } else {
          seen[key] = item;
        }
      }
      for (final item in result.items) {
        // Anything that would MERGE into an existing item, or whose quantity we
        // guessed, starts unchecked — those are the two cases where a careless
        // confirm silently changes a number the user can't easily recover.
        if (item.quantityAssumed ||
            _pantryMatch(item) != null ||
            _shoppingMatch(item) != null) {
          item.selected = false;
        }
      }
      setState(() {
        _items = result.items;
        // Don't clobber a store the user picked before retrying the scan.
        if (!_storeChosen) _store = result.store;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ScannedItem> get _selected => _items.where((i) => i.selected).toList();

  ImportDestination _destOf(ScannedItem i) => i.destination ?? _master;

  /// Same rule the shopping→pantry move uses: name AND note together identify a
  /// product, so two sizes of the same thing stay separate.
  static bool _sameProduct(String aName, String? aNote, String bName, String? bNote) =>
      aName.trim().toLowerCase() == bName.trim().toLowerCase() &&
      (aNote ?? '').trim().toLowerCase() == (bNote ?? '').trim().toLowerCase();

  InventoryItem? _pantryMatch(ScannedItem s) {
    for (final i in ref.read(inventoryProvider).valueOrNull ?? const []) {
      if (_sameProduct(s.name, s.note, i.name, i.notes)) return i;
    }
    return null;
  }

  ShoppingItem? _shoppingMatch(ScannedItem s) {
    for (final i in ref.read(shoppingProvider).valueOrNull ?? const []) {
      if (_sameProduct(s.name, s.note, i.name, i.note)) return i;
    }
    return null;
  }

  Future<void> _editRow(ScannedItem item) async {
    final l = AppLocalizations.of(context);
    final nameC = TextEditingController(text: item.name);
    final noteC = TextEditingController(text: item.note ?? '');
    var pendingCategory = item.category;
    final qtyC = TextEditingController(
        text: item.quantity == item.quantity.roundToDouble()
            ? item.quantity.toInt().toString()
            : item.quantity.toString());

    // Bottom sheet, not a dialog — AlertDialogs black-screen via Impeller here.
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.importEditTitle,
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: nameC,
              autofocus: true,
              decoration: InputDecoration(labelText: l.addItemNameLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteC,
              decoration: InputDecoration(labelText: l.addItemNotesLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyC,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.addItemQuantityLabel),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ItemCategory>(
              initialValue: item.category,
              decoration: InputDecoration(labelText: l.addItemFoodTypeLabel),
              items: [
                // Legacy values (e.g. produce) aren't offered to new items, but
                // must appear when a row already has one — otherwise the sheet
                // displays a category the row doesn't have.
                for (final c in {...kPickableCategories, item.category})
                  DropdownMenuItem(
                    value: c,
                    child: Row(children: [
                      Icon(categoryIcon(c), size: 18),
                      const SizedBox(width: 8),
                      Text(categoryLabelOf(l, c)),
                    ]),
                  ),
              ],
              onChanged: (v) => pendingCategory = v ?? pendingCategory,
            ),
            const SizedBox(height: 8),
            // Per-item store, for when one thing came from somewhere else than
            // the rest of the list.
            // Applied straight away rather than on Save: the tile opens its own
            // sheet, which trains swipe-to-close, and a swipe would otherwise
            // discard a change the subtitle already showed as made.
            StatefulBuilder(
              builder: (innerCtx, setSheetState) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.storefront),
                title: Text(l.addItemStoreLabel),
                subtitle: Text(item.effectiveStore(_store) ?? l.importStoreNone),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () async {
                  final inherited = _store;
                  final pick = await showStorePicker(
                    innerCtx,
                    savedStores:
                        ref.read(storesProvider).valueOrNull ?? const [],
                    current: item.effectiveStore(_store),
                    title: l.importStoreRowTitle,
                    canInherit: item.storeOverridden,
                    inheritFrom: inherited,
                  );
                  if (!pick.changed || !innerCtx.mounted) return;
                  setState(() {
                    if (pick.inherit || pick.store == inherited) {
                      // Matching the list's store means "follow the list", not
                      // "pin to this value" — otherwise a curious tap on Save
                      // would strand the row when the list store later changes.
                      item.clearStoreOverride();
                    } else {
                      item.overrideStore(pick.store);
                    }
                  });
                  setSheetState(() {});
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.commonSave),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final name = nameC.text.trim();
      final note = noteC.text.trim();
      final qty = double.tryParse(qtyC.text.trim());
      setState(() {
        if (name.isNotEmpty) item.name = name;
        item.note = note.isEmpty ? null : note;
        if (qty != null && qty > 0) item.quantity = qty;
        item.category = pendingCategory;
        // They've now read and confirmed this row, so the "check me" flags go.
        item.partial = false;
        item.quantityAssumed = false;
        // A rename can make the row newly collide with something, so the cached
        // resolution and duplicate flag are no longer trustworthy.
        _plan.remove(item);
        item.duplicateInScan = _items.any((o) =>
            o != item && o.productKey == item.productKey);
      });
    }
    nameC.dispose();
    noteC.dispose();
    qtyC.dispose();
  }

  Future<void> _changeStore() async {
    final l = AppLocalizations.of(context);
    final pick = await showStorePicker(
      context,
      savedStores: ref.read(storesProvider).valueOrNull ?? const [],
      current: _store,
      title: l.importStoreAllTitle,
    );
    if (!pick.changed || !mounted) return;
    setState(() {
      _store = pick.store;
      _storeChosen = true;
    });
  }

  /// Resolves a row to its target document, remembering the answer so a retry
  /// reuses it. Re-resolves only if the user changed the row's destination,
  /// which is a genuinely new intent.
  _Resolved _resolve(ScannedItem s) {
    final dest = _destOf(s);
    final cached = _plan[s];
    if (cached != null && cached.destination == dest) return cached;
    final existingItem = dest == ImportDestination.pantry ? _pantryMatch(s) : null;
    final existingShop =
        dest == ImportDestination.shopping ? _shoppingMatch(s) : null;
    return _plan[s] = _Resolved(
      destination: dest,
      pantryItem: existingItem,
      shoppingItem: existingShop,
      baseQuantity: existingItem?.quantity ?? existingShop?.quantity ?? 0,
    );
  }

  Future<void> _confirm() async {
    final hid = ref.read(householdIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    final chosen = _selected;
    final l = AppLocalizations.of(context);
    if (chosen.isEmpty) return;
    if (hid == null || uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.importNotSignedIn)));
      return;
    }

    setState(() => _saving = true);
    final svc = ref.read(firestoreServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final store = _store;
    final now = DateTime.now();

    // Rows are coalesced by TARGET before anything is written. Two rows landing
    // on one document — the model missing a dedupe, or the user editing two
    // names to match — would otherwise become two writes to the same doc in one
    // batch, where the last silently wins and a quantity is lost. This is the
    // same hazard `_moveCheckedToPantry` guards with its runningQty map.
    final pantryOps = <String, _Op<InventoryItem>>{};
    final shoppingOps = <String, _Op<ShoppingItem>>{};

    for (final s in chosen) {
      final resolved = _resolve(s);
      if (resolved.destination == ImportDestination.pantry) {
        final existing = resolved.pantryItem;
        final key = existing?.id ?? 'new|${s.productKey}';
        final op = pantryOps[key];
        if (op != null) {
          op.quantity += s.quantity;
          // Share the group's document id so unchecking one row and retrying
          // still targets the same doc instead of creating a second one.
          s.docId ??= op.docId;
          continue;
        }
        // Minted here, not inside build(): build runs after the loop, too late
        // for a coalescing row to pick the id up. Reused across retries so a
        // second attempt overwrites its own document instead of duplicating.
        final docId = existing == null ? (s.docId ??= const Uuid().v4()) : null;
        pantryOps[key] = _Op<InventoryItem>(
          existing: existing,
          baseQuantity: resolved.baseQuantity,
          quantity: s.quantity,
          docId: docId,
          build: (qty) => existing != null
              ? existing.copyWith(quantity: qty)
              : InventoryItem(
                  id: docId!,
                  name: s.name,
                  category: s.category,
                  quantity: qty,
                  unit: 'item',
                  location: s.suggestedLocation,
                  notes: s.note,
                  store: s.effectiveStore(store),
                  addedAt: now,
                  addedBy: uid,
                ),
        );
      } else {
        final existing = resolved.shoppingItem;
        final key = existing?.id ?? 'new|${s.productKey}';
        final op = shoppingOps[key];
        if (op != null) {
          op.quantity += s.quantity;
          s.docId ??= op.docId;
          continue;
        }
        final docId = existing == null ? (s.docId ??= const Uuid().v4()) : null;
        shoppingOps[key] = _Op<ShoppingItem>(
          existing: existing,
          baseQuantity: resolved.baseQuantity,
          quantity: s.quantity,
          docId: docId,
          build: (qty) => existing != null
              ? existing.copyWith(quantity: qty)
              : ShoppingItem(
                  id: docId!,
                  name: s.name,
                  store: s.effectiveStore(store),
                  quantity: qty,
                  note: s.note,
                  checked: false,
                  addedAt: now,
                  addedBy: uid,
                ),
        );
      }
    }

    final createItems = <InventoryItem>[], updateItems = <InventoryItem>[];
    final restoreItems = <InventoryItem>[], newItemIds = <String>[];
    for (final op in pantryOps.values) {
      final built = op.build(op.baseQuantity + op.quantity);
      if (op.existing != null) {
        updateItems.add(built);
        restoreItems.add(op.existing!);
      } else {
        createItems.add(built);
        newItemIds.add(built.id);
      }
    }
    final createShopping = <ShoppingItem>[], updateShopping = <ShoppingItem>[];
    final restoreShopping = <ShoppingItem>[], newShoppingIds = <String>[];
    for (final op in shoppingOps.values) {
      final built = op.build(op.baseQuantity + op.quantity);
      if (op.existing != null) {
        updateShopping.add(built);
        restoreShopping.add(op.existing!);
      } else {
        createShopping.add(built);
        newShoppingIds.add(built.id);
      }
    }

    // Reversing the import, offered even when the write only half-landed —
    // chunks commit independently, so a failure can still leave rows behind.
    Future<void> undo() async {
      await svc.deleteItemsBatch(hid, newItemIds);
      await svc.deleteShoppingBatch(hid, newShoppingIds);
      // Merged rows weren't created, so put their original quantities back.
      await svc.writeItemsBatch(hid, updated: restoreItems);
      await svc.writeShoppingBatch(hid, updated: restoreShopping);
    }

    // Only rows that CREATE an item carry a store: the merge path keeps the
    // existing item's store rather than rewriting its provenance, so a merged
    // row's store is never actually filed anywhere.
    final newRows = [for (final r in chosen) if (_resolve(r).isCreate) r];

    // Registering the stores keeps grouping from fragmenting into "Meijer" and
    // "meijer", but it is a nicety — never awaited, so it can't abort or stall
    // the import it decorates.
    final known = ref.read(storesProvider).valueOrNull ?? const <String>[];
    // Case-folded, keeping the first spelling: two spellings in ONE import both
    // pass the "already known" check, and arrayUnion would then add both —
    // producing two store headers for one shop, the exact fragmentation this
    // is here to prevent.
    final used = <String, String>{};
    for (final row in newRows) {
      final st = row.effectiveStore(store)?.trim();
      if (st != null && st.isNotEmpty) used.putIfAbsent(st.toLowerCase(), () => st);
    }
    used.removeWhere((lower, _) => known.any((x) => x.toLowerCase() == lower));
    for (final st in used.values) {
      svc.addStore(hid, st).catchError((_) {});
    }

    var failed = false;
    try {
      await svc.writeItemsBatch(hid,
          created: createItems, updated: updateItems);
      await svc.writeShoppingBatch(hid,
          created: createShopping, updated: updateShopping);
    } catch (e) {
      failed = true;
      if (!mounted) return;
      setState(() => _saving = false);
      _showResult(messenger, l.importPartialFailure('$e'), l.commonUndo, undo);
      return;
    }

    if (!mounted || failed) return;
    navigator.pop();
    final toPantry = createItems.length + updateItems.length;
    final toShopping = createShopping.length + updateShopping.length;
    final merged = updateItems.length + updateShopping.length;
    // Only name the destinations that actually received something — "0 to
    // shopping" is noise on a pantry-only import.
    final body = toPantry == 0
        ? l.importAddedShopping(toShopping)
        : toShopping == 0
            ? l.importAddedPantry(toPantry)
            : l.importAdded(toPantry, toShopping);
    _showResult(
      messenger,
      merged == 0 ? body : '$body${l.importMergedSuffix(merged)}',
      l.commonUndo,
      undo,
    );
  }

  /// A SnackBar shown in the same beat as a route pop can miss the callback that
  /// arms its auto-dismiss timer and stay on screen forever — a bug this app has
  /// already been bitten by twice. Post-frame plus an explicit close backstop is
  /// the established fix (see core/utils/shopping_actions.dart).
  static void _showResult(ScaffoldMessengerState messenger, String text,
      String undoLabel, Future<void> Function() undo) {
    const shown = Duration(seconds: 8);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger.hideCurrentSnackBar();
      final controller = messenger.showSnackBar(SnackBar(
        duration: shown,
        content: Text(text),
        action: SnackBarAction(
          label: undoLabel,
          onPressed: () {
            // Fire and forget: the snackbar is gone by the time this resolves,
            // and the lists update themselves from their streams.
            undo().catchError((_) {});
          },
        ),
      ));
      Future.delayed(
          shown + const Duration(milliseconds: 300), controller.close);
    });
  }



  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final selectedCount = _selected.length;
    // Watched so duplicate badges settle as soon as the streams arrive.
    ref.watch(inventoryProvider);
    ref.watch(shoppingProvider);

    if (_loading || _error != null || _items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l.importReviewTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _loading
                  ? [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(l.importReading, textAlign: TextAlign.center),
                    ]
                  : [
                      Icon(_error != null ? Icons.wifi_off : Icons.image_search,
                          size: 44),
                      const SizedBox(height: 12),
                      Text(
                        _error != null
                            ? l.importFailed(_error!)
                            : l.importNothingFound,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _scan,
                        icon: const Icon(Icons.refresh),
                        label: Text(l.commonRetry),
                      ),
                    ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.importReviewTitle),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () => setState(() {
                      final turnOn = selectedCount < _items.length;
                      for (final i in _items) {
                        i.selected = turnOn;
                      }
                    }),
            child: Text(selectedCount < _items.length
                ? l.importSelectAll
                : l.importSelectNone),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Master destination ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<ImportDestination>(
              segments: [
                ButtonSegment(
                  value: ImportDestination.shopping,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(l.importToShopping),
                ),
                ButtonSegment(
                  value: ImportDestination.pantry,
                  icon: const Icon(Icons.kitchen_outlined),
                  label: Text(l.importToPantry),
                ),
              ],
              selected: {_master},
              onSelectionChanged: _saving
                  ? null
                  // Per-row overrides are deliberately KEPT: a row-level choice
                  // is more specific than the master, and silently wiping the
                  // four rows a user just flipped is unrecoverable work.
                  : (s) => setState(() => _master = s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Say plainly that a machine read this. The review step tells
                // the user TO check; this tells them WHY, same as the recipe
                // screen's translation notice.
                Row(children: [
                  Icon(Icons.auto_awesome,
                      size: 14, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.importAiDisclosure,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                // The scan's guess is a starting point, not a verdict — a promo
                // banner or the wrong app in shot can name the wrong retailer,
                // and every row inherits it.
                Row(children: [
                  Expanded(
                    child: Text(
                      _store == null
                          ? l.importStoreNoneSet
                          : l.importFromStore(_store!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _saving ? null : _changeStore,
                    icon: const Icon(Icons.storefront, size: 16),
                    label: Text(
                        _store == null ? l.importStoreSet : l.importStoreChange),
                  ),
                ]),
                Text(
                  l.importTapRowToChange,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final dest = _destOf(item);
                final dup = dest == ImportDestination.pantry
                    ? _pantryMatch(item)?.quantity
                    : _shoppingMatch(item)?.quantity;

                return CheckboxListTile(
                  // Keyed on identity, not the label — the name is editable.
                  key: ObjectKey(item),
                  value: item.selected,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => item.selected = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  isThreeLine: dup != null ||
                      item.quantityAssumed ||
                      item.partial ||
                      item.duplicateInScan,
                  title: Row(
                    children: [
                      Expanded(child: Text(item.name)),
                      if (item.quantity != 1 || item.quantityAssumed)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text('×${_qtyLabel(item.quantity)}',
                              style: Theme.of(context).textTheme.titleSmall),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.note != null) Text(item.note!),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Chip(
                            icon: dest == ImportDestination.pantry
                                ? Icons.kitchen_outlined
                                : Icons.shopping_cart_outlined,
                            label: dest == ImportDestination.pantry
                                ? l.importToPantry
                                : l.importToShopping,
                            onTap: _saving
                                ? null
                                : () => setState(() => item.destination =
                                    dest == ImportDestination.pantry
                                        ? ImportDestination.shopping
                                        : ImportDestination.pantry),
                          ),
                          if (dup != null)
                            _Chip(
                              icon: Icons.merge_type,
                              // Spell out the outcome: "2 → 4" is legible where
                              // "already have 2" has to be reasoned about.
                              label: l.importWillMerge(_qtyLabel(dup),
                                  _qtyLabel(dup + item.quantity)),
                              tone: _ChipTone.warning,
                            ),
                          if (item.partial)
                            _Chip(
                              icon: Icons.crop,
                              label: l.importPartialRow,
                              tone: _ChipTone.warning,
                            ),
                          if (item.duplicateInScan)
                            _Chip(
                              icon: Icons.content_copy,
                              label: l.importRepeatedRow,
                              tone: _ChipTone.warning,
                            ),
                          // Only when this row differs from the screen's store,
                          // otherwise it is noise on every single row.
                          if (item.storeOverridden &&
                              item.effectiveStore(_store) != _store)
                            _Chip(
                              icon: Icons.storefront,
                              label: item.store ?? l.importStoreNone,
                            ),
                          if (item.quantityAssumed)
                            _Chip(
                              icon: Icons.help_outline,
                              label: l.importQuantityUnsure,
                              tone: _ChipTone.warning,
                            ),
                        ],
                      ),
                    ],
                  ),
                  secondary: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l.importEditTitle,
                    onPressed: _saving ? null : () => _editRow(item),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _saving || selectedCount == 0 ? null : _confirm,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.playlist_add_check),
                label: Text(_confirmLabel(l, selectedCount)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Add 9 to pantry, 3 to shopping" beats "Add 12 items" — the destinations
  /// are the whole point of this screen.
  String _confirmLabel(AppLocalizations l, int count) {
    if (count == 0) return l.importNothingSelected;
    final toPantry = _selected
        .where((i) => _destOf(i) == ImportDestination.pantry)
        .length;
    final toShopping = count - toPantry;
    if (toPantry == 0) return l.importConfirmShopping(toShopping);
    if (toShopping == 0) return l.importConfirmPantry(toPantry);
    return l.importConfirmBoth(toPantry, toShopping);
  }

  static String _qtyLabel(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}

/// A row's resolved target, captured once so retries stay idempotent.
class _Resolved {
  final ImportDestination destination;
  final InventoryItem? pantryItem;
  final ShoppingItem? shoppingItem;
  final double baseQuantity;

  /// No existing item matched, so this row will create a document — the only
  /// case where the row's store is actually written anywhere.
  bool get isCreate => pantryItem == null && shoppingItem == null;

  const _Resolved({
    required this.destination,
    this.pantryItem,
    this.shoppingItem,
    required this.baseQuantity,
  });
}

/// One pending write, keyed by its target document so several scanned rows that
/// resolve to the same item accumulate instead of overwriting each other.
class _Op<T> {
  final T? existing;
  final double baseQuantity;
  double quantity;
  final T Function(double totalQuantity) build;

  /// Set for creates, so other rows folded into this op can reuse the same id.
  String? docId;

  _Op({
    required this.existing,
    required this.baseQuantity,
    required this.quantity,
    required this.build,
    this.docId,
  });
}

enum _ChipTone { neutral, warning }

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final _ChipTone tone;

  const _Chip({
    required this.icon,
    required this.label,
    this.onTap,
    this.tone = _ChipTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = tone == _ChipTone.warning ? scheme.error : scheme.onSurfaceVariant;
    final bg = tone == _ChipTone.warning
        ? scheme.errorContainer.withValues(alpha: 0.4)
        : scheme.surfaceContainerHighest;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: fg)),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.swap_horiz, size: 13, color: fg),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: chip,
    );
  }
}
