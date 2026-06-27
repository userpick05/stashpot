import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows the household invite code in a bottom sheet (not an AlertDialog —
/// dialogs black-screen via Impeller on some devices, e.g. Pixel 10).
void showInviteCodeSheet(BuildContext context, String code) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite your partner',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text('Share this code so they can join your pantry. They '
                'register their own account, then enter it under "Join an '
                'existing household".'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(code,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 16)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy code'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied')),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
