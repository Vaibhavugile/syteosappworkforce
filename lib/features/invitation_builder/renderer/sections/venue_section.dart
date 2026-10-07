import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';

class InvitationVenueSection extends StatefulWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const InvitationVenueSection({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  @override
  State<InvitationVenueSection> createState() =>
      _InvitationVenueSectionState();
}

class _InvitationVenueSectionState
    extends State<InvitationVenueSection>
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
    final venuePhoto =
        widget.invitation.venuePhoto;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 82,
      ),
      color: widget.theme.backgroundColor,
      child: Column(
        children: [
          _buildHeading(),

          const SizedBox(height: 40),

          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildVenueCard(
                venuePhoto?.url,
              ),
            ),
          ),

          const SizedBox(height: 38),

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
          'THE VENUE',
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
          'Where We Begin Forever',
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
  // VENUE CARD
  // ===========================================================================

  Widget _buildVenueCard(
    String? photoUrl,
  ) {
    final String venueName =
        widget.invitation.venueName
                .trim()
                .isEmpty
            ? 'Wedding Venue'
            : widget.invitation.venueName;

    final String address =
        widget.invitation.venueAddress
                .trim()
                .isEmpty
            ? 'Your venue address'
            : widget.invitation.venueAddress;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 620,
      ),
      decoration: BoxDecoration(
        color: widget.theme.secondaryColor
            .withValues(alpha: 0.15),
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: widget.theme.accentColor
              .withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.theme.primaryColor
                .withValues(alpha: 0.07),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildVenueImage(photoUrl),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              26,
              24,
              28,
            ),
            child: Column(
              children: [
                Text(
                  venueName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.theme.textColor,
                    fontFamily:
                        widget.theme.headingFont,
                    fontSize: 29,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color:
                          widget.theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget
                              .theme
                              .mutedTextColor,
                          fontFamily:
                              widget.theme.bodyFont,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _buildLocationButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // VENUE IMAGE
  // ===========================================================================

  Widget _buildVenueImage(
    String? url,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null &&
              url.trim().isNotEmpty)
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) {
                return _venuePlaceholder();
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

                return _venuePlaceholder(
                  loading: true,
                );
              },
            )
          else
            _venuePlaceholder(),

          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient:
                      LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(
                        alpha: 0.25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 18,
            right: 18,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.theme
                    .backgroundColor
                    .withValues(alpha: 0.90),
                border: Border.all(
                  color: widget.theme
                      .accentColor
                      .withValues(alpha: 0.65),
                ),
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 19,
                color:
                    widget.theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _venuePlaceholder({
    bool loading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
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
        child: loading
            ? SizedBox(
                width: 25,
                height: 25,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color:
                      widget.theme.accentColor,
                ),
              )
            : Icon(
                Icons.location_city_outlined,
                size: 48,
                color:
                    widget.theme.accentColor,
              ),
      ),
    );
  }

  // ===========================================================================
  // LOCATION BUTTON
  // ===========================================================================

  Widget _buildLocationButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _openLocation,
        icon: Icon(
          Icons.map_outlined,
          size: 18,
          color: widget.theme.primaryColor,
        ),
        label: Text(
          'VIEW LOCATION',
          style: TextStyle(
            color: widget.theme.primaryColor,
            fontFamily: widget.theme.bodyFont,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.7,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: widget.theme.accentColor
                .withValues(alpha: 0.65),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // OPEN LOCATION
  // ===========================================================================

  Future<void> _openLocation() async {
    final double? latitude =
        widget.invitation.venueLatitude;

    final double? longitude =
        widget.invitation.venueLongitude;

    Uri uri;

    if (latitude != null &&
        longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1'
        '&query=$latitude,$longitude',
      );
    } else {
      final String address =
          widget.invitation.venueAddress
                  .trim()
                  .isNotEmpty
              ? widget.invitation.venueAddress
              : widget.invitation.venueName;

      if (address.trim().isEmpty) {
        return;
      }

      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1'
        '&query=${Uri.encodeComponent(address)}',
      );
    }

    try {
      final bool launched =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showLocationError();
      }
    } catch (_) {
      if (mounted) {
        _showLocationError();
      }
    }
  }

  void _showLocationError() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: const Text(
          'Unable to open the location.',
        ),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            widget.theme.primaryColor,
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