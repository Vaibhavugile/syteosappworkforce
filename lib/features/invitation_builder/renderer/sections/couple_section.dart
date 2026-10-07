import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';

class InvitationCoupleSection extends StatefulWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const InvitationCoupleSection({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  @override
  State<InvitationCoupleSection> createState() =>
      _InvitationCoupleSectionState();
}

class _InvitationCoupleSectionState
    extends State<InvitationCoupleSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1400,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 82,
      ),
      color: widget.theme.secondaryColor
          .withValues(alpha: 0.18),
      child: Column(
        children: [
          _buildHeading(),

          const SizedBox(height: 42),

          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildCoupleCards(),
            ),
          ),

          const SizedBox(height: 44),

          _buildLoveQuote(),

          const SizedBox(height: 26),

          _buildDivider(),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEADING
  // ===========================================================================

  Widget _buildHeading() {
    return Column(
      children: [
        Text(
          'THE COUPLE',
          style: TextStyle(
            color: widget.theme.primaryColor,
            fontFamily: widget.theme.bodyFont,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Two Souls, One Beautiful Journey',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.textColor,
            fontFamily:
                widget.theme.headingFont,
            fontSize: 31,
            height: 1.15,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 14),

        Container(
          width: 55,
          height: 1,
          color: widget.theme.accentColor,
        ),
      ],
    );
  }

  // ===========================================================================
  // COUPLE CARDS
  // ===========================================================================

  Widget _buildCoupleCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact =
            constraints.maxWidth < 650;

        if (compact) {
          return Column(
            children: [
              _buildPersonCard(
                name: widget.invitation.brideName,
                description:
                    widget.invitation.brideDescription,
                photoUrl:
                    widget.invitation.bridePhoto?.url,
                label: 'THE BRIDE',
                alignment:
                    CrossAxisAlignment.center,
              ),

              const SizedBox(height: 38),

              _buildAndSymbol(),

              const SizedBox(height: 38),

              _buildPersonCard(
                name: widget.invitation.groomName,
                description:
                    widget.invitation.groomDescription,
                photoUrl:
                    widget.invitation.groomPhoto?.url,
                label: 'THE GROOM',
                alignment:
                    CrossAxisAlignment.center,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPersonCard(
                name: widget.invitation.brideName,
                description:
                    widget.invitation.brideDescription,
                photoUrl:
                    widget.invitation.bridePhoto?.url,
                label: 'THE BRIDE',
                alignment:
                    CrossAxisAlignment.center,
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.only(
                top: 145,
              ),
              child: _buildAndSymbol(),
            ),

            Expanded(
              child: _buildPersonCard(
                name: widget.invitation.groomName,
                description:
                    widget.invitation.groomDescription,
                photoUrl:
                    widget.invitation.groomPhoto?.url,
                label: 'THE GROOM',
                alignment:
                    CrossAxisAlignment.center,
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // PERSON CARD
  // ===========================================================================

  Widget _buildPersonCard({
    required String name,
    required String description,
    required String? photoUrl,
    required String label,
    required CrossAxisAlignment alignment,
  }) {
    final String displayName =
        name.trim().isEmpty
            ? label == 'THE BRIDE'
                ? 'Bride'
                : 'Groom'
            : name;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            color: widget.theme.primaryColor,
            fontFamily: widget.theme.bodyFont,
            fontSize: 9,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 14),

        _buildPortrait(
          photoUrl,
          isBride: label == 'THE BRIDE',
        ),

        const SizedBox(height: 20),

        Text(
          displayName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.textColor,
            fontFamily:
                widget.theme.headingFont,
            fontSize: 29,
            fontWeight: FontWeight.w500,
          ),
        ),

        if (description.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 310,
            ),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    widget.theme.mutedTextColor,
                fontFamily:
                    widget.theme.bodyFont,
                fontSize: 12,
                height: 1.7,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // PORTRAIT
  // ===========================================================================

  Widget _buildPortrait(
    String? url, {
    required bool isBride,
  }) {
    return SizedBox(
      width: 210,
      height: 270,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PortraitFramePainter(
                primaryColor:
                    widget.theme.primaryColor,
                accentColor:
                    widget.theme.accentColor,
              ),
            ),
          ),

          Positioned(
            top: 12,
            bottom: 12,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.only(
                topLeft:
                    Radius.circular(110),
                topRight:
                    Radius.circular(110),
                bottomLeft:
                    Radius.circular(18),
                bottomRight:
                    Radius.circular(18),
              ),
              child: _buildImage(url),
            ),
          ),

          Positioned(
            top: -6,
            right: isBride ? 2 : null,
            left: isBride ? null : 2,
            child: _buildFlowerDecoration(),
          ),

          Positioned(
            bottom: 0,
            left: isBride ? 0 : null,
            right: isBride ? null : 0,
            child: _buildLeafDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(
    String? url,
  ) {
    if (url == null ||
        url.trim().isEmpty) {
      return _imagePlaceholder();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) {
        return _imagePlaceholder();
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

        return _imagePlaceholder(
          loading: true,
        );
      },
    );
  }

  Widget _imagePlaceholder({
    bool loading = false,
  }) {
    return Container(
      color: widget.theme.secondaryColor
          .withValues(alpha: 0.35),
      child: Center(
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color:
                      widget.theme.accentColor,
                ),
              )
            : Icon(
                Icons.person_outline_rounded,
                size: 38,
                color:
                    widget.theme.accentColor,
              ),
      ),
    );
  }

  // ===========================================================================
  // AND SYMBOL
  // ===========================================================================

  Widget _buildAndSymbol() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.theme.backgroundColor,
        border: Border.all(
          color:
              widget.theme.accentColor
                  .withValues(alpha: 0.65),
        ),
      ),
      child: Center(
        child: Text(
          '&',
          style: TextStyle(
            color: widget.theme.accentColor,
            fontFamily:
                widget.theme.scriptFont,
            fontSize: 28,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LOVE QUOTE
  // ===========================================================================

  Widget _buildLoveQuote() {
    return Column(
      children: [
        Icon(
          Icons.format_quote_rounded,
          color: widget.theme.accentColor
              .withValues(alpha: 0.75),
          size: 28,
        ),

        const SizedBox(height: 4),

        Text(
          '“And suddenly, all the love songs '
          'were about us.”',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.mutedTextColor,
            fontFamily:
                widget.theme.scriptFont,
            fontSize: 23,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DECORATIONS
  // ===========================================================================

  Widget _buildFlowerDecoration() {
    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: _FlowerPainter(
          flowerColor:
              widget.theme.primaryColor,
          accentColor:
              widget.theme.accentColor,
        ),
      ),
    );
  }

  Widget _buildLeafDecoration() {
    return Transform.rotate(
      angle: -0.3,
      child: Icon(
        Icons.eco_rounded,
        size: 42,
        color: widget.theme.primaryColor
            .withValues(alpha: 0.35),
      ),
    );
  }

  // ===========================================================================
  // DIVIDER
  // ===========================================================================

  Widget _buildDivider() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Container(
          width: 45,
          height: 1,
          color: widget.theme.accentColor
              .withValues(alpha: 0.45),
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.favorite_rounded,
          size: 10,
          color: widget.theme.primaryColor,
        ),
        const SizedBox(width: 10),
        Container(
          width: 45,
          height: 1,
          color: widget.theme.accentColor
              .withValues(alpha: 0.45),
        ),
      ],
    );
  }
}

// =============================================================================
// PORTRAIT FRAME
// =============================================================================

class _PortraitFramePainter
    extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  const _PortraitFramePainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final outerPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final innerPaint = Paint()
      ..color = primaryColor.withValues(
        alpha: 0.35,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final outerRect = Rect.fromLTWH(
      5,
      5,
      size.width - 10,
      size.height - 10,
    );

    final innerRect = Rect.fromLTWH(
      9,
      9,
      size.width - 18,
      size.height - 18,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        outerRect,
        const Radius.circular(115),
      ),
      outerPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        innerRect,
        const Radius.circular(110),
      ),
      innerPaint,
    );

    // Small decorative dots.
    final dotPaint = Paint()
      ..color = accentColor;

    canvas.drawCircle(
      const Offset(15, 15),
      2,
      dotPaint,
    );

    canvas.drawCircle(
      Offset(size.width - 15, 15),
      2,
      dotPaint,
    );

    canvas.drawCircle(
      Offset(15, size.height - 15),
      2,
      dotPaint,
    );

    canvas.drawCircle(
      Offset(
        size.width - 15,
        size.height - 15,
      ),
      2,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PortraitFramePainter oldDelegate,
  ) {
    return oldDelegate.primaryColor !=
            primaryColor ||
        oldDelegate.accentColor !=
            accentColor;
  }
}

// =============================================================================
// FLOWER
// =============================================================================

class _FlowerPainter
    extends CustomPainter {
  final Color flowerColor;
  final Color accentColor;

  const _FlowerPainter({
    required this.flowerColor,
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

    final petalPaint = Paint()
      ..color = flowerColor.withValues(
        alpha: 0.75,
      );

    for (int i = 0; i < 6; i++) {
      final double angle =
          (math.pi * 2 / 6) * i;

      final Offset petalCenter =
          Offset(
        center.dx +
            math.cos(angle) * 13,
        center.dy +
            math.sin(angle) * 13,
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
          -10,
          10,
          20,
        ),
        petalPaint,
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
    return oldDelegate.flowerColor !=
            flowerColor ||
        oldDelegate.accentColor !=
            accentColor;
  }
}