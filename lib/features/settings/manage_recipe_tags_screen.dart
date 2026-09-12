import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/recipe_providers.dart';
import '../../core/utils/recipe_tags.dart';
import '../../l10n/app_localizations.dart';

/// Manage the household's custom recipe tags (the built-in tags are fixed).
/// Mirrors [ManageFoodTypesScreen] — rename reassigns every recipe using it.
class ManageRecipeTagsScreen extends ConsumerWidget {
  const ManageRecipeTagsScreen({super.key});

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
                hintText: l.recipeTagsAddHint,
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
    final custom = ref.watch(customRecipeTagsProvider).valueOrNull ?? const [];
    final hid = ref.watch(householdIdProvider);
    final svc = ref.read(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsRecipeTags)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(l.recipeTagsBuiltIn,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          // Built-ins are fixed — shown greyed for reference, like food types.
          for (final k in kRecipeTagKeys)
            ListTile(
              dense: true,
              leading: const Icon(Icons.sell_outlined, size: 20),
              title: Text(recipeTagLabelOf(l, k)),
              enabled: false,
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l.recipeTagsYours,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (custom.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.recipeTagsEmpty),
            ),
          for (final tag in custom)
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(tag),
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
                                title: l.recipeTagsRename, initial: tag);
                            final trimmed = name?.trim();
                            if (trimmed == null ||
                                trimmed.isEmpty ||
                                trimmed.toLowerCase() == tag.toLowerCase()) {
                              return;
                            }
                            final lower = trimmed.toLowerCase();
                            // Don't let a rename recreate a built-in clash or a
                            // duplicate custom tag (look-alike groups).
                            final clash = kRecipeTagKeys.any((k) =>
                                    k == lower ||
                                    recipeTagLabelOf(l, k).toLowerCase() ==
                                        lower) ||
                                custom.any((e) =>
                                    e.toLowerCase() == lower &&
                                    e.toLowerCase() != tag.toLowerCase());
                            if (clash) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(l.recipeTagsNameTaken)),
                                );
                              }
                              return;
                            }
                            try {
                              await svc.renameRecipeTag(hid, tag, trimmed);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l.commonError(e.toString()))),
                                );
                              }
                            }
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: l.commonDelete,
                    onPressed: hid == null
                        ? null
                        : () async {
                            await svc.removeRecipeTag(hid, tag);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l.recipeTagsRemoved(tag)),
                                  action: SnackBarAction(
                                    label: l.commonUndo,
                                    onPressed: () => svc.addRecipeTag(hid, tag),
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
