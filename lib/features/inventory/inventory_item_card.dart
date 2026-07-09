import 'package:flutter/material.dart';
import '../../core/utils/category_icons.dart';
import '../../core/widgets/image_view_sheet.dart';
import '../../models/inventory_item.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  // Shown after the quantity — the dimension NOT used for the section header.
  final String secondaryLabel;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  // When provided, a "⋮" menu offers sending this item to the shopping list.
  final VoidCallback? onAddToShopping;
  // Sends to the shopping list AND removes it from the pantry.
  final VoidCallback? onRemoveToShopping;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.secondaryLabel,
    this.onDelete,
    this.onTap,
    this.onAddToShopping,
    this.onRemoveToShopping,
  });

  Color _expiryColor(BuildContext context) {
    if (item.isExpired) return Colors.red;
    if (item.expiresSoon) return Colors.orange;
    if (item.expiresThisWeek) return Colors.amber;
    return Colors.green;
  }

  String _expiryLabel() {
    final days = item.daysUntilExpiry;
    if (days == null) return '';
    if (days < 0) return 'Expired ${(-days)} day${(-days) == 1 ? '' : 's'} ago';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    return 'Expires in $days days';
  }

  @override
  Widget build(BuildContext context) {
    final hasExpiry = item.expiryDate != null;
    final qty = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(categoryIcon(item.category),
              color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$qty ${item.unit}  ·  $secondaryLabel'),
            if (hasExpiry)
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4, top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _expiryColor(context),
                    ),
                  ),
                  Text(
                    _expiryLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isExpired || item.expiresSoon ? _expiryColor(context) : null,
                      fontWeight: item.isExpired ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: onAddToShopping != null
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More',
                onSelected: (v) {
                  if (v == 'shopping') onAddToShopping!.call();
                  if (v == 'move') onRemoveToShopping?.call();
                  if (v == 'photo' && item.imageUrl != null) {
                    showImageSheet(context, item.imageUrl!);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'shopping',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.add_shopping_cart),
                      title: Text('Add to shopping list'),
                    ),
                  ),
                  if (onRemoveToShopping != null)
                    const PopupMenuItem(
                      value: 'move',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.move_up),
                        title: Text('Remove from pantry & add to shopping list'),
                      ),
                    ),
                  if (item.imageUrl != null)
                    const PopupMenuItem(
                      value: 'photo',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.image_outlined),
                        title: Text('View photo'),
                      ),
                    ),
                ],
              )
            : item.imageUrl != null
                ? IconButton(
                    icon: Icon(Icons.image_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    tooltip: 'View photo',
                    onPressed: () => showImageSheet(context, item.imageUrl!),
                  )
                : (onDelete != null
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: onDelete,
                      )
                    : null),
        isThreeLine: hasExpiry,
      ),
    );
  }
}
