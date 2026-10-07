import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';

class InvitationHeroSection extends StatefulWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;

  final bool enablePetals;
  final bool enableParallax;
  final bool enable3DTilt;

  final bool isPreview;

  const InvitationHeroSection({
    super.key,
    required this.invitation,
    required this.theme,
    this.enablePetals = false,
    this.enableParallax = false,
    this.enable3DTilt = false,
    this.isPreview = false,
  });

  @override
  State<InvitationHeroSection> createState() =>
      _InvitationHeroSectionState();
}

class _InvitationHeroSectionState
    extends State<InvitationHeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _textAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.65,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.8,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _textAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.15,
          0.9,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final double width =
        mediaQuery.size.width;

    final bool isSmallScreen =
        width < 380;

    final double heroHeight =
        widget.isPreview
            ? 620
            : math.max(
                680,
                mediaQuery.size.height * 0.92,
              );

    return SizedBox(
      width: double.infinity,
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),

          if (widget.enableParallax)
            _buildDecorativeGlow(),

          if (widget.enablePetals)
            _buildPetals(),

          _buildTopDecoration(),

          _buildMainContent(
            isSmallScreen: isSmallScreen,
          ),

          _buildBottomDecoration(),
        ],
      ),
    );
  }

  // ===========================================================================
  // BACKGROUND
  // ===========================================================================

  Widget _buildBackground() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.theme.backgroundColor,
            widget.theme.secondaryColor.withValues(
              alpha: 0.30,
            ),
            widget.theme.backgroundColor,
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DECORATIVE GLOW
  // ===========================================================================

  Widget _buildDecorativeGlow() {
    return Positioned(
      top: -120,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              widget.theme.accentColor.withValues(
                alpha: 0.16,
              ),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP DECORATION
  // ===========================================================================

  Widget _buildTopDecoration() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SizedBox(
          height: 180,
          child: CustomPaint(
            painter: _FloralCornerPainter(
              primaryColor:
                  widget.theme.primaryColor,
              accentColor:
                  widget.theme.accentColor,
              secondaryColor:
                  widget.theme.secondaryColor,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MAIN CONTENT
  // ===========================================================================

  Widget _buildMainContent({
    required bool isSmallScreen,
  }) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal:
              isSmallScreen ? 20 : 28,
          vertical: 28,
        ),
        child: Column(
          children: [
            const SizedBox(height: 18),

            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildSmallHeading(),
            ),

            const SizedBox(height: 16),

            SlideTransition(
              position: _textAnimation,
              child: _buildNames(),
            ),

            const SizedBox(height: 18),

            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildDate(),
            ),

            const SizedBox(height: 28),

            Expanded(
              child: _buildCouplePhoto(
                isSmallScreen,
              ),
            ),

            const SizedBox(height: 24),

            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildVenue(),
            ),

            const SizedBox(height: 24),

            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildScrollHint(),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SMALL HEADING
  // ===========================================================================

  Widget _buildSmallHeading() {
    return Column(
      children: [
        Text(
          'TOGETHER WITH OUR FAMILIES',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.mutedTextColor,
            fontFamily: widget.theme.bodyFont,
            fontSize: 10,
            letterSpacing: 2.8,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 42,
          height: 1,
          color: widget.theme.accentColor,
        ),
      ],
    );
  }

  // ===========================================================================
  // NAMES
  // ===========================================================================

  Widget _buildNames() {
    final String bride =
        widget.invitation.brideName
                .trim()
                .isEmpty
            ? 'Bride'
            : widget.invitation.brideName;

    final String groom =
        widget.invitation.groomName
                .trim()
                .isEmpty
            ? 'Groom'
            : widget.invitation.groomName;

    return Column(
      children: [
        Text(
          bride,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.textColor,
            fontFamily:
                widget.theme.headingFont,
            fontSize: 42,
            height: 0.95,
            fontWeight: FontWeight.w500,
          ),
        ),

        Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 4,
          ),
          child: Text(
            '&',
            style: TextStyle(
              color: widget.theme.accentColor,
              fontFamily:
                  widget.theme.scriptFont,
              fontSize: 34,
            ),
          ),
        ),

        Text(
          groom,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.textColor,
            fontFamily:
                widget.theme.headingFont,
            fontSize: 42,
            height: 0.95,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DATE
  // ===========================================================================

  Widget _buildDate() {
    final String date =
        widget.invitation.weddingDate
                .trim()
                .isEmpty
            ? 'Your Wedding Date'
            : widget.invitation.weddingDate;

    final String time =
        widget.invitation.weddingTime
                .trim()
                .isEmpty
            ? ''
            : widget.invitation.weddingTime;

    return Column(
      children: [
        Text(
          date.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.primaryColor,
            fontFamily: widget.theme.bodyFont,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),

        if (time.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            time,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.theme.mutedTextColor,
              fontFamily:
                  widget.theme.bodyFont,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // COUPLE PHOTO
  // ===========================================================================

  Widget _buildCouplePhoto(
    bool isSmallScreen,
  ) {
    final photo =
        widget.invitation.couplePhoto;

    final double maxWidth =
        isSmallScreen ? 270 : 310;

    final double maxHeight =
        isSmallScreen ? 300 : 350;

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          width: double.infinity,
          child: AspectRatio(
            aspectRatio: 0.84,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: _buildPhotoContent(
                    photo?.url,
                  ),
                ),

                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _PhotoFramePainter(
                        color:
                            widget.theme.accentColor,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: -10,
                  left: -10,
                  child: _smallFlower(),
                ),

                Positioned(
                  bottom: -10,
                  right: -10,
                  child: Transform.rotate(
                    angle: math.pi,
                    child: _smallFlower(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoContent(
    String? url,
  ) {
    if (url != null &&
        url.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(150),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) {
            return _photoPlaceholder();
          },
          loadingBuilder:
              (
                context,
                child,
                loadingProgress,
              ) {
            if (loadingProgress == null) {
              return child;
            }

            return _photoPlaceholder(
              showLoading: true,
            );
          },
        ),
      );
    }

    return _photoPlaceholder();
  }

  Widget _photoPlaceholder({
    bool showLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(150),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.theme.secondaryColor,
            widget.theme.backgroundColor,
          ],
        ),
      ),
      child: Center(
        child: showLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color:
                      widget.theme.accentColor,
                ),
              )
            : Icon(
                Icons.favorite_border_rounded,
                size: 42,
                color:
                    widget.theme.accentColor
                        .withValues(
                  alpha: 0.7,
                ),
              ),
      ),
    );
  }

  // ===========================================================================
  // VENUE
  // ===========================================================================

  Widget _buildVenue() {
    final String venue =
        widget.invitation.venueName
                .trim()
                .isEmpty
            ? 'Wedding Celebration'
            : widget.invitation.venueName;

    return Column(
      children: [
        Text(
          venue,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.textColor,
            fontFamily:
                widget.theme.headingFont,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),

        if (widget
            .invitation
            .venueAddress
            .trim()
            .isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.invitation.venueAddress,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  widget.theme.mutedTextColor,
              fontFamily:
                  widget.theme.bodyFont,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // SCROLL HINT
  // ===========================================================================

  Widget _buildScrollHint() {
    return Column(
      children: [
        Text(
          'SCROLL TO EXPLORE',
          style: TextStyle(
            color: widget.theme.mutedTextColor,
            fontFamily: widget.theme.bodyFont,
            fontSize: 8,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          color: widget.theme.accentColor,
          size: 22,
        ),
      ],
    );
  }

  // ===========================================================================
  // PETALS
  // ===========================================================================

  Widget _buildPetals() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _PetalPainter(
          primaryColor:
              widget.theme.primaryColor,
          secondaryColor:
              widget.theme.secondaryColor,
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM DECORATION
  // ===========================================================================

  Widget _buildBottomDecoration() {
    return Positioned(
      bottom: -1,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SizedBox(
          height: 80,
          child: CustomPaint(
            painter: _BottomFloralPainter(
              primaryColor:
                  widget.theme.primaryColor,
              accentColor:
                  widget.theme.accentColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallFlower() {
    return SizedBox(
      width: 42,
      height: 42,
      child: CustomPaint(
        painter: _FlowerPainter(
          color: widget.theme.primaryColor,
          accentColor: widget.theme.accentColor,
        ),
      ),
    );
  }
}

// =============================================================================
// FLORAL CORNER PAINTER
// =============================================================================

class _FloralCornerPainter
    extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final Color secondaryColor;

  const _FloralCornerPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.secondaryColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final double scale =
        size.width / 390;

    canvas.save();
    canvas.scale(scale);

    // Leaves
    paint.color =
        primaryColor.withValues(alpha: 0.16);

    for (int i = 0; i < 5; i++) {
      final double x =
          18.0 + (i * 22);
      final double y =
          18.0 + (i * 12);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(
        -0.55 + (i * 0.15),
      );

      canvas.drawOval(
        const Rect.fromLTWH(
          0,
          0,
          42,
          15,
        ),
        paint,
      );

      canvas.restore();
    }

    // Flowers
    _drawFlower(
      canvas,
      const Offset(20, 28),
      28,
      primaryColor,
      accentColor,
    );

    _drawFlower(
      canvas,
      const Offset(65, 65),
      20,
      secondaryColor,
      accentColor,
    );

    _drawFlower(
      canvas,
      const Offset(110, 22),
      15,
      primaryColor,
      accentColor,
    );

    canvas.restore();
  }

  void _drawFlower(
    Canvas canvas,
    Offset center,
    double radius,
    Color flowerColor,
    Color centerColor,
  ) {
    final paint = Paint()
      ..color = flowerColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final double angle =
          (math.pi * 2 / 6) * i;

      final Offset petalCenter =
          Offset(
        center.dx +
            math.cos(angle) *
                radius *
                0.55,
        center.dy +
            math.sin(angle) *
                radius *
                0.55,
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: petalCenter,
          width: radius * 0.65,
          height: radius * 0.9,
        ),
        paint,
      );
    }

    canvas.drawCircle(
      center,
      radius * 0.25,
      Paint()..color = centerColor,
    );
  }

  @override
  bool shouldRepaint(
    covariant _FloralCornerPainter oldDelegate,
  ) {
    return oldDelegate.primaryColor !=
            primaryColor ||
        oldDelegate.accentColor !=
            accentColor ||
        oldDelegate.secondaryColor !=
            secondaryColor;
  }
}

// =============================================================================
// PHOTO FRAME PAINTER
// =============================================================================

class _PhotoFramePainter
    extends CustomPainter {
  final Color color;

  const _PhotoFramePainter({
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = Rect.fromLTWH(
      6,
      6,
      size.width - 12,
      size.height - 12,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(150),
      ),
      paint,
    );

    final innerRect =
        Rect.fromLTWH(
      12,
      12,
      size.width - 24,
      size.height - 24,
    );

    paint
      ..color = color.withValues(
        alpha: 0.35,
      )
      ..strokeWidth = 0.7;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        innerRect,
        const Radius.circular(150),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PhotoFramePainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}

// =============================================================================
// PETAL PAINTER
// =============================================================================

class _PetalPainter
    extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  const _PetalPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final petals = [
      const Offset(0.12, 0.25),
      const Offset(0.88, 0.18),
      const Offset(0.20, 0.60),
      const Offset(0.82, 0.68),
      const Offset(0.08, 0.82),
      const Offset(0.94, 0.84),
      const Offset(0.36, 0.12),
      const Offset(0.66, 0.38),
    ];

    for (int i = 0; i < petals.length; i++) {
      final point = petals[i];

      paint.color =
          (i.isEven
                  ? primaryColor
                  : secondaryColor)
              .withValues(alpha: 0.18);

      canvas.save();

      canvas.translate(
        size.width * point.dx,
        size.height * point.dy,
      );

      canvas.rotate(
        -0.5 + (i * 0.4),
      );

      canvas.drawOval(
        const Rect.fromLTWH(
          -5,
          -10,
          10,
          20,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(
    covariant _PetalPainter oldDelegate,
  ) {
    return oldDelegate.primaryColor !=
            primaryColor ||
        oldDelegate.secondaryColor !=
            secondaryColor;
  }
}

// =============================================================================
// BOTTOM FLORAL PAINTER
// =============================================================================

class _BottomFloralPainter
    extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  const _BottomFloralPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();

    path.moveTo(
      0,
      size.height * 0.65,
    );

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.10,
      size.width * 0.50,
      size.height * 0.55,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height * 0.30,
    );

    paint.color =
        primaryColor.withValues(
      alpha: 0.28,
    );

    canvas.drawPath(
      path,
      paint,
    );

    paint
      ..style = PaintingStyle.fill
      ..color = accentColor.withValues(
        alpha: 0.7,
      );

    canvas.drawCircle(
      Offset(
        size.width * 0.5,
        size.height * 0.55,
      ),
      3,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _BottomFloralPainter oldDelegate,
  ) {
    return oldDelegate.primaryColor !=
            primaryColor ||
        oldDelegate.accentColor !=
            accentColor;
  }
}

// =============================================================================
// SMALL FLOWER PAINTER
// =============================================================================

class _FlowerPainter
    extends CustomPainter {
  final Color color;
  final Color accentColor;

  const _FlowerPainter({
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final paint = Paint()
      ..color = color.withValues(
        alpha: 0.75,
      );

    for (int i = 0; i < 6; i++) {
      final double angle =
          (math.pi * 2 / 6) * i;

      final Offset petalCenter =
          Offset(
        center.dx +
            math.cos(angle) * 11,
        center.dy +
            math.sin(angle) * 11,
      );

      canvas.save();
      canvas.translate(
        petalCenter.dx,
        petalCenter.dy,
      );
      canvas.rotate(angle);

      canvas.drawOval(
        const Rect.fromLTWH(
          -5,
          -9,
          10,
          18,
        ),
        paint,
      );

      canvas.restore();
    }

    canvas.drawCircle(
      center,
      5,
      Paint()..color = accentColor,
    );
  }

  @override
  bool shouldRepaint(
    covariant _FlowerPainter oldDelegate,
  ) {
    return oldDelegate.color != color ||
        oldDelegate.accentColor !=
            accentColor;
  }
}