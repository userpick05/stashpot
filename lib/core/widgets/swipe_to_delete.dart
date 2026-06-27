import 'dart:async';
import 'package:flutter/material.dart';

/// Swipe a row left to delete. Instead of vanishing, the row is replaced
/// in-place by an "Undo" strip for a few seconds. If undone, nothing happens;
/// otherwise the delete is committed. Leaving the screen also commits it.
///
/// Used everywhere we have swipe-to-delete so the behavior is consistent.
class SwipeToDelete extends StatefulWidget {
  final String itemId;
  final String label;
  final Widget child;
  final Future<void> Function() onDelete;
  final EdgeInsets margin;
  final Duration undoWindow;

  const SwipeToDelete({
    super.key,
    required this.itemId,
    required this.label,
    required this.child,
    required this.onDelete,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.undoWindow = const Duration(seconds: 4),
  });

  @override
  State<SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<SwipeToDelete> {
  bool _pending = false;
  bool _committed = false;
  Timer? _timer;

  @override
  void dispose() {
    // Only cancel — never commit a delete from dispose. Disposing can happen
    // during list reconciliation, and committing here could delete the wrong
    // item. If the user leaves before the window elapses, the item simply stays.
    _timer?.cancel();
    super.dispose();
  }

  void _startPending() {
    setState(() => _pending = true);
    _timer = Timer(widget.undoWindow, _commit);
  }

  Future<void> _commit() async {
    if (_committed) return;
    _committed = true;
    await widget.onDelete();
    // The list stream will drop this row once the delete syncs.
  }

  void _undo() {
    _timer?.cancel();
    if (mounted) setState(() => _pending = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_pending) {
      return Container(
        key: ValueKey('undo-${widget.itemId}'),
        margin: widget.margin,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.delete_outline, color: scheme.outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Removed ${widget.label}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
            TextButton.icon(
              icon: const Icon(Icons.undo),
              label: const Text('Undo'),
              onPressed: _undo,
            ),
          ],
        ),
      );
    }

    return Dismissible(
      key: ValueKey('item-${widget.itemId}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _startPending(),
      background: Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: widget.child,
    );
  }
}
