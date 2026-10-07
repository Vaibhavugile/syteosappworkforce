import 'package:flutter/material.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';
import 'lotus_royale_decorations.dart';

class LotusRoyaleRsvp extends StatelessWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const LotusRoyaleRsvp({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!invitation.rsvpEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        82,
        22,
        82,
      ),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: -25,
            child: LotusRoyaleDecorations.lotusFlower(
              theme: theme,
              size: 60,
            ),
          ),
          Positioned(
            right: -25,
            bottom: 0,
            child: Transform.rotate(
              angle: 0.3,
              child: LotusRoyaleDecorations.lotusFlower(
                theme: theme,
                size: 60,
              ),
            ),
          ),
          Column(
            children: [
              _buildHeading(),

              const SizedBox(height: 38),

              _buildRsvpCard(),

              const SizedBox(height: 34),

              Text(
                'Your presence is the most beautiful gift.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.mutedTextColor,
                  fontSize: 12,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  fontFamily: theme.bodyFont,
                ),
              ),

              const SizedBox(height: 38),

              LotusRoyaleDecorations.goldDivider(
                theme: theme,
                width: 180,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      children: [
        Text(
          'KINDLY RESPOND',
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
          'Will You Join Us?',
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

  Widget _buildRsvpCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 430,
      ),
      padding: const EdgeInsets.fromLTRB(
        25,
        30,
        25,
        28,
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
            alpha: 0.32,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(
              alpha: 0.05,
            ),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildEnvelopeIcon(),

          const SizedBox(height: 18),

          Text(
            'We hope you can celebrate with us',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w500,
              fontFamily: theme.headingFont,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            _buildMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.mutedTextColor,
              fontSize: 12,
              height: 1.7,
              fontFamily: theme.bodyFont,
            ),
          ),

          const SizedBox(height: 25),

          _buildPrimaryButton(),

          const SizedBox(height: 10),

          _buildSecondaryButton(),
        ],
      ),
    );
  }

  String _buildMessage() {
    final bride = invitation.brideName.trim();
    final groom = invitation.groomName.trim();

    if (bride.isNotEmpty && groom.isNotEmpty) {
      return 'Please let $bride & $groom know '
          'whether you will be joining their '
          'special celebration.';
    }

    return 'Please let us know whether you '
        'will be joining our special celebration.';
  }

  Widget _buildEnvelopeIcon() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.backgroundColor,
        border: Border.all(
          color: theme.accentColor.withValues(
            alpha: 0.55,
          ),
        ),
      ),
      child: Icon(
        Icons.mail_outline_rounded,
        color: theme.primaryColor,
        size: 27,
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return _buildButton(
      label: 'YES, I’LL BE THERE',
      icon: Icons.favorite_outline,
      filled: true,
      onTap: () {
        _showPreviewMessage();
      },
    );
  }

  Widget _buildSecondaryButton() {
    return _buildButton(
      label: 'SORRY, CAN’T MAKE IT',
      icon: Icons.close_rounded,
      filled: false,
      onTap: () {
        _showPreviewMessage();
      },
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: filled
                  ? theme.primaryColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: theme.primaryColor.withValues(
                  alpha: filled ? 1 : 0.35,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: filled
                      ? theme.backgroundColor
                      : theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: filled
                        ? theme.backgroundColor
                        : theme.primaryColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.05,
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

  void _showPreviewMessage() {
    // Actual RSVP submission will be connected
    // during the publishing/database step.
  }
}