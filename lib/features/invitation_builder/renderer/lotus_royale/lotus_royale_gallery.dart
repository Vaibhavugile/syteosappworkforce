import 'package:flutter/material.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_photo.dart';
import '../../models/invitation_template.dart';
import '../../models/invitation_theme.dart';
import 'lotus_royale_decorations.dart';

/// Lotus Royale gallery.
///
/// The section uses a dedicated artwork background and places the user's
/// uploaded gallery photos above it. The artwork already contains the
/// "OUR MOMENTS / Memories We Hold Dear" typography, so Flutter does not
/// render a duplicate heading.
class LotusRoyaleGallery extends StatefulWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final GalleryStyle galleryStyle;
  final bool isPreview;

  const LotusRoyaleGallery({
    super.key,
    required this.invitation,
    required this.theme,
    required this.galleryStyle,
    this.isPreview = false,
  });

  @override
  State<LotusRoyaleGallery> createState() => _LotusRoyaleGalleryState();
}

class _LotusRoyaleGalleryState extends State<LotusRoyaleGallery>
    with SingleTickerProviderStateMixin {
  static const String _backgroundAsset =
      'assets/invitations/lotus_royale/backgrounds/gallery.webp';

  int _selectedIndex = 0;
  late final AnimationController _entranceController;

  List<InvitationPhoto> get photos => widget.invitation.galleryPhotos;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 430;
        final bool desktop = width >= 700;

        return Container(
          width: double.infinity,
          color: widget.theme.backgroundColor,
          child: Stack(
            children: [
              _buildBackground(desktop),
              Padding(
                padding: EdgeInsets.only(
                  left: desktop ? 44 : 18,
                  right: desktop ? 44 : 18,
                  top: desktop ? 300 : 205,
                  bottom: desktop ? 110 : 86,
                ),
                child: Column(
                  children: [
                    if (photos.isEmpty)
                      _buildEmptyState()
                    else
                      _buildGallery(desktop),
                    const SizedBox(height: 36),
                    LotusRoyaleDecorations.goldDivider(
                      theme: widget.theme,
                      width: desktop ? 190 : 150,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground(bool desktop) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Image.asset(
          _backgroundAsset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.theme.backgroundColor,
                    widget.theme.secondaryColor.withValues(alpha: 0.25),
                    widget.theme.backgroundColor,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGallery(bool desktop) {
    switch (widget.galleryStyle) {
      case GalleryStyle.grid:
        return _buildGrid(desktop);

      case GalleryStyle.masonry:
        return _buildMasonry(desktop);

      case GalleryStyle.slider:
        return _buildSlider(desktop);

      case GalleryStyle.cinematic:
        return _buildCinematic(desktop);
    }
  }

  // ------------------------------------------------------------
  // GRID
  // ------------------------------------------------------------

  Widget _buildGrid(bool desktop) {
    final int columns = desktop ? 4 : 2;
    final double spacing = desktop ? 14 : 9;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: desktop ? 0.78 : 0.74,
      ),
      itemBuilder: (context, index) {
        return _animatedPhoto(
          index,
          _buildGalleryPhoto(
            photos[index],
            height: double.infinity,
            borderRadius: desktop ? 18 : 13,
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // MASONRY
  // ------------------------------------------------------------

  Widget _buildMasonry(bool desktop) {
    final List<List<InvitationPhoto>> columns = [[], []];

    for (int index = 0; index < photos.length; index++) {
      columns[index % 2].add(photos[index]);
    }

    final double gap = desktop ? 14 : 9;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < columns[0].length; i++) ...[
                _animatedPhoto(
                  i * 2,
                  _buildGalleryPhoto(
                    columns[0][i],
                    height: desktop
                        ? (i.isEven ? 270 : 205)
                        : (i.isEven ? 225 : 170),
                    borderRadius: desktop ? 18 : 13,
                  ),
                ),
                if (i != columns[0].length - 1)
                  SizedBox(height: gap),
              ],
            ],
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: desktop ? 28 : 22),
            child: Column(
              children: [
                for (int i = 0; i < columns[1].length; i++) ...[
                  _animatedPhoto(
                    i * 2 + 1,
                    _buildGalleryPhoto(
                      columns[1][i],
                      height: desktop
                          ? (i.isEven ? 205 : 270)
                          : (i.isEven ? 170 : 225),
                      borderRadius: desktop ? 18 : 13,
                    ),
                  ),
                  if (i != columns[1].length - 1)
                    SizedBox(height: gap),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SLIDER
  // ------------------------------------------------------------

  Widget _buildSlider(bool desktop) {
    final double height = desktop ? 540 : 370;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            itemCount: photos.length,
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() {
                _selectedIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: desktop ? 12 : 5,
                ),
                child: _animatedPhoto(
                  index,
                  _buildGalleryPhoto(
                    photos[index],
                    height: height,
                    borderRadius: desktop ? 24 : 18,
                  ),
                ),
              );
            },
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 16),
          _buildDots(),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // CINEMATIC
  // ------------------------------------------------------------

  Widget _buildCinematic(bool desktop) {
    final int safeIndex = _selectedIndex.clamp(0, photos.length - 1);
    final double mainHeight = desktop ? 580 : 410;

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          child: KeyedSubtree(
            key: ValueKey<int>(safeIndex),
            child: _animatedPhoto(
              safeIndex,
              _buildGalleryPhoto(
                photos[safeIndex],
                height: mainHeight,
                borderRadius: desktop ? 26 : 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: desktop ? 88 : 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            itemCount: photos.length,
            separatorBuilder: (context, index) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final bool selected = index == safeIndex;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  width: desktop ? 78 : 66,
                  height: desktop ? 88 : 72,
                  padding: EdgeInsets.all(selected ? 2 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: selected
                        ? Border.all(
                            color: widget.theme.accentColor,
                            width: 1.4,
                          )
                        : Border.all(
                            color: Colors.transparent,
                            width: 1.4,
                          ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: widget.theme.accentColor.withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildNetworkImage(photos[index].url),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // PHOTO FRAME
  // ------------------------------------------------------------

  Widget _buildGalleryPhoto(
    InvitationPhoto photo, {
    required double height,
    double borderRadius = 16,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: widget.theme.accentColor.withValues(alpha: 0.70),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: widget.theme.accentColor.withValues(alpha: 0.10),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          borderRadius > 6 ? borderRadius - 5 : borderRadius,
        ),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildNetworkImage(photo.url),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.07),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animatedPhoto(int index, Widget child) {
    final double start = (index * 0.07).clamp(0.0, 0.55);

    return AnimatedBuilder(
      animation: _entranceController,
      child: child,
      builder: (context, child) {
        final double progress = Curves.easeOutCubic.transform(
          ((_entranceController.value - start) / (1 - start))
              .clamp(0.0, 1.0),
        );

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - progress)),
            child: Transform.scale(
              scale: 0.97 + (0.03 * progress),
              child: child,
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // IMAGE
  // ------------------------------------------------------------

  Widget _buildNetworkImage(String url) {
    if (url.trim().isEmpty) {
      return _buildPhotoPlaceholder();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return _buildPhotoPlaceholder();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: widget.theme.secondaryColor.withValues(alpha: 0.18),
          alignment: Alignment.center,
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: widget.theme.accentColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: widget.theme.secondaryColor.withValues(alpha: 0.22),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            color: widget.theme.accentColor,
            size: 28,
          ),
          const SizedBox(height: 7),
          Text(
            'Photo',
            style: TextStyle(
              color: widget.theme.mutedTextColor,
              fontSize: 11,
              fontFamily: widget.theme.bodyFont,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        photos.length,
        (index) {
          final bool selected = index == _selectedIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: selected ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: selected
                  ? widget.theme.accentColor
                  : widget.theme.accentColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 430,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(widget.theme.borderRadius),
        border: Border.all(
          color: widget.theme.accentColor.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          LotusRoyaleDecorations.lotusFlower(
            theme: widget.theme,
            size: 54,
          ),
          const SizedBox(height: 14),
          Text(
            'Your precious moments will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.theme.mutedTextColor,
              fontSize: 13,
              height: 1.6,
              fontFamily: widget.theme.bodyFont,
            ),
          ),
        ],
      ),
    );
  }
}
