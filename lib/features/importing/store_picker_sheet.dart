import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// What the store picker came back with.
///
/// Three outcomes matter and "null" can only express one of them: picking a
/// store, deliberately choosing *no* store, and backing out without changing
/// anything. Conflating the last two would make it impossible to clear a store
/// the scan guessed wrong.
class StorePick {
  /// Null means "no store". Only meaningful when [changed] is true.
  final String? store;
  final bool changed;

  /// The row should go back to following the screen-wide store. Without this
  /// there is no way out of a per-row override, so "set the store for all
  /// items" would silently skip any row that had ever been touched.
  final bool inherit;

  const StorePick(this.store) : changed = true, inherit = false;
  const StorePick.cancelled() : store = null, changed = false, inherit = false;
  const StorePick.inherit() : store = null, changed = true, inherit = true;
}

/// Pick a store from the household's saved list, type a new one, or clear it.
///
/// A bottom sheet rather than a dialog — AlertDialogs black-screen via Impeller
/// on this hardware.
Future<StorePick> showStorePicker(
  BuildContext context, {
  required List<String> savedStores,
  String? current,
  required String title,

  /// When set, offers "use the list's store" — only meaningful for a single row.
  String? inheritFrom,
  bool canInherit = false,
}) async {
  final controller = TextEditingController(text: current ?? '');
  final result = await showModalBottomSheet<StorePick>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final l = AppLocalizations.of(ctx);
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          // Scrollable so a large system font size can't push the buttons
          // off the bottom of the sheet.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l.addItemStoreLabel,
                    hintText: l.addItemStoreHint,
                  ),
                  onSubmitted: (v) => Navigator.pop(
                    ctx,
                    StorePick(v.trim().isEmpty ? null : v.trim()),
                  ),
                ),
                const SizedBox(height: 8),
                if (savedStores.isNotEmpty) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l.importPickSavedStore,
                      style: Theme.of(ctx).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Constrained so a long store list can't push the buttons off
                  // screen with the keyboard up.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in savedStores)
                            ActionChip(
                              avatar: const Icon(Icons.storefront, size: 16),
                              label: Text(s),
                              onPressed: () => Navigator.pop(ctx, StorePick(s)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (canInherit)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: TextButton.icon(
                      icon: const Icon(Icons.link, size: 18),
                      label: Text(
                        inheritFrom == null
                            ? l.importStoreUseListNone
                            : l.importStoreUseList(inheritFrom),
                      ),
                      onPressed: () =>
                          Navigator.pop(ctx, const StorePick.inherit()),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.block, size: 18),
                        label: Text(l.importStoreNone),
                        onPressed: () =>
                            Navigator.pop(ctx, const StorePick(null)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final v = controller.text.trim();
                          Navigator.pop(ctx, StorePick(v.isEmpty ? null : v));
                        },
                        child: Text(l.commonSave),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  // Disposed after the exit animation, not on pop: the TextField is still
  // mounted while the sheet slides out, and dropping focus with an active IME
  // composing region (routine for Chinese input) writes to the controller.
  WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  return result ?? const StorePick.cancelled();
}
