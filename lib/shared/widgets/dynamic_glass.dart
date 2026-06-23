import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DynamicGlass extends StatefulWidget {
  const DynamicGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 28,
    this.blur = 20,
    this.opacity = 1,
    this.onTap,
    this.borderColor,
    this.shadowColor,
    this.gradientColors,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double blur;
  final double opacity;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? shadowColor;
  final List<Color>? gradientColors;

  @override
  State<DynamicGlass> createState() => _DynamicGlassState();
}

class _DynamicGlassState extends State<DynamicGlass>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _reflectionController;

  @override
  void initState() {
    super.initState();
    _reflectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3380),
    )..repeat();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(widget.borderRadius);
    final blur = _hovered ? widget.blur + 4 : widget.blur;

    return MouseRegion(
      onEnter: (_) {
        if (kIsWeb) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) {
        if (_hovered) {
          setState(() => _hovered = false);
        }
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _hovered ? 1 : 0),
        duration: const Duration(milliseconds: 143),
        curve: Curves.easeOutCubic,
        builder: (context, hoverValue, _) {
          return AnimatedBuilder(
            animation: _reflectionController,
            builder: (context, __) {
              final reflectionValue = _reflectionController.value;
              return Transform.translate(
                offset: Offset(0, -hoverValue * 4),
                child: Transform.scale(
                  scale: 1 + (hoverValue * 0.01),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.shadowColor ?? colorScheme.shadow)
                              .withValues(
                            alpha: (isDark ? 0.32 : 0.12) + (hoverValue * 0.1),
                          ),
                          blurRadius: 34 + (hoverValue * 16),
                          offset: Offset(0, 18 + (hoverValue * 8)),
                        ),
                        BoxShadow(
                          color: colorScheme.primary.withValues(
                            alpha: (isDark ? 0.24 : 0.12) + (hoverValue * 0.08),
                          ),
                          blurRadius: 46 + (hoverValue * 22),
                          spreadRadius: 0.8 + (hoverValue * 1.6),
                          offset: const Offset(0, 22),
                        ),
                        BoxShadow(
                          color: colorScheme.secondary.withValues(
                            alpha: (isDark ? 0.16 : 0.08) + (hoverValue * 0.06),
                          ),
                          blurRadius: 58,
                          offset: const Offset(0, 30),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                        child: Material(
                          color: Colors.transparent,
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: radius,
                              border: Border.all(
                                color: widget.borderColor ??
                                    Colors.white.withValues(
                                      alpha: isDark ? 0.2 : 0.62,
                                    ),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: (widget.gradientColors ??
                                        [
                                          Colors.white.withValues(
                                            alpha: isDark ? 0.2 : 0.82,
                                          ),
                                          colorScheme.primary.withValues(
                                            alpha: isDark ? 0.18 : 0.12,
                                          ),
                                          colorScheme.secondary.withValues(
                                            alpha: isDark ? 0.14 : 0.1,
                                          ),
                                          colorScheme.tertiary.withValues(
                                            alpha: isDark ? 0.1 : 0.06,
                                          ),
                                        ])
                                    .map(
                                      (color) => color.withValues(
                                        alpha: color.a * widget.opacity,
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment(
                                            -1.2 + (hoverValue * 0.8),
                                            -1,
                                          ),
                                          end: Alignment(
                                            0.35 + (hoverValue * 0.9),
                                            1,
                                          ),
                                          colors: [
                                            Colors.white.withValues(
                                              alpha: isDark ? 0.1 : 0.2,
                                            ),
                                            Colors.white.withValues(alpha: 0),
                                            colorScheme.secondary.withValues(
                                              alpha: isDark ? 0.06 : 0.05,
                                            ),
                                          ],
                                          stops: const [0, 0.36, 1],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          center: Alignment(
                                            0.92 - (hoverValue * 0.2),
                                            -0.86,
                                          ),
                                          radius: 1.2,
                                          colors: [
                                            colorScheme.secondary.withValues(
                                              alpha: isDark ? 0.14 : 0.1,
                                            ),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment(
                                            -1.45 + (reflectionValue * 2.4),
                                            -0.84,
                                          ),
                                          end: Alignment(
                                            -0.15 + (reflectionValue * 2.4),
                                            0.92,
                                          ),
                                          colors: [
                                            Colors.transparent,
                                            Colors.white
                                                .withValues(alpha: 0.03),
                                            Colors.white
                                                .withValues(alpha: 0.16),
                                            Colors.white
                                                .withValues(alpha: 0.04),
                                            Colors.transparent,
                                          ],
                                          stops: const [0, 0.3, 0.46, 0.62, 1],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: radius,
                                        border: Border.all(
                                          color: colorScheme.primary.withValues(
                                            alpha: isDark ? 0.18 : 0.12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: widget.onTap,
                                  child: Padding(
                                    padding: widget.padding,
                                    child: widget.child,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
