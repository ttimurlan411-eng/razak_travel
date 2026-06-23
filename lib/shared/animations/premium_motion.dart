import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

enum PremiumRouteStyle {
  fadeThrough,
  liquidSlide,
  blurScale,
}

abstract final class PremiumCurves {
  static const entrance = Curves.easeOutCubic;
  static const standard = Curves.easeInOut;
  static const emphasized = Curves.fastOutSlowIn;
}

abstract final class PremiumDurations {
  static const quick = Duration(milliseconds: 143);
  static const medium = Duration(milliseconds: 208);
  static const slow = Duration(milliseconds: 293);
}

abstract final class PremiumMotion {
  static Route<T> pageRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    PremiumRouteStyle style = PremiumRouteStyle.liquidSlide,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: PremiumDurations.slow,
      reverseTransitionDuration: PremiumDurations.medium,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: PremiumCurves.entrance,
          reverseCurve: PremiumCurves.standard,
        );
        final fade = FadeTransition(opacity: curved, child: child);
        final scale = ScaleTransition(
          scale: Tween<double>(begin: 0.982, end: 1).animate(curved),
          child: fade,
        );

        switch (style) {
          case PremiumRouteStyle.fadeThrough:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.025),
                end: Offset.zero,
              ).animate(curved),
              child: scale,
            );
          case PremiumRouteStyle.blurScale:
            return AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (context, routeChild) {
                final blur = (1 - curved.value) * 16;
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(curved),
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.955,
                          end: 1,
                        ).animate(curved),
                        child: routeChild,
                      ),
                    ),
                  ),
                );
              },
            );
          case PremiumRouteStyle.liquidSlide:
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: PremiumCurves.emphasized,
                  reverseCurve: PremiumCurves.standard,
                )),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.99, end: 1).animate(curved),
                  child: child,
                ),
              ),
            );
        }
      },
    );
  }
}

class PremiumReveal extends StatelessWidget {
  const PremiumReveal({
    super.key,
    this.child = const SizedBox.shrink(),
    this.offset = const Offset(0, 18),
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 455),
  });

  final Widget child;
  final Offset offset;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration + delay,
      curve: PremiumCurves.entrance,
      builder: (context, value, _) {
        final delayedValue = delay == Duration.zero
            ? value
            : ((value * (duration + delay).inMilliseconds) - delay.inMilliseconds) /
                duration.inMilliseconds;
        final t = delayedValue.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(offset.dx * (1 - t), offset.dy * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

class FloatingMotion extends StatefulWidget {
  const FloatingMotion({
    super.key,
    this.child = const SizedBox.shrink(),
    this.distance = 8,
    this.duration = const Duration(milliseconds: 2730),
  });

  final Widget child;
  final double distance;
  final Duration duration;

  @override
  State<FloatingMotion> createState() => _FloatingMotionState();
}

class _FloatingMotionState extends State<FloatingMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final dy = math.sin(_controller.value * math.pi) * widget.distance;
        return Transform.translate(
          offset: Offset(0, -dy),
          child: child,
        );
      },
    );
  }
}

class PulseGlow extends StatefulWidget {
  const PulseGlow({
    super.key,
    this.child = const SizedBox.shrink(),
    this.color = Colors.transparent,
    this.enabled = true,
    this.blur = 28,
  });

  final Widget child;
  final Color color;
  final bool enabled;
  final double blur;

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1430),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.14 + (t * 0.14)),
                blurRadius: widget.blur + (t * 14),
                spreadRadius: 0.6 + (t * 1.8),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class PremiumParallax extends StatelessWidget {
  const PremiumParallax({
    super.key,
    this.child = const SizedBox.shrink(),
    this.controller,
    this.depth = 0.14,
    this.extraExtent = 48,
  });

  final Widget child;
  final ScrollController? controller;
  final double depth;
  final double extraExtent;

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return child;
    }

    return ClipRect(
      child: AnimatedBuilder(
        animation: controller!,
        child: child,
        builder: (context, parallaxChild) {
          final offset = controller!.hasClients ? controller!.offset : 0.0;
          final shift = -offset * depth;
          return Transform.translate(
            offset: Offset(0, shift),
            child: OverflowBox(
              minHeight: 0,
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: extraExtent / 2),
                child: parallaxChild,
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedGradientSurface extends StatefulWidget {
  const AnimatedGradientSurface({
    super.key,
    this.child = const SizedBox.shrink(),
    this.colors = const [
      Color(0xFF07111A),
      Color(0xFF0F172A),
      Color(0xFF0A5A68),
      Color(0xFF0EA5E9),
    ],
    this.opacity = 1,
  });

  final Widget child;
  final List<Color> colors;
  final double opacity;

  @override
  State<AnimatedGradientSurface> createState() => _AnimatedGradientSurfaceState();
}

class _AnimatedGradientSurfaceState extends State<AnimatedGradientSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 11700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = PremiumCurves.standard.transform(_controller.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1.2 + (t * 1.1), -1.1),
                  end: Alignment(1.05 - (t * 0.8), 1.15),
                  colors: widget.colors
                      .map((color) => color.withValues(alpha: widget.opacity))
                      .toList(growable: false),
                  stops: const [0, 0.22, 0.68, 1],
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.72 - (t * 0.55), -0.82 + (t * 0.45)),
                    radius: 1.18,
                    colors: [
                      const Color(0xFF67E8F9)
                          .withValues(alpha: 0.2 * widget.opacity),
                      const Color(0xFF14B8A6)
                          .withValues(alpha: 0.16 * widget.opacity),
                      const Color(0xFF0EA5E9)
                          .withValues(alpha: 0.1 * widget.opacity),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.16, 0.32, 1],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.84 + (t * 0.34), 0.94 - (t * 0.26)),
                    radius: 1,
                    colors: [
                      const Color(0xFF7C3AED)
                          .withValues(alpha: 0.16 * widget.opacity),
                      Colors.transparent,
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.35 + (t * 2.3), -0.92),
                    end: Alignment(-0.18 + (t * 2.25), 0.9),
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.06 * widget.opacity),
                      Colors.white.withValues(alpha: 0.14 * widget.opacity),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.32, 0.5, 1],
                  ),
                ),
              ),
            ),
            child ?? const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}

class PremiumShimmer extends StatefulWidget {
  const PremiumShimmer({
    super.key,
    required this.child,
    this.opacity = 1,
  });

  final Widget child;
  final double opacity;

  @override
  State<PremiumShimmer> createState() => _PremiumShimmerState();
}

class _PremiumShimmerState extends State<PremiumShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1560),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = PremiumCurves.standard.transform(_controller.value);
        return Stack(
          fit: StackFit.loose,
          clipBehavior: Clip.hardEdge,
          children: [
            child ?? const SizedBox.shrink(),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.45 + (t * 2.5), -0.85),
                      end: Alignment(-0.35 + (t * 2.5), 0.9),
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.02 * widget.opacity),
                        Colors.white.withValues(alpha: 0.18 * widget.opacity),
                        Colors.white.withValues(alpha: 0.04 * widget.opacity),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.28, 0.46, 0.62, 1],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PremiumSkeleton extends StatelessWidget {
  const PremiumSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 18,
    this.child,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PulseGlow(
      color: colorScheme.primary.withValues(alpha: 0.5),
      blur: 18,
      child: PremiumShimmer(
        opacity: 0.9,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface.withValues(alpha: 0.82),
                colorScheme.primary.withValues(alpha: 0.12),
                colorScheme.secondary.withValues(alpha: 0.16),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
