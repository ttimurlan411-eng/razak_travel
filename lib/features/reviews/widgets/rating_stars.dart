import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 22,
    this.spacing = 2,
    this.onRatingChanged,
    this.activeColor,
    this.inactiveColor,
  });

  final double rating;
  final double size;
  final double spacing;
  final ValueChanged<int>? onRatingChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedActiveColor = activeColor ?? colorScheme.tertiary;
    final resolvedInactiveColor = inactiveColor ?? colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) {
          final icon = _iconForIndex(index);
          final star = Icon(
            icon,
            size: size,
            color: icon == Icons.star_border_rounded
                ? resolvedInactiveColor
                : resolvedActiveColor,
          );

          if (onRatingChanged == null) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing),
              child: star,
            );
          }

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onRatingChanged!(index + 1),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing, vertical: 4),
              child: star,
            ),
          );
        },
      ),
    );
  }

  IconData _iconForIndex(int index) {
    final wholeStarIndex = index + 1;

    if (rating >= wholeStarIndex) {
      return Icons.star_rounded;
    }

    if (onRatingChanged == null && rating > index && rating < wholeStarIndex) {
      return Icons.star_half_rounded;
    }

    return Icons.star_border_rounded;
  }
}
