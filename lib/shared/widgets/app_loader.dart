import 'package:flutter/material.dart';
import 'package:razak_travel/shared/animations/premium_motion.dart';

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_controller.value);
          return PulseGlow(
            color: colorScheme.primary,
            blur: 34,
            child: PremiumShimmer(
              child: SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.08),
                            colorScheme.secondary.withValues(alpha: 0.2),
                            colorScheme.tertiary.withValues(alpha: 0.18),
                            colorScheme.primary.withValues(alpha: 0.08),
                          ],
                          transform:
                              GradientRotation(_controller.value * 6.28318),
                        ),
                      ),
                    ),
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.surface.withValues(alpha: 0.96),
                            colorScheme.primary.withValues(alpha: 0.16),
                            colorScheme.secondary.withValues(alpha: 0.14),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PremiumSkeleton(
                            width: 48,
                            height: 8,
                            borderRadius: 999,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: 0.44 + (t * 0.42),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primary
                                            .withValues(alpha: 0.92),
                                        colorScheme.secondary
                                            .withValues(alpha: 0.78),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (index) {
                              final phase =
                                  ((_controller.value + (index * 0.16)) % 1);
                              final dotScale = 0.8 +
                                  (Curves.fastOutSlowIn.transform(phase) *
                                      0.36);

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: Transform.scale(
                                  scale: dotScale,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index == 1
                                          ? colorScheme.secondary
                                          : colorScheme.primary,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 10),
                          // ignore: prefer_const_constructors
                          PremiumSkeleton(
                            width: 38,
                            height: 6,
                            borderRadius: 999,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
