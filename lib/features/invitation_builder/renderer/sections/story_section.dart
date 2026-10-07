import 'package:flutter/material.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';

class InvitationStorySection extends StatefulWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const InvitationStorySection({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  @override
  State<InvitationStorySection> createState() =>
      _InvitationStorySectionState();
}

class _InvitationStorySectionState
    extends State<InvitationStorySection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1200,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
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
    final storyPhotos =
        widget.invitation.storyPhotos;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 80,
      ),
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
      ),
      child: Column(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildSectionHeading(),
          ),

          const SizedBox(height: 34),

          SlideTransition(
            position: _slideAnimation,
            child: _buildStoryContent(),
          ),

          if (storyPhotos.isNotEmpty) ...[
            const SizedBox(height: 42),
            _buildStoryPhotos(storyPhotos),
          ],

          const SizedBox(height: 20),

          _buildDivider(),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEADING
  // ===========================================================================

  Widget _buildSectionHeading() {
    return Column(
      children: [
        Text(
          'OUR STORY',
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
          widget.invitation.storyTitle
                  .trim()
                  .isEmpty
              ? 'A Story Written in Love'
              : widget.invitation.storyTitle,
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
  // STORY CONTENT
  // ===========================================================================

  Widget _buildStoryContent() {
    final String story =
        widget.invitation.storyText
                .trim()
                .isEmpty
            ? 'Two hearts met, two lives became one, '
              'and a beautiful journey began. '
              'Now we invite you to celebrate '
              'the beginning of our forever with us.'
            : widget.invitation.storyText;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 620,
      ),
      child: Text(
        story,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: widget.theme.mutedTextColor,
          fontFamily: widget.theme.bodyFont,
          fontSize: 14,
          height: 1.9,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ===========================================================================
  // STORY PHOTOS
  // ===========================================================================

  Widget _buildStoryPhotos(
    List<dynamic> photos,
  ) {
    final visiblePhotos =
        photos.take(3).toList();

    if (visiblePhotos.length == 1) {
      return _buildSinglePhoto(
        visiblePhotos.first.url,
      );
    }

    if (visiblePhotos.length == 2) {
      return _buildTwoPhotos(
        visiblePhotos[0].url,
        visiblePhotos[1].url,
      );
    }

    return _buildThreePhotos(
      visiblePhotos[0].url,
      visiblePhotos[1].url,
      visiblePhotos[2].url,
    );
  }

  // ===========================================================================
  // ONE PHOTO
  // ===========================================================================

  Widget _buildSinglePhoto(
    String url,
  ) {
    return _storyImage(
      url,
      width: 280,
      height: 340,
      borderRadius: 140,
    );
  }

  // ===========================================================================
  // TWO PHOTOS
  // ===========================================================================

  Widget _buildTwoPhotos(
    String firstUrl,
    String secondUrl,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: [
        Transform.rotate(
          angle: -0.04,
          child: _storyImage(
            firstUrl,
            width: 145,
            height: 200,
            borderRadius: 80,
          ),
        ),
        const SizedBox(width: 14),
        Transform.translate(
          offset: const Offset(0, -16),
          child: Transform.rotate(
            angle: 0.04,
            child: _storyImage(
              secondUrl,
              width: 145,
              height: 220,
              borderRadius: 80,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // THREE PHOTOS
  // ===========================================================================

  Widget _buildThreePhotos(
    String firstUrl,
    String secondUrl,
    String thirdUrl,
  ) {
    return SizedBox(
      height: 290,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 10,
            bottom: 20,
            child: Transform.rotate(
              angle: -0.07,
              child: _storyImage(
                firstUrl,
                width: 130,
                height: 190,
                borderRadius: 70,
              ),
            ),
          ),

          Positioned(
            right: 10,
            bottom: 12,
            child: Transform.rotate(
              angle: 0.07,
              child: _storyImage(
                thirdUrl,
                width: 130,
                height: 190,
                borderRadius: 70,
              ),
            ),
          ),

          Positioned(
            top: 0,
            child: _storyImage(
              secondUrl,
              width: 150,
              height: 220,
              borderRadius: 80,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // IMAGE
  // ===========================================================================

  Widget _storyImage(
    String url, {
    required double width,
    required double height,
    required double borderRadius,
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
                  .withValues(alpha: 0.75),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                widget.theme.primaryColor
                    .withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
          .withValues(alpha: 0.35),
      child: Center(
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color:
                      widget.theme.accentColor,
                ),
              )
            : Icon(
                Icons.image_outlined,
                color:
                    widget.theme.accentColor,
                size: 30,
              ),
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