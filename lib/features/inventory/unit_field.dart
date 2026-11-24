import 'package:flutter/material.dart';

import '../../core/utils/labels.dart';
import '../../l10n/app_localizations.dart';

/// A typable unit field with the common units (and the household's own custom
/// units) as quick-pick chips. The user can type anything — "dozen", "pack" —
/// and the parent remembers a new one on save (see [customUnits]).
class UnitField extends StatefulWidget {
  final String value;
  final List<String> customUnits;
  final ValueChanged<String> onChanged;

  const UnitField({
    super.key,
    required this.value,
    required this.customUnits,
    required this.onChanged,
  });

  @override
  State<UnitField> createState() => _UnitFieldState();
}

class _UnitFieldState extends State<UnitField> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant UnitField old) {
    super.didUpdateWidget(old);
    // Keep the field in step if the parent sets the unit elsewhere (e.g. an
    // identify-by-photo prefill), without fighting the cursor mid-type.
    if (widget.value != _ctrl.text && widget.value != old.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _select(String unit) {
    setState(() {
      _ctrl.text = unit;
      _ctrl.selection = TextSelection.collapsed(offset: unit.length);
    });
    widget.onChanged(unit);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Built-ins first, then custom units not already covered by a built-in.
    final chips = <String>[
      ...kBuiltInUnits,
      ...widget.customUnits.where((u) =>
          u.trim().isNotEmpty && !kBuiltInUnits.contains(u)),
    ];
    final current = _ctrl.text.trim().toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _ctrl,
          decoration: InputDecoration(
            labelText: l.addItemUnitLabel,
            hintText: l.addItemUnitHint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) {
            widget.onChanged(v);
            setState(() {}); // re-evaluate which quick-pick is highlighted
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 0,
          children: [
            for (final u in chips)
              ChoiceChip(
                label: Text(unitLabelOf(l, u)),
                selected: u.toLowerCase() == current,
                onSelected: (_) => _select(u),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}
