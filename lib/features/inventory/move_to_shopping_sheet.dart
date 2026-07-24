import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/labels.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';

/// Asks how much of a pantry item to move to the shopping list. Returns the
/// chosen amount (a value from just above 0 up to the full quantity), or null
/// if cancelled. Defaults to the full amount, so a straight confirm moves
/// everything — the same as the pre-existing "remove & add to shopping" action.
Future<double?> showMoveToShoppingSheet(
  BuildContext context,
  InventoryItem item,
) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MoveToShoppingSheet(item: item),
  );
}

class _MoveToShoppingSheet extends StatefulWidget {
  final InventoryItem item;
  const _MoveToShoppingSheet({required this.item});

  @override
  State<_MoveToShoppingSheet> createState() => _MoveToShoppingSheetState();
}

class _MoveToShoppingSheetState extends State<_MoveToShoppingSheet> {
  late double _qty;
  late final double _max;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _max = widget.item.quantity;
    _qty = _max; // default to moving everything
    _ctrl = TextEditingController(text: _label(_qty));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _label(double q) => q % 1 == 0 ? q.toInt().toString() : q.toString();

  void _setQty(double q) {
    var clamped = q;
    if (clamped < 0) clamped = 0;
    if (clamped > _max) clamped = _max;
    setState(() {
      _qty = clamped;
      _ctrl.text = _label(clamped);
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // 'item' is the stored key for a plain count — it gets no visible unit.
    final unit =
        widget.item.unit == 'item' ? null : unitLabelOf(l, widget.item.unit);
    final movingAll = _qty >= _max;
    final canMove = _qty > 0;
    final moveLabel =
        movingAll ? l.qtyMoveAll : l.qtyMoveAmount(_label(_qty));

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.qtyMoveTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(widget.item.name, style: TextStyle(color: scheme.outline)),
          const SizedBox(height: 4),
          Text(
            l.qtyMoveAvailable(
                '${_label(_max)}${unit == null ? '' : ' $unit'}'),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                onPressed: _qty <= 0 ? null : () => _setQty(_qty - 1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: Theme.of(context).textTheme.headlineSmall,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffixText: unit,
                  ),
                  onChanged: (v) {
                    final d = double.tryParse(v);
                    if (d == null) return;
                    // You can't move more than you have: snap the field down to
                    // the max so what's shown matches what actually moves. Values
                    // in range are left as typed so we don't fight the cursor.
                    if (d > _max) {
                      _setQty(_max);
                    } else {
                      setState(() => _qty = d < 0 ? 0 : d);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                onPressed: _qty >= _max ? null : () => _setQty(_qty + 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canMove ? () => Navigator.of(context).pop(_qty) : null,
              child: Text(moveLabel),
            ),
          ),
        ],
      ),
    );
  }
}
