import 'package:flutter/material.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';

class InvitationFooterSection extends StatelessWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const InvitationFooterSection({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        70,
        24,
        45,
      ),
      decoration: BoxDecoration(
        color: theme.primaryColor,
      ),
      child: Column(
        children: [
          _buildFloralDecoration(),

          const SizedBox(height: 28),

          Text(
            'WITH LOVE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.5,
              fontFamily: theme.bodyFont,
            ),
          ),

          const SizedBox(height: 16),

          _buildCoupleNames(),

          const SizedBox(height: 18),

          _buildDate(),

          const SizedBox(height: 35),

          _buildDivider(),

          const SizedBox(height: 28),

          Text(
            'Thank you for being a part of our story.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.backgroundColor.withValues(
                alpha: 0.78,
              ),
              fontSize: 13,
              height: 1.6,
              fontStyle: FontStyle.italic,
              fontFamily: theme.bodyFont,
            ),
          ),

          const SizedBox(height: 30),

          _buildHeart(),

          const SizedBox(height: 35),

          Text(
            'Made with love',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.backgroundColor.withValues(
                alpha: 0.48,
              ),
              fontSize: 10,
              letterSpacing: 1,
              fontFamily: theme.bodyFont,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Wedding Invitation',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.accentColor.withValues(
                alpha: 0.8,
              ),
              fontSize: 10,
              letterSpacing: 1.5,
              fontFamily: theme.bodyFont,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoupleNames() {
    final bool hasNames =
        invitation.brideName.trim().isNotEmpty &&
            invitation.groomName.trim().isNotEmpty;

    if (!hasNames) {
      return Text(
        'Your Special Day',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.backgroundColor,
          fontSize: 34,
          fontWeight: FontWeight.w500,
          fontFamily: theme.headingFont,
        ),
      );
    }

    return Column(
      children: [
        Text(
          invitation.brideName.trim(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.backgroundColor,
            fontSize: 35,
            height: 1,
            fontWeight: FontWeight.w500,
            fontFamily: theme.headingFont,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          '&',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.accentColor,
            fontSize: 22,
            fontFamily: theme.scriptFont,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          invitation.groomName.trim(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.backgroundColor,
            fontSize: 35,
            height: 1,
            fontWeight: FontWeight.w500,
            fontFamily: theme.headingFont,
          ),
        ),
      ],
    );
  }

  Widget _buildDate() {
    if (invitation.weddingDate.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final String date =
        invitation.weddingDate.trim();

    final String time =
        invitation.weddingTime.trim();

    final String text = time.isEmpty
        ? date
        : '$date  •  $time';

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: theme.accentColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        fontFamily: theme.bodyFont,
      ),
    );
  }

  Widget _buildFloralDecoration() {
    return SizedBox(
      width: 170,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 15,
            bottom: 10,
            child: _buildLeaf(
              rotation: -0.55,
            ),
          ),
          Positioned(
            left: 42,
            top: 7,
            child: _buildLeaf(
              rotation: -0.25,
            ),
          ),
          Positioned(
            right: 15,
            bottom: 10,
            child: Transform.scale(
              scaleX: -1,
              child: _buildLeaf(
                rotation: -0.55,
              ),
            ),
          ),
          Positioned(
            right: 42,
            top: 7,
            child: Transform.scale(
              scaleX: -1,
              child: _buildLeaf(
                rotation: -0.25,
              ),
            ),
          ),
          Icon(
            Icons.local_florist_rounded,
            color: theme.accentColor,
            size: 34,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaf({
    required double rotation,
  }) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 30,
        height: 13,
        decoration: BoxDecoration(
          color: theme.accentColor.withValues(
            alpha: 0.72,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 55,
          height: 1,
          color: theme.accentColor.withValues(
            alpha: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.favorite,
          color: theme.accentColor,
          size: 12,
        ),
        const SizedBox(width: 12),
        Container(
          width: 55,
          height: 1,
          color: theme.accentColor.withValues(
            alpha: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeart() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.accentColor.withValues(
            alpha: 0.55,
          ),
        ),
      ),
      child: Icon(
        Icons.favorite,
        color: theme.accentColor,
        size: 18,
      ),
    );
  }
}