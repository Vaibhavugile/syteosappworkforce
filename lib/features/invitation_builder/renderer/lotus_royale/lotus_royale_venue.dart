import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';
import 'lotus_royale_decorations.dart';

class LotusRoyaleVenue extends StatelessWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const LotusRoyaleVenue({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto =
        invitation.venuePhoto?.url.trim().isNotEmpty ?? false;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 900,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
      ),
      child: Stack(
        children: [
          // ======================================================
          // VENUE BACKGROUND
          // ======================================================

          Positioned.fill(
            child: Image.asset(
              'assets/invitations/lotus_royale/backgrounds/venue.webp',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  color: theme.backgroundColor,
                );
              },
            ),
          ),

          // ======================================================
          // SOFT READABILITY OVERLAY
          // ======================================================

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(
                  alpha: 0.72,
                ),
              ),
            ),
          ),

          // ======================================================
          // VERY LIGHT CENTER GLOW
          // ======================================================

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    Colors.white.withValues(
                      alpha: 0.26,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // VENUE CONTENT
          // ======================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              22,
              78,
              22,
              82,
            ),
            child: Column(
              children: [
                _buildHeading(),

                const SizedBox(height: 40),

                _buildVenueCard(
                  hasPhoto: hasPhoto,
                ),

                const SizedBox(height: 30),

                _buildLocationButton(),

                const SizedBox(height: 42),

                LotusRoyaleDecorations.goldDivider(
                  theme: theme,
                  width: 180,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHeading() {
    return Column(
      children: [
        Text(
          'THE VENUE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.accentColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.2,
            fontFamily: theme.bodyFont,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Where We Celebrate',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.primaryColor,
            fontSize: 34,
            height: 1.08,
            fontWeight: FontWeight.w500,
            fontFamily: theme.headingFont,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          width: 35,
          height: 1,
          color: theme.accentColor.withValues(
            alpha: 0.65,
          ),
        ),
      ],
    );
  }

  Widget _buildVenueCard({
    required bool hasPhoto,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 480,
      ),
      decoration: BoxDecoration(
        color: theme.secondaryColor.withValues(
          alpha: 0.13,
        ),
        borderRadius: BorderRadius.circular(
          theme.borderRadius + 5,
        ),
        border: Border.all(
          color: theme.accentColor.withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Column(
        children: [
          if (hasPhoto)
            _buildVenuePhoto()
          else
            _buildVenueIllustration(),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              25,
              24,
              27,
            ),
            child: Column(
              children: [
                Text(
                  invitation.venueName.trim().isEmpty
                      ? 'Wedding Venue'
                      : invitation.venueName.trim(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 27,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                    fontFamily: theme.headingFont,
                  ),
                ),

                if (invitation.venueAddress
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    invitation.venueAddress.trim(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.mutedTextColor,
                      fontSize: 12,
                      height: 1.6,
                      fontFamily: theme.bodyFont,
                    ),
                  ),
                ],

                if (invitation.venueLatitude != null &&
                    invitation.venueLongitude != null) ...[
                  const SizedBox(height: 14),
                  _buildCoordinates(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenuePhoto() {
    return SizedBox(
      width: double.infinity,
      height: 245,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            theme.borderRadius + 5,
          ),
          topRight: Radius.circular(
            theme.borderRadius + 5,
          ),
        ),
        child: Image.network(
          invitation.venuePhoto!.url,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _buildVenueIllustration();
          },
          loadingBuilder: (
            context,
            child,
            loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }

            return _buildLoading();
          },
        ),
      ),
    );
  }

  Widget _buildVenueIllustration() {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.secondaryColor.withValues(
              alpha: 0.28,
            ),
            theme.secondaryColor.withValues(
              alpha: 0.08,
            ),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 25,
            left: 25,
            child: LotusRoyaleDecorations.lotusFlower(
              theme: theme,
              size: 55,
            ),
          ),
          Positioned(
            bottom: 22,
            right: 25,
            child: Transform.rotate(
              angle: 0.3,
              child: LotusRoyaleDecorations.lotusFlower(
                theme: theme,
                size: 50,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_city_outlined,
                color: theme.primaryColor,
                size: 42,
              ),
              const SizedBox(height: 10),
              Text(
                'THE CELEBRATION',
                style: TextStyle(
                  color: theme.accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontFamily: theme.bodyFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: theme.secondaryColor.withValues(
        alpha: 0.18,
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: theme.accentColor,
        ),
      ),
    );
  }

  Widget _buildCoordinates() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.backgroundColor.withValues(
          alpha: 0.65,
        ),
      ),
      child: Text(
        '${invitation.venueLatitude!.toStringAsFixed(4)}, '
        '${invitation.venueLongitude!.toStringAsFixed(4)}',
        style: TextStyle(
          color: theme.mutedTextColor,
          fontSize: 9,
          letterSpacing: 0.4,
          fontFamily: theme.bodyFont,
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return SizedBox(
      width: 220,
      height: 50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openLocation,
          child: Ink(
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(
                    alpha: 0.18,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: theme.backgroundColor,
                ),
                const SizedBox(width: 9),
                Text(
                  'VIEW LOCATION',
                  style: TextStyle(
                    color: theme.backgroundColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: theme.bodyFont,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLocation() async {
    Uri? uri;

    final latitude = invitation.venueLatitude;
    final longitude = invitation.venueLongitude;

    if (latitude != null && longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/'
        '?api=1&query=$latitude,$longitude',
      );
    } else if (invitation.venueAddress.trim().isNotEmpty) {
      final String query = Uri.encodeComponent(
        invitation.venueAddress.trim(),
      );

      uri = Uri.parse(
        'https://www.google.com/maps/search/'
        '?api=1&query=$query',
      );
    } else if (invitation.venueName.trim().isNotEmpty) {
      final String query = Uri.encodeComponent(
        invitation.venueName.trim(),
      );

      uri = Uri.parse(
        'https://www.google.com/maps/search/'
        '?api=1&query=$query',
      );
    }

    if (uri == null) return;

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}