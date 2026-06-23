import 'package:flutter/material.dart';
import 'package:razak_travel/shared/animations/premium_motion.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    required this.placeholder,
    this.errorPlaceholder,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
  });

  final String imageUrl;
  final Widget placeholder;
  final Widget? errorPlaceholder;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl.trim();

    if (normalizedUrl.isEmpty) {
      return placeholder;
    }

    return Image.network(
      normalizedUrl,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }

        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: PremiumDurations.medium,
          curve: PremiumCurves.entrance,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        final expectedBytes = loadingProgress.expectedTotalBytes;
        final loadedBytes = loadingProgress.cumulativeBytesLoaded;
        final progress = expectedBytes == null || expectedBytes == 0
            ? null
            : loadedBytes / expectedBytes;

        return Stack(
          fit: StackFit.expand,
          children: [
            PremiumShimmer(child: placeholder),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: PremiumSkeleton(
                    height: 5,
                    borderRadius: 999,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress?.clamp(0.1, 1.0) ?? 0.38,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF14B8A6),
                                Color(0xFF0EA5E9),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorPlaceholder ?? placeholder;
      },
    );
  }
}
