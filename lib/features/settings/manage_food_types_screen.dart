import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/labels.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';

/// Manage the household's custom food types (the built-in categories are fixed).
/// Mirrors [ManageLocationsScreen] — rename reassigns every item using the type.
class ManageFoodTypesScreen extends ConsumerWidget {
  const ManageFoodTypesScreen({super.key});

  // Shared text-entry sheet for rename. A bottom sheet, not a dialog (Impeller
  // black-screens dialogs on this hardware).
  Future<String?> _promptName(
    BuildContext context, {
    required String title,
    String initial = '',
  }) {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: initial);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l.foodTypesHint,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: Text(l.commonSave),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(ctrl.dispose);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final custom = ref.watch(customCategoriesProvider).valueOrNull ?? const [];
    final hid = ref.watch(householdIdProvider);
    final svc = ref.read(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsFoodTypes)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(l.foodTypesBuiltIn,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          // Built-ins are fixed — shown greyed for reference, like locations.
          for (final c in kPickableCategories)
            ListTile(
              dense: true,
              leading: Icon(categoryIcon(c), size: 20),
              title: Text(categoryLabelOf(l, c)),
              enabled: false,
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l.foodTypesYours,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (custom.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.foodTypesEmpty),
            ),
          for (final type in custom)
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(type),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l.commonRename,
                    onPressed: hid == null
                        ? null
                        : () async {
                            final name = await _promptName(context,
                                title: l.foodTypesRename, initial: type);
                            final trimmed = name?.trim();
                            if (trimmed == null ||
                                trimmed.isEmpty ||
                                trimmed.toLowerCase() == type.toLowerCase()) {
                              return;
                            }
                            final lower = trimmed.toLowerCase();
                            // Same guard as creating a type: don't let a rename
                            // recreate a built-in clash or a duplicate custom
                            // type (which would split into look-alike groups).
                            final clash = ItemCategory.values.any(
                                    (c) => c.name.toLowerCase() == lower) ||
                                kPickableCategories.any((c) =>
                                    categoryLabelOf(l, c).toLowerCase() ==
                                    lower) ||
                                custom.any((e) =>
                                    e.toLowerCase() == lower &&
                                    e.toLowerCase() != type.toLowerCase());
                            if (clash) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l.foodTypesNameTaken)),
                                );
                              }
                              return;
                            }
                            await svc.renameCategory(hid, type, trimmed);
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: l.commonDelete,
                    onPressed: hid == null
                        ? null
                        : () async {
                            await svc.removeCategory(hid, type);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l.foodTypesRemoved(type)),
                                  action: SnackBarAction(
                                    label: l.commonUndo,
                                    onPressed: () =>
                                        svc.addCategory(hid, type),
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
