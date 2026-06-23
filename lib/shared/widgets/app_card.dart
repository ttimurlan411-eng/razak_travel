import 'package:flutter/material.dart';
import 'package:razak_travel/shared/widgets/dynamic_glass.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 28,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return DynamicGlass(
      onTap: onTap,
      padding: padding,
      borderRadius: borderRadius,
      blur: 22,
      child: child,
    );
  }
}
