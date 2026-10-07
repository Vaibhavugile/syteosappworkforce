import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/invitation_theme.dart';

class LotusRoyaleDecorations {
  LotusRoyaleDecorations._();

  static Widget topFloralArch({
    required InvitationTheme theme,
    double height = 180,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _LotusArchPainter(
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          secondaryColor: theme.secondaryColor,
        ),
      ),
    );
  }

  static Widget lotusFlower({
    required InvitationTheme theme,
    double size = 70,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LotusFlowerPainter(
          primaryColor: theme.primaryColor,
          accentColor: theme.accentColor,
          secondaryColor: theme.secondaryColor,
        ),
      ),
    );
  }

  static Widget cornerDecoration({
    required InvitationTheme theme,
    required Alignment alignment,
    double size = 120,
  }) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CornerFloralPainter(
            primaryColor: theme.primaryColor,
            accentColor: theme.accentColor,
            secondaryColor: theme.secondaryColor,
            flipHorizontal:
                alignment == Alignment.topRight ||
                alignment == Alignment.bottomRight,
            flipVertical:
                alignment == Alignment.bottomLeft ||
                alignment == Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  static Widget goldDivider({
    required InvitationTheme theme,
    double width = 180,
  }) {
    return SizedBox(
      width: width,
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: theme.accentColor.withValues(
                alpha: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.local_florist_rounded,
            size: 14,
            color: theme.accentColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: theme.accentColor.withValues(
                alpha: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget goldFrame({
    required InvitationTheme theme,
    required Widget child,
    double borderRadius = 24,
    EdgeInsets padding = const EdgeInsets.all(7),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          borderRadius,
        ),
        border: Border.all(
          color: theme.accentColor.withValues(
            alpha: 0.8,
          ),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accentColor.withValues(
              alpha: 0.12,
            ),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            borderRadius - 4,
          ),
          border: Border.all(
            color: theme.accentColor.withValues(
              alpha: 0.35,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            borderRadius - 5,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LotusArchPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final Color secondaryColor;

  const _LotusArchPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.secondaryColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Paint goldPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final Paint softPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final double centerX = size.width / 2;

    final Rect archRect = Rect.fromCenter(
      center: Offset(
        centerX,
        size.height * 0.92,
      ),
      width: size.width * 0.72,
      height: size.height * 1.55,
    );

    canvas.drawArc(
      archRect,
      math.pi,
      math.pi,
      false,
      goldPaint,
    );

    final Rect innerArchRect =
        Rect.fromCenter(
      center: Offset(
        centerX,
        size.height * 0.94,
      ),
      width: size.width * 0.64,
      height: size.height * 1.38,
    );

    canvas.drawArc(
      innerArchRect,
      math.pi,
      math.pi,
      false,
      softPaint,
    );

    _drawFlowerCluster(
      canvas,
      Offset(
        size.width * 0.15,
        size.height * 0.48,
      ),
      0.85,
    );

    _drawFlowerCluster(
      canvas,
      Offset(
        size.width * 0.85,
        size.height * 0.48,
      ),
      -0.85,
    );

    _drawLeaves(
      canvas,
      Offset(
        size.width * 0.09,
        size.height * 0.67,
      ),
      false,
    );

    _drawLeaves(
      canvas,
      Offset(
        size.width * 0.91,
        size.height * 0.67,
      ),
      true,
    );
  }

  void _drawFlowerCluster(
    Canvas canvas,
    Offset center,
    double direction,
  ) {
    final Paint flowerPaint = Paint()
      ..color = primaryColor.withValues(
        alpha: 0.5,
      )
      ..style = PaintingStyle.fill;

    final Paint centerPaint = Paint()
      ..color = accentColor.withValues(
        alpha: 0.8,
      );

    for (int i = 0; i < 5; i++) {
      final double angle =
          (math.pi * 2 / 5) * i;

      final Offset petalCenter = center +
          Offset(
            math.cos(angle) * 9,
            math.sin(angle) * 9,
          );

      canvas.drawOval(
        Rect.fromCenter(
          center: petalCenter,
          width: 13,
          height: 20,
        ),
        flowerPaint,
      );
    }

    canvas.drawCircle(
      center,
      5,
      centerPaint,
    );

    final Paint stemPaint = Paint()
      ..color = primaryColor.withValues(
        alpha: 0.45,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final Path stem = Path()
      ..moveTo(center.dx, center.dy + 7)
      ..quadraticBezierTo(
        center.dx + direction * 15,
        center.dy + 35,
        center.dx + direction * 18,
        center.dy + 55,
      );

    canvas.drawPath(
      stem,
      stemPaint,
    );
  }

  void _drawLeaves(
    Canvas canvas,
    Offset start,
    bool flip,
  ) {
    final Paint leafPaint = Paint()
      ..color = primaryColor.withValues(
        alpha: 0.35,
      );

    for (int i = 0; i < 4; i++) {
      final double y = start.dy + i * 11;
      final double x =
          start.dx + (flip ? -i * 5 : i * 5);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 20,
          height: 9,
        ),
        leafPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _LotusArchPainter oldDelegate,
  ) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

class _LotusFlowerPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final Color secondaryColor;

  const _LotusFlowerPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.secondaryColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center = Offset(
      size.width / 2,
      size.height * 0.62,
    );

    final double petalWidth =
        size.width * 0.27;

    final double petalHeight =
        size.height * 0.62;

    final Paint outerPaint = Paint()
      ..color = secondaryColor.withValues(
        alpha: 0.9,
      );

    final Paint innerPaint = Paint()
      ..color = primaryColor.withValues(
        alpha: 0.72,
      );

    final Paint goldPaint = Paint()
      ..color = accentColor.withValues(
        alpha: 0.9,
      );

    for (int i = 0; i < 7; i++) {
      final double angle =
          math.pi * 0.15 +
          (math.pi * 0.7 / 6) * i;

      canvas.save();

      canvas.translate(
        center.dx,
        center.dy,
      );

      canvas.rotate(
        angle - math.pi / 2,
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            0,
            -petalHeight * 0.32,
          ),
          width: petalWidth,
          height: petalHeight,
        ),
        outerPaint,
      );

      canvas.restore();
    }

    for (int i = 0; i < 5; i++) {
      final double angle =
          math.pi * 0.2 +
          (math.pi * 0.6 / 4) * i;

      canvas.save();

      canvas.translate(
        center.dx,
        center.dy,
      );

      canvas.rotate(
        angle - math.pi / 2,
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            0,
            -petalHeight * 0.28,
          ),
          width: petalWidth * 0.72,
          height: petalHeight * 0.78,
        ),
        innerPaint,
      );

      canvas.restore();
    }

    final Path base = Path()
      ..moveTo(
        center.dx - size.width * 0.34,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + size.height * 0.22,
        center.dx + size.width * 0.34,
        center.dy,
      )
      ..close();

    canvas.drawPath(
      base,
      goldPaint,
    );

    canvas.drawCircle(
      center,
      size.width * 0.045,
      goldPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _LotusFlowerPainter oldDelegate,
  ) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

class _CornerFloralPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final Color secondaryColor;

  final bool flipHorizontal;
  final bool flipVertical;

  const _CornerFloralPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.secondaryColor,
    required this.flipHorizontal,
    required this.flipVertical,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    canvas.save();

    if (flipHorizontal) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    if (flipVertical) {
      canvas.translate(0, size.height);
      canvas.scale(1, -1);
    }

    final Paint goldPaint = Paint()
      ..color = accentColor.withValues(
        alpha: 0.65,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final Paint flowerPaint = Paint()
      ..color = primaryColor.withValues(
        alpha: 0.38,
      );

    final Paint leafPaint = Paint()
      ..color = secondaryColor.withValues(
        alpha: 0.7,
      );

    final Path branch = Path()
      ..moveTo(
        0,
        size.height * 0.2,
      )
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.2,
        size.width * 0.75,
        size.height * 0.8,
      );

    canvas.drawPath(
      branch,
      goldPaint,
    );

    for (int i = 0; i < 5; i++) {
      final double x =
          size.width * (0.15 + i * 0.14);
      final double y =
          size.height * (0.25 + i * 0.11);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 24,
          height: 10,
        ),
        leafPaint,
      );
    }

    for (int i = 0; i < 3; i++) {
      final Offset center = Offset(
        size.width * (0.22 + i * 0.23),
        size.height * (0.23 + i * 0.19),
      );

      for (int petal = 0; petal < 5; petal++) {
        final double angle =
            math.pi * 2 / 5 * petal;

        final Offset petalCenter = center +
            Offset(
              math.cos(angle) * 7,
              math.sin(angle) * 7,
            );

        canvas.drawOval(
          Rect.fromCenter(
            center: petalCenter,
            width: 10,
            height: 15,
          ),
          flowerPaint,
        );
      }

      canvas.drawCircle(
        center,
        3,
        Paint()..color = accentColor,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _CornerFloralPainter oldDelegate,
  ) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.flipHorizontal != flipHorizontal ||
        oldDelegate.flipVertical != flipVertical;
  }
}