import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/labels.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';

/// Manage the household's custom pantry locations (the four built-ins are fixed).
class ManageLocationsScreen extends ConsumerWidget {
  const ManageLocationsScreen({super.key});

  // Shared text-entry sheet for add/rename. Returns the entered name or null.
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
                hintText: l.locationsHint,
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
    final custom = ref.watch(customLocationsProvider).valueOrNull ?? const [];
    final hid = ref.watch(householdIdProvider);
    final svc = ref.read(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsPantryLocations)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(l.locationsBuiltIn,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final k in kBuiltInLocationKeys)
            ListTile(
              leading: Icon(locationIcon(k)),
              title: Text(locationLabelOf(l, k)),
              enabled: false,
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l.locationsYours,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (custom.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.locationsEmpty),
            ),
          for (final loc in custom)
            ListTile(
              leading: Icon(locationIcon(loc)),
              title: Text(loc),
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
                                title: l.locationsRename, initial: loc);
                            final trimmed = name?.trim();
                            if (trimmed != null &&
                                trimmed.isNotEmpty &&
                                trimmed != loc) {
                              await svc.renameLocation(hid, loc, trimmed);
                            }
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: l.commonDelete,
                    onPressed: hid == null
                        ? null
                        : () async {
                            await svc.removeLocation(hid, loc);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l.locationsRemoved(loc)),
                                  action: SnackBarAction(
                                    label: l.commonUndo,
                                    onPressed: () => svc.addLocation(hid, loc),
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 88),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: hid == null
            ? null
            : () async {
                final name =
                    await _promptName(context, title: l.locationsNew);
                final trimmed = name?.trim();
                if (trimmed != null && trimmed.isNotEmpty) {
                  await svc.addLocation(hid, trimmed);
                }
              },
        icon: const Icon(Icons.add),
        label: Text(l.locationsAdd),
      ),
    );
  }
}
