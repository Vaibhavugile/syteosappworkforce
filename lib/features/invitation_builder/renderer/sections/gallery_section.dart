import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_photo.dart';
import '../../models/invitation_theme.dart';
import '../../models/invitation_template.dart';

class InvitationGallerySection extends StatefulWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final GalleryStyle galleryStyle;
  final bool isPreview;

  const InvitationGallerySection({
    super.key,
    required this.invitation,
    required this.theme,
    required this.galleryStyle,
    this.isPreview = false,
  });

  @override
  State<InvitationGallerySection> createState() =>
      _InvitationGallerySectionState();
}

class _InvitationGallerySectionState
    extends State<InvitationGallerySection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  int _currentSlide = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1300,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
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
    final photos =
        widget.invitation.galleryPhotos;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 82,
      ),
      color: widget.theme.secondaryColor
          .withValues(alpha: 0.13),
      child: Column(
        children: [
          _buildHeading(),

          const SizedBox(height: 40),

          if (photos.isEmpty)
            _buildEmptyGallery()
          else
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildGallery(photos),
              ),
            ),

          const SizedBox(height: 42),

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
          'OUR MOMENTS',
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
          'A Collection of Memories',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.textColor,
            fontFamily:
                widget.theme.headingFont,
            fontSize: 36,
            height: 1.1,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Little moments that became our favorite memories.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.mutedTextColor,
            fontFamily: widget.theme.bodyFont,
            fontSize: 12,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 16),

        Container(
          width: 55,
          height: 1,
          color: widget.theme.accentColor,
        ),
      ],
    );
  }

  // ===========================================================================
  // GALLERY SELECTOR
  // ===========================================================================

  Widget _buildGallery(
    List<InvitationPhoto> photos,
  ) {
    switch (widget.galleryStyle) {
      case GalleryStyle.grid:
        return _buildGridGallery(photos);

      case GalleryStyle.masonry:
        return _buildMasonryGallery(photos);

      case GalleryStyle.slider:
        return _buildSliderGallery(photos);

      case GalleryStyle.cinematic:
        return _buildCinematicGallery(photos);
    }
  }

  // ===========================================================================
  // GRID
  // ===========================================================================

  Widget _buildGridGallery(
    List<InvitationPhoto> photos,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        return _galleryImage(
          photos[index].url,
          borderRadius: 18,
        );
      },
    );
  }

  // ===========================================================================
  // MASONRY
  // ===========================================================================

  Widget _buildMasonryGallery(
    List<InvitationPhoto> photos,
  ) {
    final List<InvitationPhoto> left =
        <InvitationPhoto>[];

    final List<InvitationPhoto> right =
        <InvitationPhoto>[];

    for (int index = 0;
        index < photos.length;
        index++) {
      if (index.isEven) {
        left.add(photos[index]);
      } else {
        right.add(photos[index]);
      }
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (int index = 0;
                  index < left.length;
                  index++)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: _galleryImage(
                    left[index].url,
                    height:
                        index.isEven
                            ? 240
                            : 180,
                    borderRadius: 20,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 35,
            ),
            child: Column(
              children: [
                for (int index = 0;
                    index < right.length;
                    index++)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: _galleryImage(
                      right[index].url,
                      height:
                          index.isEven
                              ? 180
                              : 240,
                      borderRadius: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SLIDER
  // ===========================================================================

  Widget _buildSliderGallery(
    List<InvitationPhoto> photos,
  ) {
    final int safeIndex =
        _currentSlide.clamp(
      0,
      photos.length - 1,
    );

    return Column(
      children: [
        AnimatedSwitcher(
          duration:
              const Duration(milliseconds: 450),
          transitionBuilder:
              (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.96,
                  end: 1,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: SizedBox(
            key: ValueKey(
              photos[safeIndex].id,
            ),
            width: double.infinity,
            height: 430,
            child: _galleryImage(
              photos[safeIndex].url,
              borderRadius: 28,
            ),
          ),
        ),

        const SizedBox(height: 18),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            _sliderButton(
              icon: Icons.chevron_left_rounded,
              onTap: () {
                setState(() {
                  _currentSlide =
                      (_currentSlide -
                              1 +
                              photos.length) %
                          photos.length;
                });
              },
            ),

            const SizedBox(width: 18),

            Text(
              '${safeIndex + 1} / ${photos.length}',
              style: TextStyle(
                color:
                    widget.theme.mutedTextColor,
                fontFamily:
                    widget.theme.bodyFont,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(width: 18),

            _sliderButton(
              icon: Icons.chevron_right_rounded,
              onTap: () {
                setState(() {
                  _currentSlide =
                      (_currentSlide + 1) %
                          photos.length;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _sliderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(50),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  widget.theme.accentColor
                      .withValues(alpha: 0.55),
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: widget.theme.primaryColor,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CINEMATIC
  // ===========================================================================

  Widget _buildCinematicGallery(
    List<InvitationPhoto> photos,
  ) {
    return Column(
      children: [
        if (photos.isNotEmpty)
          _buildCinematicMain(
            photos.first.url,
          ),

        if (photos.length > 1) ...[
          const SizedBox(height: 10),
          _buildCinematicStrip(
            photos.skip(1).take(4).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCinematicMain(
    String url,
  ) {
    return AspectRatio(
      aspectRatio: 0.88,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _galleryImage(
            url,
            borderRadius: 26,
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(26),
                  gradient:
                      LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(
                        alpha: 0.48,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 25,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'FOREVER MOMENTS',
                  style: TextStyle(
                    color: Colors.white
                        .withValues(alpha: 0.8),
                    fontFamily:
                        widget.theme.bodyFont,
                    fontSize: 8,
                    letterSpacing: 2.5,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Our beautiful beginning',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily:
                        widget.theme.headingFont,
                    fontSize: 25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCinematicStrip(
    List<InvitationPhoto> photos,
  ) {
    return SizedBox(
      height: 115,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 105,
            child: _galleryImage(
              photos[index].url,
              borderRadius: 16,
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // IMAGE
  // ===========================================================================

  Widget _galleryImage(
    String url, {
    double? width,
    double? height,
    double borderRadius = 18,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          borderRadius,
        ),
        border: Border.all(
          color:
              widget.theme.accentColor
                  .withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color:
                widget.theme.primaryColor
                    .withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          borderRadius,
        ),
        child: Image.network(
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
        ),
      ),
    );
  }

  Widget _imagePlaceholder({
    bool loading = false,
  }) {
    return Container(
      color: widget.theme.secondaryColor
          .withValues(alpha: 0.3),
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
                Icons.photo_library_outlined,
                size: 32,
                color:
                    widget.theme.accentColor,
              ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY GALLERY
  // ===========================================================================

  Widget _buildEmptyGallery() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 55,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(26),
        border: Border.all(
          color:
              widget.theme.accentColor
                  .withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 38,
            color: widget.theme.accentColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Your favorite moments will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  widget.theme.mutedTextColor,
              fontFamily:
                  widget.theme.bodyFont,
              fontSize: 13,
            ),
          ),
        ],
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