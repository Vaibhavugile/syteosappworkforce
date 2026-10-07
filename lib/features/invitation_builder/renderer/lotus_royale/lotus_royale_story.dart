import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_photo.dart';
import '../../models/invitation_theme.dart';

class LotusRoyaleStory extends StatefulWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const LotusRoyaleStory({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  @override
  State<LotusRoyaleStory> createState() =>
      _LotusRoyaleStoryState();
}

class _LotusRoyaleStoryState
    extends State<LotusRoyaleStory>
    with TickerProviderStateMixin {
  static const String _backgroundAsset =
      'assets/invitations/lotus_royale/backgrounds/story.webp';

  late final AnimationController _motionController;
  late final AnimationController _entranceController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _titleAnimation;
  late final Animation<double> _contentAnimation;
  late final Animation<double> _photoAnimation;
  late final Animation<double> _quoteAnimation;

  bool _reduceMotion = false;

  InvitationModel get invitation => widget.invitation;

  InvitationTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();

    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 8,
      ),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.0,
        0.32,
        curve: Curves.easeOut,
      ),
    );

    _titleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.12,
        0.52,
        curve: Curves.easeOutCubic,
      ),
    );

    _contentAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.30,
        0.72,
        curve: Curves.easeOutCubic,
      ),
    );

    _photoAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.46,
        0.88,
        curve: Curves.easeOutBack,
      ),
    );

    _quoteAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.68,
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        _reduceMotion =
            MediaQuery.maybeOf(context)
                    ?.disableAnimations ??
                false;

        if (_reduceMotion) {
          _entranceController.value = 1;
          _motionController.stop();
        } else {
          _entranceController.forward();
        }

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _motionController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<InvitationPhoto> photos =
        invitation.storyPhotos
            .take(3)
            .toList();

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final double width =
            constraints.maxWidth;

        return Container(
          width: double.infinity,
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          color: const Color(
            0xFFFFF7F1,
          ),
          child: AnimatedBuilder(
            animation: _motionController,
            builder: (
              context,
              child,
            ) {
              final double progress =
                  _motionController.value;

              final double backgroundOffset =
                  _reduceMotion
                      ? 0
                      : math.sin(
                            progress *
                                math.pi *
                                2,
                          ) *
                          5;

              final double petalOffset =
                  _reduceMotion
                      ? 0
                      : math.sin(
                            progress *
                                math.pi *
                                2,
                          ) *
                          7;

              return Stack(
                children: [
                  // =================================================
                  // BACKGROUND WITH SLOW PARALLAX
                  // =================================================

                  Positioned.fill(
                    child: ClipRect(
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          backgroundOffset,
                        ),
                        child: Transform.scale(
                          scale: 1.025,
                          child: Image.asset(
                            _backgroundAsset,
                            fit: BoxFit.cover,
                            alignment:
                                Alignment.center,
                            filterQuality:
                                FilterQuality.high,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return Container(
                                decoration:
                                    const BoxDecoration(
                                  gradient:
                                      LinearGradient(
                                    begin:
                                        Alignment
                                            .topCenter,
                                    end:
                                        Alignment
                                            .bottomCenter,
                                    colors: [
                                      Color(
                                        0xFFFFF8F1,
                                      ),
                                      Color(
                                        0xFFF8E8DE,
                                      ),
                                      Color(
                                        0xFFFFF5ED,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // =================================================
                  // READABILITY LAYER
                  // =================================================

                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration:
                            BoxDecoration(
                          gradient:
                              LinearGradient(
                            begin:
                                Alignment
                                    .topCenter,
                            end:
                                Alignment
                                    .bottomCenter,
                            colors: [
                              Colors.white
                                  .withValues(
                                alpha: 0.60,
                              ),
                              Colors.white
                                  .withValues(
                                alpha: 0.78,
                              ),
                              Colors.white
                                  .withValues(
                                alpha: 0.52,
                              ),
                            ],
                            stops: const [
                              0.0,
                              0.52,
                              1.0,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // =================================================
                  // FLOATING PETALS
                  // =================================================

                  if (!_reduceMotion)
                    Positioned.fill(
                      child: IgnorePointer(
                        child:
                            _buildFloatingPetals(
                          progress,
                          petalOffset,
                        ),
                      ),
                    ),

                  // =================================================
                  // MAIN CONTENT
                  // =================================================

                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(
                      width < 380
                          ? 22
                          : 28,
                      38,
                      width < 380
                          ? 22
                          : 28,
                      42,
                    ),
                    child: Column(
                      children: [
                        // -------------------------------------------
                        // EYEBROW
                        // -------------------------------------------

                        FadeTransition(
                          opacity:
                              _fadeAnimation,
                          child:
                              _buildEyebrow(),
                        ),

                        const SizedBox(
                          height: 9,
                        ),

                        // -------------------------------------------
                        // TITLE
                        // -------------------------------------------

                        AnimatedBuilder(
                          animation:
                              _titleAnimation,
                          builder: (
                            context,
                            child,
                          ) {
                            final double
                                value =
                                _titleAnimation
                                    .value;

                            return Opacity(
                              opacity: value
                                  .clamp(
                                0.0,
                                1.0,
                              ),
                              child:
                                  Transform.translate(
                                offset:
                                    Offset(
                                  0,
                                  20 *
                                      (1 -
                                          value),
                                ),
                                child:
                                    child,
                              ),
                            );
                          },
                          child:
                              _buildTitle(),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _buildDivider(),

                        const SizedBox(
                          height: 22,
                        ),

                        // -------------------------------------------
                        // STORY TEXT
                        // -------------------------------------------

                        AnimatedBuilder(
                          animation:
                              _contentAnimation,
                          builder: (
                            context,
                            child,
                          ) {
                            final double
                                value =
                                _contentAnimation
                                    .value;

                            return Opacity(
                              opacity: value
                                  .clamp(
                                0.0,
                                1.0,
                              ),
                              child:
                                  Transform.translate(
                                offset:
                                    Offset(
                                  0,
                                  18 *
                                      (1 -
                                          value),
                                ),
                                child:
                                    child,
                              ),
                            );
                          },
                          child:
                              invitation
                                      .storyText
                                      .trim()
                                      .isNotEmpty
                                  ? _buildStoryText(
                                      width,
                                    )
                                  : const SizedBox
                                      .shrink(),
                        ),

                        const SizedBox(
                          height: 25,
                        ),

                        // -------------------------------------------
                        // PHOTO
                        // -------------------------------------------

                        AnimatedBuilder(
                          animation:
                              _photoAnimation,
                          builder: (
                            context,
                            child,
                          ) {
                            final double
                                value =
                                _photoAnimation
                                    .value;

                            final double
                                scale =
                                0.90 +
                                    (0.10 *
                                        value);

                            return Opacity(
                              opacity: value
                                  .clamp(
                                0.0,
                                1.0,
                              ),
                              child:
                                  Transform.scale(
                                scale: scale,
                                child:
                                    child,
                              ),
                            );
                          },
                          child:
                              photos.isEmpty
                                  ? _buildPhotoPlaceholder(
                                      width,
                                    )
                                  : _buildStoryPhotos(
                                      photos,
                                      width,
                                    ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // -------------------------------------------
                        // QUOTE
                        // -------------------------------------------

                        AnimatedBuilder(
                          animation:
                              _quoteAnimation,
                          builder: (
                            context,
                            child,
                          ) {
                            final double
                                value =
                                _quoteAnimation
                                    .value;

                            final double
                                float =
                                _reduceMotion
                                    ? 0
                                    : math.sin(
                                          progress *
                                              math.pi *
                                              2,
                                        ) *
                                        2.5;

                            return Opacity(
                              opacity: value
                                  .clamp(
                                0.0,
                                1.0,
                              ),
                              child:
                                  Transform.translate(
                                offset:
                                    Offset(
                                  0,
                                  14 *
                                          (1 -
                                              value) +
                                      float,
                                ),
                                child:
                                    child,
                              ),
                            );
                          },
                          child:
                              _buildQuote(
                            width,
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        _buildBottomOrnament(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ==============================================================
  // FLOATING PETALS
  // ==============================================================

  Widget _buildFloatingPetals(
    double progress,
    double petalOffset,
  ) {
    final List<_PetalData> petals = [
      const _PetalData(
        left: 0.12,
        top: 0.23,
        size: 12,
        speed: 1.0,
        rotation: 0.25,
      ),
      const _PetalData(
        left: 0.82,
        top: 0.31,
        size: 9,
        speed: 1.35,
        rotation: -0.35,
      ),
      const _PetalData(
        left: 0.19,
        top: 0.55,
        size: 8,
        speed: 0.8,
        rotation: 0.5,
      ),
      const _PetalData(
        left: 0.76,
        top: 0.66,
        size: 11,
        speed: 1.15,
        rotation: -0.2,
      ),
    ];

    return Stack(
      children: petals.map(
        (
          petal,
        ) {
          final double wave =
              math.sin(
                    progress *
                        math.pi *
                        2 *
                        petal.speed,
                  ) *
                  10;

          final double vertical =
              math.cos(
                    progress *
                        math.pi *
                        2 *
                        petal.speed,
                  ) *
                  6;

          return Positioned(
            left:
                MediaQuery.sizeOf(
                      context,
                    ).width *
                    petal.left,
            top:
                MediaQuery.sizeOf(
                      context,
                    ).height *
                        petal.top *
                        0.55 +
                    vertical +
                    petalOffset,
            child: Transform.rotate(
              angle:
                  petal.rotation +
                  wave *
                      0.015,
              child: _buildPetal(
                petal.size,
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildPetal(
    double size,
  ) {
    return SizedBox(
      width: size,
      height: size * 1.45,
      child: CustomPaint(
        painter:
            _StoryPetalPainter(),
      ),
    );
  }

  // ==============================================================
  // EYEBROW
  // ==============================================================

  Widget _buildEyebrow() {
    return Text(
      'OUR STORY',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(
          0xFF9C6B43,
        ),
        fontSize: 9.5,
        fontWeight:
            FontWeight.w700,
        letterSpacing: 3.0,
        fontFamily:
            theme.bodyFont,
        shadows: [
          Shadow(
            color:
                Colors.white
                    .withValues(
              alpha: 0.9,
            ),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // TITLE
  // ==============================================================

  Widget _buildTitle() {
    final String title =
        invitation.storyTitle
                .trim()
                .isNotEmpty
            ? invitation.storyTitle
                .trim()
            : 'A Story Written in Love';

    return Text(
      title,
      textAlign:
          TextAlign.center,
      maxLines: 2,
      overflow:
          TextOverflow.ellipsis,
      style: TextStyle(
        color: const Color(
          0xFF713B4C,
        ),
        fontSize: 27,
        height: 1.08,
        fontWeight:
            FontWeight.w500,
        fontFamily:
            theme.headingFont,
        shadows: [
          Shadow(
            color:
                Colors.white
                    .withValues(
              alpha: 0.95,
            ),
            blurRadius: 7,
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // DIVIDER
  // ==============================================================

  Widget _buildDivider() {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 1,
          color:
              const Color(
            0xFFC9A05B,
          ).withValues(
            alpha: 0.75,
          ),
        ),
        const SizedBox(
          width: 9,
        ),
        const Icon(
          Icons.favorite_rounded,
          size: 9,
          color:
              Color(
            0xFFC9A05B,
          ),
        ),
        const SizedBox(
          width: 9,
        ),
        Container(
          width: 42,
          height: 1,
          color:
              const Color(
            0xFFC9A05B,
          ).withValues(
            alpha: 0.75,
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // STORY TEXT
  // ==============================================================

  Widget _buildStoryText(
    double width,
  ) {
    return Container(
      constraints:
          const BoxConstraints(
        maxWidth: 520,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 5,
      ),
      child: Text(
        invitation.storyText.trim(),
        textAlign:
            TextAlign.center,
        style: TextStyle(
          color: const Color(
            0xFF4D3934,
          ),
          fontSize:
              width < 380
                  ? 13
                  : 13.5,
          height: 1.65,
          fontWeight:
              FontWeight.w400,
          fontFamily:
              theme.bodyFont,
          shadows: [
            Shadow(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.95,
              ),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // STORY PHOTOS
  // ==============================================================

  Widget _buildStoryPhotos(
    List<InvitationPhoto> photos,
    double width,
  ) {
    if (photos.length == 1) {
      return _buildSinglePhoto(
        photos.first,
        width,
      );
    }

    if (photos.length == 2) {
      return _buildTwoPhotos(
        photos,
        width,
      );
    }

    return _buildThreePhotos(
      photos,
      width,
    );
  }

  // ==============================================================
  // SINGLE PHOTO - 3D
  // ==============================================================

  Widget _buildSinglePhoto(
    InvitationPhoto photo,
    double width,
  ) {
    final double photoWidth =
        width < 380
            ? 190
            : 215;

    final double photoHeight =
        photoWidth * 1.18;

    return AnimatedBuilder(
      animation:
          _motionController,
      builder: (
        context,
        child,
      ) {
        final double progress =
            _motionController.value;

        final double tilt =
            _reduceMotion
                ? 0
                : math.sin(
                      progress *
                          math.pi *
                          2,
                    ) *
                    0.018;

        final double y =
            _reduceMotion
                ? 0
                : math.sin(
                      progress *
                          math.pi *
                          2,
                    ) *
                    3;

        return Transform(
          alignment:
              Alignment.center,
          transform:
              Matrix4.identity()
                ..setEntry(
                  3,
                  2,
                  0.0012,
                )
                ..rotateX(
                  tilt * 0.35,
                )
                ..rotateY(
                  tilt,
                )
                ..translate(
                  0.0,
                  y,
                ),
          child: child,
        );
      },
      child: _buildPhotoFrame(
        photo: photo,
        width: photoWidth,
        height: photoHeight,
      ),
    );
  }

  // ==============================================================
  // TWO PHOTOS
  // ==============================================================

  Widget _buildTwoPhotos(
    List<InvitationPhoto> photos,
    double width,
  ) {
    final double firstWidth =
        width < 380
            ? 125
            : 140;

    final double secondWidth =
        width < 380
            ? 135
            : 150;

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Transform(
          alignment:
              Alignment.center,
          transform:
              Matrix4.identity()
                ..setEntry(
                  3,
                  2,
                  0.001,
                )
                ..rotateY(
                  -0.035,
                ),
          child: Transform.rotate(
            angle: -0.045,
            child:
                _buildPhotoFrame(
              photo: photos[0],
              width: firstWidth,
              height:
                  firstWidth *
                      1.25,
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Transform(
          alignment:
              Alignment.center,
          transform:
              Matrix4.identity()
                ..setEntry(
                  3,
                  2,
                  0.001,
                )
                ..rotateY(
                  0.035,
                ),
          child: Transform.rotate(
            angle: 0.045,
            child:
                _buildPhotoFrame(
              photo: photos[1],
              width: secondWidth,
              height:
                  secondWidth *
                      1.25,
            ),
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // THREE PHOTOS
  // ==============================================================

  Widget _buildThreePhotos(
    List<InvitationPhoto> photos,
    double width,
  ) {
    final double sideWidth =
        width < 380
            ? 105
            : 115;

    final double centerWidth =
        width < 380
            ? 130
            : 140;

    return SizedBox(
      height: 205,
      child: Stack(
        alignment:
            Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 30,
            child: Transform(
              alignment:
                  Alignment.center,
              transform:
                  Matrix4.identity()
                    ..setEntry(
                      3,
                      2,
                      0.001,
                    )
                    ..rotateY(
                      -0.06,
                    ),
              child:
                  Transform.rotate(
                angle: -0.07,
                child:
                    _buildPhotoFrame(
                  photo:
                      photos[0],
                  width:
                      sideWidth,
                  height:
                      sideWidth *
                          1.22,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 20,
            child: Transform(
              alignment:
                  Alignment.center,
              transform:
                  Matrix4.identity()
                    ..setEntry(
                      3,
                      2,
                      0.001,
                    )
                    ..rotateY(
                      0.06,
                    ),
              child:
                  Transform.rotate(
                angle: 0.07,
                child:
                    _buildPhotoFrame(
                  photo:
                      photos[2],
                  width:
                      sideWidth,
                  height:
                      sideWidth *
                          1.22,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child:
                _buildPhotoFrame(
              photo:
                  photos[1],
              width:
                  centerWidth,
              height:
                  centerWidth *
                      1.25,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // PHOTO FRAME
  // ==============================================================

  Widget _buildPhotoFrame({
    required InvitationPhoto photo,
    required double width,
    required double height,
  }) {
    final String url =
        photo.url.trim();

    return Container(
      width: width + 12,
      height: height + 12,
      padding:
          const EdgeInsets.all(
        6,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFC9A05B,
          ),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha: 0.14,
            ),
            blurRadius: 20,
            offset:
                const Offset(
              0,
              10,
            ),
          ),
          BoxShadow(
            color:
                const Color(
              0xFFC9A05B,
            ).withValues(
              alpha: 0.12,
            ),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        child: url.isEmpty
            ? _buildEmptyPhoto()
            : Image.network(
                url,
                fit: BoxFit.cover,
                filterQuality:
                    FilterQuality.high,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return _buildEmptyPhoto();
                },
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress ==
                      null) {
                    return child;
                  }

                  return _buildLoadingPhoto();
                },
              ),
      ),
    );
  }

  // ==============================================================
  // EMPTY PHOTO
  // ==============================================================

  Widget _buildEmptyPhoto() {
    return Container(
      color: const Color(
        0xFFFFF8F2,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    const Color(
                  0xFFF4E7DC,
                ),
                border: Border.all(
                  color:
                      const Color(
                    0xFFC9A05B,
                  ).withValues(
                    alpha: 0.65,
                  ),
                ),
              ),
              child:
                  const Icon(
                Icons
                    .photo_camera_outlined,
                size: 23,
                color:
                    Color(
                  0xFFC09650,
                ),
              ),
            ),
            const SizedBox(
              height: 9,
            ),
            const Text(
              'STORY PHOTO',
              style: TextStyle(
                color:
                    Color(
                  0xFF713B4C,
                ),
                fontSize: 8,
                fontWeight:
                    FontWeight.w700,
                letterSpacing:
                    1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // LOADING
  // ==============================================================

  Widget _buildLoadingPhoto() {
    return Container(
      color: const Color(
        0xFFFFF8F2,
      ),
      alignment:
          Alignment.center,
      child:
          const SizedBox(
        width: 21,
        height: 21,
        child:
            CircularProgressIndicator(
          strokeWidth: 1.5,
          color:
              Color(
            0xFFC09650,
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // PHOTO PLACEHOLDER
  // ==============================================================

  Widget _buildPhotoPlaceholder(
    double width,
  ) {
    final double placeholderWidth =
        width < 380
            ? 205
            : 225;

    return Container(
      width:
          placeholderWidth,
      height: 125,
      decoration:
          BoxDecoration(
        color: Colors.white
            .withValues(
          alpha: 0.72,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFC9A05B,
          ).withValues(
            alpha: 0.60,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha: 0.06,
            ),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons
                .photo_library_outlined,
            size: 28,
            color:
                Color(
              0xFFC09650,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            'ADD YOUR STORY PHOTOS',
            style: TextStyle(
              color:
                  const Color(
                0xFF713B4C,
              ),
              fontSize: 8.5,
              fontWeight:
                  FontWeight.w700,
              letterSpacing:
                  1.2,
              fontFamily:
                  theme.bodyFont,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // QUOTE
  // ==============================================================

  Widget _buildQuote(
    double width,
  ) {
    return Container(
      constraints:
          const BoxConstraints(
        maxWidth: 360,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white
            .withValues(
          alpha: 0.72,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFC9A05B,
          ).withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Text(
        '“Every love story is beautiful, '
        'but ours is our favorite.”',
        textAlign:
            TextAlign.center,
        style: TextStyle(
          color:
              const Color(
            0xFF713B4C,
          ),
          fontSize: 11.5,
          height: 1.45,
          fontStyle:
              FontStyle.italic,
          fontFamily:
              theme.bodyFont,
        ),
      ),
    );
  }

  // ==============================================================
  // BOTTOM ORNAMENT
  // ==============================================================

  Widget _buildBottomOrnament() {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 1,
          color:
              const Color(
            0xFFC9A05B,
          ).withValues(
            alpha: 0.65,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        const Icon(
          Icons.auto_awesome,
          size: 11,
          color:
              Color(
            0xFFC9A05B,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Container(
          width: 42,
          height: 1,
          color:
              const Color(
            0xFFC9A05B,
          ).withValues(
            alpha: 0.65,
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// PETAL DATA
// ==================================================================

class _PetalData {
  final double left;
  final double top;
  final double size;
  final double speed;
  final double rotation;

  const _PetalData({
    required this.left,
    required this.top,
    required this.size,
    required this.speed,
    required this.rotation,
  });
}

// ==================================================================
// PETAL PAINTER
// ==================================================================

class _StoryPetalPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Paint paint =
        Paint()
          ..shader =
              const LinearGradient(
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
                colors: [
                  Color(
                    0xFFFFA5B8,
                  ),
                  Color(
                    0xFFE76D88,
                  ),
                ],
              ).createShader(
                Rect.fromLTWH(
                  0,
                  0,
                  size.width,
                  size.height,
                ),
              );

    final Path path =
        Path();

    path.moveTo(
      size.width * 0.5,
      0,
    );

    path.cubicTo(
      size.width * 0.95,
      size.height * 0.20,
      size.width * 0.90,
      size.height * 0.72,
      size.width * 0.52,
      size.height,
    );

    path.cubicTo(
      size.width * 0.12,
      size.height * 0.72,
      size.width * 0.05,
      size.height * 0.20,
      size.width * 0.5,
      0,
    );

    path.close();

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}