import 'package:flutter/material.dart';

/// Renders a 0–5 star rating with an optional count, e.g. ★★★★☆ (128).
class StarRating extends StatelessWidget {
  final double stars; // 0..5
  final int? count;
  final double size;

  const StarRating({super.key, required this.stars, this.count, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final full = stars.floor();
    final half = (stars - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < full
                ? Icons.star
                : (i == full && half ? Icons.star_half : Icons.star_border),
            size: size,
            color: Colors.amber.shade700,
          ),
        if (count != null) ...[
          const SizedBox(width: 4),
          Text('($count)',
              style: TextStyle(fontSize: size - 2, color: Theme.of(context).colorScheme.outline)),
        ],
      ],
    );
  }
}
