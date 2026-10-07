import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Premium cinematic 3D scroll wrapper.
///
/// Each invitation section behaves like a physical luxury card/screen:
/// it rises from below the viewport, scales into place, rotates slightly
/// on the X axis, and gradually loses its depth shadow as it settles.
///
/// Use one shared [scrollNotifier] for all sections.
class Premium3DScrollSection extends StatelessWidget {
  const Premium3DScrollSection({
    super.key,
    required this.child,
    required this.scrollNotifier,
    this.minScale = 0.88,
    this.maxScale = 1.0,
    this.maxLift = 110.0,
    this.maxRotation = 0.075,
    this.minOpacity = 0.72,
    this.borderRadius = 28.0,
    this.enableShadow = true,
  });

  final Widget child;
  final ValueListenable<double> scrollNotifier;

  final double minScale;
  final double maxScale;
  final double maxLift;
  final double maxRotation;
  final double minOpacity;
  final double borderRadius;
  final bool enableShadow;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return ValueListenableBuilder<double>(
      valueListenable: scrollNotifier,
      builder: (context, _, __) {
        final scrollable = Scrollable.maybeOf(context);

        if (scrollable == null) {
          return child;
        }

        final scrollRenderObject =
            scrollable.context.findRenderObject();

        final sectionRenderObject =
            context.findRenderObject();

        if (scrollRenderObject is! RenderBox ||
            sectionRenderObject is! RenderBox) {
          return child;
        }

        if (!scrollRenderObject.hasSize ||
            !sectionRenderObject.hasSize) {
          return child;
        }

        final scrollOrigin =
            scrollRenderObject.localToGlobal(Offset.zero);

        final sectionOrigin =
            sectionRenderObject.localToGlobal(Offset.zero);

        final viewportHeight = scrollRenderObject.size.height;

        final sectionTop =
            sectionOrigin.dy - scrollOrigin.dy;

        final sectionHeight =
            sectionRenderObject.size.height;

        final progress = _calculateProgress(
          sectionTop: sectionTop,
          sectionHeight: sectionHeight,
          viewportHeight: viewportHeight,
        );

        final scale =
            minScale + ((maxScale - minScale) * progress);

        final lift =
            maxLift * (1.0 - progress);

        final rotation =
            maxRotation * (1.0 - progress);

        final opacity =
            minOpacity +
            ((1.0 - minOpacity) * progress);

        final shadowProgress =
            (1.0 - progress).clamp(0.0, 1.0);

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.00115)
          ..translate(0.0, lift)
          ..rotateX(rotation)
          ..scale(scale);

        final shadow = enableShadow && shadowProgress > 0.01
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.20 * shadowProgress,
                  ),
                  blurRadius: 42.0 * shadowProgress,
                  spreadRadius: 3.0 * shadowProgress,
                  offset: Offset(
                    0,
                    22.0 * shadowProgress,
                  ),
                ),
              ]
            : const <BoxShadow>[];

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.topCenter,
            transform: matrix,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(borderRadius),
                boxShadow: shadow,
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(borderRadius),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateProgress({
    required double sectionTop,
    required double sectionHeight,
    required double viewportHeight,
  }) {
    if (viewportHeight <= 0 || sectionHeight <= 0) {
      return 1.0;
    }

    // The section begins its cinematic entrance while it is still
    // below the viewer and settles before reaching the upper-middle
    // part of the screen.
    final start = viewportHeight * 0.95;
    final end = viewportHeight * 0.20;

    final anchor =
        sectionTop + (sectionHeight * 0.08);

    final distance = start - end;

    if (distance <= 0) {
      return 1.0;
    }

    final progress =
        (start - anchor) / distance;

    return progress.clamp(0.0, 1.0);
  }
}
