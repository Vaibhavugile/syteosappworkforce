import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_photo.dart';
import '../../models/invitation_theme.dart';

/// Premium Couple section for Lotus Royale.
///
/// The artwork already contains the title, circular portrait frames,
/// THE BRIDE / THE GROOM labels, heart ornament, quote and scenery.
///
/// Flutter overlays only:
/// - bride photo
/// - groom photo
/// - bride name
/// - groom name
///
/// Descriptions are intentionally not rendered here so the artwork stays
/// clean and premium.
class LotusRoyaleCouple extends StatefulWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const LotusRoyaleCouple({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  @override
  State<LotusRoyaleCouple> createState() => _LotusRoyaleCoupleState();
}

class _LotusRoyaleCoupleState extends State<LotusRoyaleCouple>
    with TickerProviderStateMixin {
  static const String _backgroundAsset =
      'assets/invitations/lotus_royale/backgrounds/couple.webp';

  static const double _artWidth = 1536;
  static const double _artHeight = 2048;

  static const Color _wine = Color(0xFF713B4C);
  static const Color _gold = Color(0xFFC9A05B);

  late final AnimationController _entranceController;
  late final AnimationController _motionController;
  late final Animation<double> _portraitAnimation;
  late final Animation<double> _nameAnimation;

  bool _reduceMotion = false;

  double _brideTiltX = 0;
  double _brideTiltY = 0;
  double _groomTiltX = 0;
  double _groomTiltY = 0;

  InvitationModel get invitation => widget.invitation;
  InvitationTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _portraitAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.08,
        0.58,
        curve: Curves.easeOutBack,
      ),
    );

    _nameAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.35,
        0.82,
        curve: Curves.easeOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;

      if (_reduceMotion) {
        _entranceController.value = 1;
        _motionController.stop();
      } else {
        _entranceController.forward();
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF7F1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = width * _artHeight / _artWidth;

          return SizedBox(
            width: width,
            height: height,
            child: AnimatedBuilder(
              animation: _motionController,
              builder: (context, child) {
                final double progress = _motionController.value;

                final double backgroundMove = _reduceMotion
                    ? 0
                    : math.sin(progress * math.pi * 2) * 0.7;

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Background artwork.
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(0, backgroundMove),
                        child: Transform.scale(
                          scale: 1.004,
                          child: Image.asset(
                            _backgroundAsset,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackBackground();
                            },
                          ),
                        ),
                      ),
                    ),

                    // Bride photo.
                    Positioned(
                      left: width * 0.145,
                      top: height * 0.177,
                      width: width * 0.295,
                      height: width * 0.295,
                      child: _buildAnimatedPortrait(
                        photo: invitation.bridePhoto,
                        isBride: true,
                      ),
                    ),

                    // Groom photo.
                    Positioned(
                      right: width * 0.145,
                      top: height * 0.177,
                      width: width * 0.295,
                      height: width * 0.295,
                      child: _buildAnimatedPortrait(
                        photo: invitation.groomPhoto,
                        isBride: false,
                      ),
                    ),

                    // Bride name.
                    Positioned(
                      left: width * 0.095,
                      width: width * 0.36,
                      top: height * 0.558,
                      child: _buildAnimatedName(invitation.brideName),
                    ),

                    // Groom name.
                    Positioned(
                      right: width * 0.095,
                      width: width * 0.36,
                      top: height * 0.558,
                      child: _buildAnimatedName(invitation.groomName),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedPortrait({
    required InvitationPhoto? photo,
    required bool isBride,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _portraitAnimation,
        _motionController,
      ]),
      builder: (context, child) {
        final double entrance =
            _portraitAnimation.value.clamp(0.0, 1.0);

        final double progress = _motionController.value;

        final double automaticTilt = _reduceMotion
            ? 0
            : math.sin(
                  progress * math.pi * 2 +
                      (isBride ? 0 : math.pi),
                ) *
                0.004;

        final double tiltY =
            (isBride ? _brideTiltX : _groomTiltX) * 0.014 +
                automaticTilt;

        final double tiltX =
            (isBride ? _brideTiltY : _groomTiltY) * -0.010;

        final double scale = 0.965 + entrance * 0.035;

        return Opacity(
          opacity: entrance,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..rotateX(tiltX)
              ..rotateY(tiltY)
              ..scale(scale),
            child: _buildPortrait(
              photo: photo,
              isBride: isBride,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortrait({
    required InvitationPhoto? photo,
    required bool isBride,
  }) {
    final String url = photo?.url.trim() ?? '';

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onHover: (event) {
        if (!mounted) return;

        final RenderBox? box =
            context.findRenderObject() as RenderBox?;

        if (box == null) return;

        final Offset local = box.globalToLocal(event.position);
        final double centerX = box.size.width / 2;
        final double centerY = box.size.height / 2;

        final double x =
            ((local.dx - centerX) / centerX).clamp(-1.0, 1.0);
        final double y =
            ((local.dy - centerY) / centerY).clamp(-1.0, 1.0);

        setState(() {
          if (isBride) {
            _brideTiltX = x;
            _brideTiltY = y;
          } else {
            _groomTiltX = x;
            _groomTiltY = y;
          }
        });
      },
      onExit: (_) {
        if (!mounted) return;

        setState(() {
          if (isBride) {
            _brideTiltX = 0;
            _brideTiltY = 0;
          } else {
            _groomTiltX = 0;
            _groomTiltY = 0;
          }
        });
      },
      child: ClipOval(
        child: url.isEmpty
            ? _buildPortraitPlaceholder(isBride)
            : Image.network(
                url,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPortraitPlaceholder(isBride);
                },
                loadingBuilder:
                    (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPortraitLoading();
                },
              ),
      ),
    );
  }

  Widget _buildPortraitPlaceholder(bool isBride) {
    return Container(
      color: const Color(0xFFFFF7EF),
      alignment: Alignment.center,
      child: Icon(
        isBride ? Icons.face_3_outlined : Icons.face_6_outlined,
        color: _gold,
        size: 30,
      ),
    );
  }

  Widget _buildPortraitLoading() {
    return Container(
      color: const Color(0xFFFFF7EF),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 1.3,
          color: _gold,
        ),
      ),
    );
  }

  Widget _buildAnimatedName(String name) {
    return AnimatedBuilder(
      animation: _nameAnimation,
      builder: (context, child) {
        final double value =
            _nameAnimation.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(
        name.trim().isEmpty ? 'Name' : name.trim(),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _wine,
          fontSize: 19,
          height: 1.0,
          fontWeight: FontWeight.w500,
          fontFamily: theme.headingFont,
          shadows: [
            Shadow(
              color: Colors.white.withValues(alpha: 0.95),
              blurRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF2E9),
            Color(0xFFF5D9CF),
            Color(0xFFFFF7F1),
          ],
        ),
      ),
    );
  }
}
