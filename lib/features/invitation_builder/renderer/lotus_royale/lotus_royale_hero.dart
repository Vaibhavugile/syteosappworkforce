import 'dart:math' as math;



import 'package:flutter/material.dart';



import '../../models/invitation_model.dart';

import '../../models/invitation_theme.dart';



class LotusRoyaleHero extends StatefulWidget {

  final InvitationModel invitation;

  final InvitationTheme theme;

  final bool isPreview;



  const LotusRoyaleHero({

    super.key,

    required this.invitation,

    required this.theme,

    this.isPreview = false,

  });



  @override

  State<LotusRoyaleHero> createState() =>

      _LotusRoyaleHeroState();

}



class _LotusRoyaleHeroState extends State<LotusRoyaleHero>

    with TickerProviderStateMixin {

  // ============================================================

  // ASSET

  // ============================================================



  static const String _heroBackgroundAsset =

      'assets/invitations/lotus_royale/backgrounds/hero.webp';



  // ============================================================

  // ANIMATION CONTROLLERS

  // ============================================================



  late final AnimationController _entranceController;



  late final AnimationController _floatingController;



  late final AnimationController _backgroundController;



  late final Animation<double> _entranceOpacity;



  late final Animation<double> _entranceScale;



  late final Animation<double> _photoOpacity;



  late final Animation<double> _photoScale;



  late final Animation<double> _backgroundScale;



  // ============================================================

  // STATE

  // ============================================================



  bool _isPressed = false;



  double _pointerX = 0;



  double _pointerY = 0;



  @override

  void initState() {

    super.initState();



    // ==========================================================

    // MAIN ENTRANCE

    // ==========================================================



    _entranceController = AnimationController(

      vsync: this,

      duration: const Duration(

        milliseconds: 1800,

      ),

    );



    _entranceOpacity = CurvedAnimation(

      parent: _entranceController,

      curve: const Interval(

        0.0,

        0.55,

        curve: Curves.easeOut,

      ),

    );



    _entranceScale = Tween<double>(

      begin: 0.96,

      end: 1.0,

    ).animate(

      CurvedAnimation(

        parent: _entranceController,

        curve: const Interval(

          0.0,

          0.75,

          curve: Curves.easeOutCubic,

        ),

      ),

    );



    // ==========================================================

    // PHOTO ENTRANCE

    // ==========================================================



    _photoOpacity = CurvedAnimation(

      parent: _entranceController,

      curve: const Interval(

        0.20,

        0.70,

        curve: Curves.easeOut,

      ),

    );



    _photoScale = Tween<double>(

      begin: 0.82,

      end: 1.0,

    ).animate(

      CurvedAnimation(

        parent: _entranceController,

        curve: const Interval(

          0.18,

          0.82,

          curve: Curves.easeOutBack,

        ),

      ),

    );



    // ==========================================================

    // SUBTLE FLOATING

    // ==========================================================



    _floatingController = AnimationController(

      vsync: this,

      duration: const Duration(

        milliseconds: 5000,

      ),

    )..repeat(

        reverse: true,

      );



    // ==========================================================

    // BACKGROUND CINEMATIC ZOOM

    // ==========================================================



    _backgroundController = AnimationController(

      vsync: this,

      duration: const Duration(

        seconds: 16,

      ),

    )..repeat(

        reverse: true,

      );



    _backgroundScale = Tween<double>(

      begin: 1.0,

      end: 1.035,

    ).animate(

      CurvedAnimation(

        parent: _backgroundController,

        curve: Curves.easeInOut,

      ),

    );



    // Start entrance.

    _entranceController.forward();

  }



  @override

  void dispose() {

    _entranceController.dispose();

    _floatingController.dispose();

    _backgroundController.dispose();



    super.dispose();

  }



  // ============================================================

  // BUILD

  // ============================================================



  @override

  Widget build(BuildContext context) {

    return LayoutBuilder(

      builder: (

        context,

        constraints,

      ) {

        final double width =

            constraints.maxWidth;



        // ------------------------------------------------------

        // HERO HEIGHT

        //

        // The hero is intentionally tall because the artwork

        // contains the complete palace/water composition.

        // ------------------------------------------------------



        final double heroHeight = math.max(

          900,

          width * 2.55,

        );



        return AnimatedBuilder(

          animation: Listenable.merge([

            _entranceController,

            _floatingController,

            _backgroundController,

          ]),

          builder: (

            context,

            child,

          ) {

            final double floating =

                math.sin(

                  _floatingController.value *

                      math.pi *

                      2,

                ) *

                3;



            final double floatingSmall =

                math.sin(

                  _floatingController.value *

                      math.pi *

                      2,

                ) *

                1.8;



            return SizedBox(

              width: double.infinity,

              height: heroHeight,

              child: Stack(

                clipBehavior: Clip.hardEdge,

                children: [

                  // ==================================================

                  // BACKGROUND

                  // ==================================================



                  Positioned.fill(

                    child: ClipRect(

                      child: Transform.scale(

                        scale:

                            _backgroundScale.value,

                        child:

                            _buildBackground(),

                      ),

                    ),

                  ),



                  // ==================================================

                  // READABILITY OVERLAY

                  // ==================================================



                  Positioned.fill(

                    child: IgnorePointer(

                      child: DecoratedBox(

                        decoration:

                            BoxDecoration(

                          gradient:

                              LinearGradient(

                            begin:

                                Alignment.topCenter,

                            end:

                                Alignment.bottomCenter,

                            stops: const [

                              0.0,

                              0.16,

                              0.32,

                              0.55,

                              0.72,

                              0.88,

                              1.0,

                            ],

                            colors: [

                              Colors.black

                                  .withValues(

                                alpha: 0.25,

                              ),

                              Colors.black

                                  .withValues(

                                alpha: 0.08,

                              ),

                              Colors

                                  .transparent,

                              Colors

                                  .transparent,

                              Colors.black

                                  .withValues(

                                alpha: 0.05,

                              ),

                              Colors.white

                                  .withValues(

                                alpha: 0.10,

                              ),

                              widget

                                  .theme

                                  .backgroundColor

                                  .withValues(

                                alpha: 0.70,

                              ),

                            ],

                          ),

                        ),

                      ),

                    ),

                  ),



                  // ==================================================

                  // CENTRAL SOFT LIGHT

                  //

                  // Helps text/photo sit naturally inside the arch.

                  // ==================================================



                  Positioned(

                    left: width * 0.05,

                    right: width * 0.05,

                    top: heroHeight * 0.17,

                    height:

                        heroHeight * 0.55,

                    child: IgnorePointer(

                      child: DecoratedBox(

                        decoration:

                            BoxDecoration(

                          borderRadius:

                              BorderRadius.circular(

                            width * 0.45,

                          ),

                          gradient:

                              RadialGradient(

                            center:

                                Alignment.center,

                            radius: 0.78,

                            colors: [

                              Colors.white

                                  .withValues(

                                alpha: 0.14,

                              ),

                              Colors.white

                                  .withValues(

                                alpha: 0.035,

                              ),

                              Colors.transparent,

                            ],

                          ),

                        ),

                      ),

                    ),

                  ),



                  // ==================================================

                  // MAIN CONTENT

                  // ==================================================



                  SafeArea(

                    bottom: false,

                    child: Stack(

                      children: [

                        // =================================================

                        // FAMILY TEXT

                        // =================================================



                        Positioned(

                          top: heroHeight * 0.058,

                          left: 18,

                          right: 18,

                          child: FadeTransition(

                            opacity:

                                _entranceOpacity,

                            child:

                                _buildEyebrow(),

                          ),

                        ),



                        // =================================================

                        // COUPLE NAMES

                        //

                        // Positioned directly inside the arch.

                        // =================================================



                        Positioned(

                          top: heroHeight * 0.125,

                          left: 18,

                          right: 18,

                          child: Opacity(

                            opacity:

                                _entranceOpacity

                                    .value,

                            child:

                                Transform.scale(

                              scale:

                                  _entranceScale

                                      .value,

                              child:

                                  Transform.translate(

                                offset: Offset(

                                  0,

                                  floatingSmall,

                                ),

                                child:

                                    _buildCoupleNames(

                                  width,

                                ),

                              ),

                            ),

                          ),

                        ),



                        // =================================================

                        // COUPLE PHOTO

                        //

                        // This is the most important composition change.

                        //

                        // It sits in the central arch opening instead of

                        // being pushed down by a Column.

                        // =================================================



                        Positioned(

                          top:

                              heroHeight * 0.285,

                          left:

                              width * 0.15,

                          right:

                              width * 0.15,

                          child:

                              FadeTransition(

                            opacity:

                                _photoOpacity,

                            child:

                                _build3DPhoto(

                              width:

                                  width * 0.70,

                              height:

                                  math.min(

                                heroHeight *

                                    0.36,

                                width *

                                    0.94,

                              ),

                              floating:

                                  floating,

                            ),

                          ),

                        ),



                        // =================================================

                        // DATE + TIME

                        //

                        // Positioned over the lower safe area of artwork.

                        // =================================================



                        Positioned(

                          top:

                              heroHeight * 0.765,

                          left: 20,

                          right: 20,

                          child:

                              FadeTransition(

                            opacity:

                                _entranceOpacity,

                            child:

                                _buildWeddingDetails(

                              width,

                            ),

                          ),

                        ),



                        // =================================================

                        // SCROLL HINT

                        // =================================================



                        Positioned(

                          top:

                              heroHeight * 0.895,

                          left: 0,

                          right: 0,

                          child:

                              _buildScrollHint(),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

            );

          },

        );

      },

    );

  }



  // ============================================================

  // BACKGROUND

  // ============================================================



  Widget _buildBackground() {

    return Stack(

      fit: StackFit.expand,

      children: [

        Image.asset(

          _heroBackgroundAsset,



          // Keep the artwork filling the complete hero.

          fit: BoxFit.cover,



          alignment: Alignment.center,



          filterQuality:

              FilterQuality.high,



          errorBuilder: (

            context,

            error,

            stackTrace,

          ) {

            return _buildFallbackBackground();

          },

        ),



        // --------------------------------------------------------

        // WARM CINEMATIC COLOR

        // --------------------------------------------------------



        DecoratedBox(

          decoration: BoxDecoration(

            gradient: LinearGradient(

              begin: Alignment.topCenter,

              end: Alignment.bottomCenter,

              colors: [

                const Color(0xFF35151D)

                    .withValues(

                  alpha: 0.16,

                ),

                Colors.transparent,

                const Color(0xFF6D3042)

                    .withValues(

                  alpha: 0.07,

                ),

              ],

            ),

          ),

        ),

      ],

    );

  }



  Widget _buildFallbackBackground() {

    return DecoratedBox(

      decoration: BoxDecoration(

        gradient: LinearGradient(

          begin: Alignment.topCenter,

          end: Alignment.bottomCenter,

          colors: [

            const Color(0xFFFFF7F1),

            widget.theme.secondaryColor

                .withValues(

              alpha: 0.20,

            ),

            widget.theme.backgroundColor,

          ],

        ),

      ),

    );

  }



  // ============================================================

  // EYEBROW

  // ============================================================



  Widget _buildEyebrow() {

    return Column(

      mainAxisSize: MainAxisSize.min,

      children: [

        Text(

          'TOGETHER WITH OUR FAMILIES',

          textAlign: TextAlign.center,

          style: TextStyle(

            color:

                const Color(0xFFFFF8EC),

            fontSize: 9.5,

            fontWeight:

                FontWeight.w700,

            letterSpacing: 2.3,

            fontFamily:

                widget.theme.bodyFont,

            shadows: const [

              Shadow(

                color:

                    Color(0xDD000000),

                blurRadius: 8,

                offset: Offset(

                  0,

                  2,

                ),

              ),

            ],

          ),

        ),



        const SizedBox(

          height: 8,

        ),



        Container(

          width: 42,

          height: 1,

          decoration:

              BoxDecoration(

            color:

                const Color(0xFFE5C477),

            boxShadow: [

              BoxShadow(

                color:

                    const Color(

                  0xFFE5C477,

                ).withValues(

                  alpha: 0.60,

                ),

                blurRadius: 8,

              ),

            ],

          ),

        ),

      ],

    );

  }



  // ============================================================

  // COUPLE NAMES

  // ============================================================



  Widget _buildCoupleNames(

    double width,

  ) {

    final String bride =

        widget.invitation.brideName

                .trim()

                .isEmpty

            ? 'Bride'

            : widget.invitation

                .brideName

                .trim();



    final String groom =

        widget.invitation.groomName

                .trim()

                .isEmpty

            ? 'Groom'

            : widget.invitation

                .groomName

                .trim();



    final double nameSize =

        width < 380 ? 39 : 43;



    return Column(

      mainAxisSize: MainAxisSize.min,

      children: [

        _buildName(

          bride,

          size: nameSize,

        ),



        Transform.translate(

          offset: const Offset(

            0,

            -2,

          ),

          child: Text(

            '&',

            textAlign: TextAlign.center,

            style: TextStyle(

              color:

                  const Color(

                0xFFE7C875,

              ),

              fontSize: 30,

              height: 0.95,

              fontFamily:

                  widget.theme.scriptFont,

              shadows: const [

                Shadow(

                  color:

                      Color(0xCC000000),

                  blurRadius: 9,

                  offset: Offset(

                    0,

                    2,

                  ),

                ),

              ],

            ),

          ),

        ),



        _buildName(

          groom,

          size: nameSize,

        ),

      ],

    );

  }



  Widget _buildName(

    String name, {

    required double size,

  }) {

    return Text(

      name,

      textAlign: TextAlign.center,

      maxLines: 1,

      overflow:

          TextOverflow.ellipsis,

      style: TextStyle(

        color:

            const Color(0xFFFFF9EF),

        fontSize: size,

        height: 0.98,

        fontWeight:

            FontWeight.w600,

        fontFamily:

            widget.theme.headingFont,

        letterSpacing: 0.1,

        shadows: const [

          Shadow(

            color:

                Color(0xEE000000),

            blurRadius: 9,

            offset: Offset(

              0,

              3,

            ),

          ),

          Shadow(

            color:

                Color(0x88000000),

            blurRadius: 18,

          ),

        ],

      ),

    );

  }



  // ============================================================

  // 3D PHOTO

  // ============================================================



  Widget _build3DPhoto({

    required double width,

    required double height,

    required double floating,

  }) {

    final double normalizedX =

        _pointerX.clamp(

              -1.0,

              1.0,

            );



    final double normalizedY =

        _pointerY.clamp(

              -1.0,

              1.0,

            );



    final double autoTilt =

        math.sin(

          _floatingController.value *

              math.pi *

              2,

        ) *

        0.008;



    final double rotateY =

        (normalizedX * 0.025) +

            autoTilt;



    final double rotateX =

        (-normalizedY * 0.018) +

            (autoTilt * 0.5);



    return MouseRegion(

      onEnter: (_) {

        setState(() {

          _isPressed = true;

        });

      },

      onExit: (_) {

        setState(() {

          _isPressed = false;

          _pointerX = 0;

          _pointerY = 0;

        });

      },

      onHover: (event) {

        final RenderBox? box =

            context.findRenderObject()

                as RenderBox?;



        if (box == null) {

          return;

        }



        final Offset local =

            box.globalToLocal(

          event.position,

        );



        final double centerX =

            box.size.width / 2;



        final double centerY =

            box.size.height / 2;



        setState(() {

          _pointerX =

              (local.dx - centerX) /

                  centerX;



          _pointerY =

              (local.dy - centerY) /

                  centerY;

        });

      },

      child: AnimatedScale(

        scale: _isPressed ? 1.015 : 1.0,

        duration:

            const Duration(

          milliseconds: 250,

        ),

        curve:

            Curves.easeOutCubic,

        child: Transform(

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

                  rotateX,

                )

                ..rotateY(

                  rotateY,

                )

                ..translate(

                  0.0,

                  floating,

                ),

          child:

              _buildCouplePhoto(

            width,

            height,

          ),

        ),

      ),

    );

  }



  // ============================================================

  // COUPLE PHOTO

  // ============================================================



  Widget _buildCouplePhoto(

    double width,

    double height,

  ) {

    final String? imageUrl =

        widget.invitation

            .couplePhoto

            ?.url;



    final double radius =

        width * 0.28;



    if (imageUrl == null ||

        imageUrl.trim().isEmpty) {

      return _buildPhotoPlaceholder(

        width,

        height,

        radius,

      );

    }



    return Container(

      width: width,

      height: height,

      padding:

          const EdgeInsets.all(7),

      decoration: BoxDecoration(

        borderRadius:

            BorderRadius.circular(

          radius,

        ),

        border: Border.all(

          color:

              const Color(

            0xFFE2B967,

          ),

          width: 1.5,

        ),

        boxShadow: [

          BoxShadow(

            color:

                Colors.black.withValues(

              alpha: 0.22,

            ),

            blurRadius: 30,

            spreadRadius: 2,

            offset: const Offset(

              0,

              14,

            ),

          ),

          BoxShadow(

            color:

                const Color(

              0xFFE0B866,

            ).withValues(

              alpha: 0.28,

            ),

            blurRadius: 22,

          ),

        ],

      ),

      child: ClipRRect(

        borderRadius:

            BorderRadius.circular(

          radius - 5,

        ),

        child: Image.network(

          imageUrl,

          fit: BoxFit.cover,

          errorBuilder: (

            context,

            error,

            stackTrace,

          ) {

            return _buildPhotoPlaceholder(

              width,

              height,

              radius,

            );

          },

          loadingBuilder: (

            context,

            child,

            progress,

          ) {

            if (progress == null) {

              return child;

            }



            return _buildPhotoLoading(

              width,

              height,

              radius,

            );

          },

        ),

      ),

    );

  }



  Widget _buildPhotoPlaceholder(

    double width,

    double height,

    double radius,

  ) {

    return Container(

      width: width,

      height: height,

      decoration:

          BoxDecoration(

        color:

            const Color(

          0xFFF5E5DB,

        ).withValues(

          alpha: 0.94,

        ),

        borderRadius:

            BorderRadius.circular(

          radius,

        ),

        border: Border.all(

          color:

              const Color(

            0xFFD3A85F,

          ).withValues(

            alpha: 0.75,

          ),

          width: 1.4,

        ),

        boxShadow: [

          BoxShadow(

            color:

                Colors.black.withValues(

              alpha: 0.15,

            ),

            blurRadius: 25,

            offset: const Offset(

              0,

              12,

            ),

          ),

        ],

      ),

      child: Center(

        child: Column(

          mainAxisSize:

              MainAxisSize.min,

          children: [

            Container(

              width: 58,

              height: 58,

              decoration:

                  BoxDecoration(

                shape:

                    BoxShape.circle,

                color:

                    Colors.white

                        .withValues(

                  alpha: 0.70,

                ),

                border:

                    Border.all(

                  color:

                      const Color(

                    0xFFD3A85F,

                  ).withValues(

                    alpha: 0.55,

                  ),

                ),

              ),

              child: const Icon(

                Icons

                    .photo_camera_outlined,

                size: 28,

                color:

                    Color(

                  0xFFC09650,

                ),

              ),

            ),



            const SizedBox(

              height: 13,

            ),



            const Text(

              'YOUR COUPLE PHOTO',

              textAlign:

                  TextAlign.center,

              style: TextStyle(

                color:

                    Color(

                  0xFF4B302C,

                ),

                fontSize: 10,

                fontWeight:

                    FontWeight.w700,

                letterSpacing: 1.25,

              ),

            ),



            const SizedBox(

              height: 5,

            ),



            Text(

              'A beautiful moment together',

              textAlign:

                  TextAlign.center,

              style: TextStyle(

                color:

                    widget.theme

                        .mutedTextColor,

                fontSize: 9,

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildPhotoLoading(

    double width,

    double height,

    double radius,

  ) {

    return Container(

      width: width,

      height: height,

      decoration:

          BoxDecoration(

        color:

            const Color(

          0xFFF1DED3,

        ),

        borderRadius:

            BorderRadius.circular(

          radius,

        ),

      ),

      alignment:

          Alignment.center,

      child: const SizedBox(

        width: 25,

        height: 25,

        child:

            CircularProgressIndicator(

          strokeWidth: 1.5,

          color:

              Color(0xFFC09650),

        ),

      ),

    );

  }



  // ============================================================

  // WEDDING DETAILS

  // ============================================================



  Widget _buildWeddingDetails(

    double width,

  ) {

    final bool hasDate =

        widget.invitation.weddingDate

            .trim()

            .isNotEmpty;



    final bool hasTime =

        widget.invitation.weddingTime

            .trim()

            .isNotEmpty;



    final bool hasVenue =

        widget.invitation.venueName

            .trim()

            .isNotEmpty;



    return Column(

      mainAxisSize:

          MainAxisSize.min,

      children: [

        // --------------------------------------------------------

        // DATE + TIME

        // --------------------------------------------------------



        if (hasDate || hasTime)

          Container(

            constraints:

                BoxConstraints(

              maxWidth:

                  width * 0.88,

            ),

            padding:

                const EdgeInsets

                    .symmetric(

              horizontal: 14,

              vertical: 7,

            ),

            decoration:

                BoxDecoration(

              color:

                  Colors.black

                      .withValues(

                alpha: 0.22,

              ),

              borderRadius:

                  BorderRadius.circular(

                30,

              ),

              border:

                  Border.all(

                color:

                    Colors.white

                        .withValues(

                  alpha: 0.28,

                ),

              ),

              boxShadow: [

                BoxShadow(

                  color:

                      Colors.black

                          .withValues(

                    alpha: 0.16,

                  ),

                  blurRadius: 16,

                ),

              ],

            ),

            child: Row(

              mainAxisSize:

                  MainAxisSize.min,

              children: [

                if (hasDate)

                  Flexible(

                    child:

                        Text(

                      widget

                          .invitation

                          .weddingDate

                          .trim(),

                      textAlign:

                          TextAlign.center,

                      style:

                          const TextStyle(

                        color:

                            Color(

                          0xFFFFF8EC,

                        ),

                        fontSize: 11.5,

                        fontWeight:

                            FontWeight.w600,

                        letterSpacing:

                            0.45,

                        shadows: [

                          Shadow(

                            color:

                                Colors.black,

                            blurRadius:

                                6,

                          ),

                        ],

                      ),

                    ),

                  ),



                if (hasDate &&

                    hasTime)

                  const Padding(

                    padding:

                        EdgeInsets

                            .symmetric(

                      horizontal: 8,

                    ),

                    child:

                        Text(

                      '•',

                      style:

                          TextStyle(

                        color:

                            Color(

                          0xFFE6C477,

                        ),

                        fontSize: 13,

                        fontWeight:

                            FontWeight

                                .bold,

                      ),

                    ),

                  ),



                if (hasTime)

                  Flexible(

                    child:

                        Text(

                      widget

                          .invitation

                          .weddingTime

                          .trim(),

                      textAlign:

                          TextAlign.center,

                      style:

                          const TextStyle(

                        color:

                            Color(

                          0xFFFFF8EC,

                        ),

                        fontSize: 11.5,

                        fontWeight:

                            FontWeight.w600,

                        letterSpacing:

                            0.45,

                        shadows: [

                          Shadow(

                            color:

                                Colors.black,

                            blurRadius:

                                6,

                          ),

                        ],

                      ),

                    ),

                  ),

              ],

            ),

          ),



        // --------------------------------------------------------

        // VENUE

        // --------------------------------------------------------



        if (hasVenue) ...[

          const SizedBox(

            height: 8,

          ),



          Text(

            widget.invitation

                .venueName

                .trim(),

            textAlign:

                TextAlign.center,

            maxLines: 2,

            overflow:

                TextOverflow.ellipsis,

            style:

                const TextStyle(

              color:

                  Color(0xFFFFE6A9),

              fontSize: 14.5,

              fontWeight:

                  FontWeight.w700,

              letterSpacing:

                  0.15,

              shadows: [

                Shadow(

                  color:

                      Colors.black,

                  blurRadius: 9,

                  offset:

                      Offset(

                    0,

                    2,

                  ),

                ),

              ],

            ),

          ),

        ],



        // --------------------------------------------------------

        // ADDRESS

        // --------------------------------------------------------



        if (widget.invitation

            .venueAddress

            .trim()

            .isNotEmpty) ...[

          const SizedBox(

            height: 3,

          ),



          Padding(

            padding:

                const EdgeInsets

                    .symmetric(

              horizontal: 28,

            ),

            child:

                Text(

              widget.invitation

                  .venueAddress

                  .trim(),

              textAlign:

                  TextAlign.center,

              maxLines: 2,

              overflow:

                  TextOverflow

                      .ellipsis,

              style:

                  const TextStyle(

                color:

                    Color(

                  0xFFFFF8EC,

                ),

                fontSize: 10,

                height: 1.35,

                shadows: [

                  Shadow(

                    color:

                        Colors.black,

                    blurRadius:

                        7,

                  ),

                ],

              ),

            ),

          ),

        ],

      ],

    );

  }



  // ============================================================

  // SCROLL HINT

  // ============================================================



  Widget _buildScrollHint() {

    return AnimatedBuilder(

      animation:

          _floatingController,

      builder: (

        context,

        child,

      ) {

        final double offset =

            math.sin(

              _floatingController

                      .value *

                  math.pi *

                  2,

            ) *

            4;



        return Transform.translate(

          offset: Offset(

            0,

            offset,

          ),

          child: Column(

            mainAxisSize:

                MainAxisSize.min,

            children: [

              const Text(

                'SCROLL TO EXPLORE',

                style:

                    TextStyle(

                  color:

                      Color(

                    0xFFFFF8EC,

                  ),

                  fontSize: 7.5,

                  fontWeight:

                      FontWeight.w600,

                  letterSpacing: 1.9,

                  shadows: [

                    Shadow(

                      color:

                          Colors.black,

                      blurRadius:

                          6,

                    ),

                  ],

                ),

              ),



              const SizedBox(

                height: 5,

              ),



              const Icon(

                Icons

                    .keyboard_arrow_down_rounded,

                size: 21,

                color:

                    Color(

                  0xFFE6C477,

                ),

              ),

            ],

          ),

        );

      },

    );

  }

}