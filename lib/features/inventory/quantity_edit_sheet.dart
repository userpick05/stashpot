import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_providers.dart';
import '../../models/inventory_item.dart';

/// Quick quantity editor — tap a pantry item's quantity pill to bump it up/down
/// or type a new value, without opening the full edit screen.
Future<void> showQuantityEditSheet(
  BuildContext context,
  WidgetRef ref,
  InventoryItem item,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _QuantityEditSheet(item: item),
  );
}

class _QuantityEditSheet extends ConsumerStatefulWidget {
  final InventoryItem item;
  const _QuantityEditSheet({required this.item});

  @override
  ConsumerState<_QuantityEditSheet> createState() => _QuantityEditSheetState();
}

class _QuantityEditSheetState extends ConsumerState<_QuantityEditSheet> {
  late double _qty;
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _qty = widget.item.quantity;
    _ctrl = TextEditingController(text: _label(_qty));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _label(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toString();

  void _setQty(double q) {
    final clamped = q < 0 ? 0.0 : q;
    setState(() {
      _qty = clamped;
      _ctrl.text = _label(clamped);
      _ctrl.selection =
          TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final hid = ref.read(householdIdProvider);
    if (hid != null) {
      await ref
          .read(firestoreServiceProvider)
          .updateItem(hid, widget.item.copyWith(quantity: _qty));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quantity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(widget.item.name, style: TextStyle(color: scheme.outline)),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: Theme.of(context).textTheme.headlineSmall,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffixText: widget.item.unit == 'item' ? null : widget.item.unit,
                  ),
                  onChanged: (v) {
                    final d = double.tryParse(v);
                    if (d != null) setState(() => _qty = d);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                onPressed: () => _setQty(_qty + 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }
}
