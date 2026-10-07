import 'package:flutter/material.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';

class InvitationRsvpSection extends StatelessWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const InvitationRsvpSection({
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
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 75,
      ),
      decoration: BoxDecoration(
        color: theme.secondaryColor.withValues(
          alpha: 0.16,
        ),
      ),
      child: Column(
        children: [
          _buildDecoration(),

          const SizedBox(height: 22),

          Text(
            'KINDLY RESPOND',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
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
              height: 1.1,
              fontWeight: FontWeight.w500,
              fontFamily: theme.headingFont,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            _buildMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.mutedTextColor,
              fontSize: 14,
              height: 1.7,
              fontFamily: theme.bodyFont,
            ),
          ),

          const SizedBox(height: 32),

          _buildRsvpCard(),

          const SizedBox(height: 32),

          Text(
            'We would be delighted to celebrate '
            'this special day with you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor.withValues(
                alpha: 0.75,
              ),
              fontSize: 12,
              height: 1.6,
              fontStyle: FontStyle.italic,
              fontFamily: theme.bodyFont,
            ),
          ),

          const SizedBox(height: 25),

          Text(
            '♥',
            style: TextStyle(
              color: theme.accentColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  String _buildMessage() {
    final String coupleName =
        invitation.brideName.trim().isNotEmpty &&
                invitation.groomName.trim().isNotEmpty
            ? '${invitation.brideName.trim()} & '
                '${invitation.groomName.trim()}'
            : 'the happy couple';

    return 'Your presence would mean the world to '
        '$coupleName. Please let us know if you '
        'will be joining us.';
  }

  Widget _buildRsvpCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 430,
      ),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(
          theme.borderRadius + 4,
        ),
        border: Border.all(
          color: theme.accentColor.withValues(
            alpha: 0.38,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(
              alpha: 0.08,
            ),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.secondaryColor.withValues(
                alpha: 0.45,
              ),
              border: Border.all(
                color: theme.accentColor.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              color: theme.primaryColor,
              size: 25,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'RSVP',
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontFamily: theme.headingFont,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Please confirm your attendance',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.mutedTextColor,
              fontSize: 12,
              fontFamily: theme.bodyFont,
            ),
          ),

          const SizedBox(height: 22),

          _buildActionButton(
            icon: Icons.check_rounded,
            label: 'YES, I’LL BE THERE',
            filled: true,
          ),

          const SizedBox(height: 10),

          _buildActionButton(
            icon: Icons.close_rounded,
            label: 'SORRY, CAN’T MAKE IT',
            filled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool filled,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: filled
              ? theme.primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.primaryColor.withValues(
              alpha: filled ? 1 : 0.35,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              // RSVP submission will be connected
              // in the publishing/database step.
            },
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: filled
                      ? theme.backgroundColor
                      : theme.primaryColor,
                ),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: TextStyle(
                    color: filled
                        ? theme.backgroundColor
                        : theme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
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

  Widget _buildDecoration() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 1,
          color: theme.accentColor.withValues(
            alpha: 0.45,
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.favorite,
          size: 13,
          color: theme.accentColor,
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 1,
          color: theme.accentColor.withValues(
            alpha: 0.45,
          ),
        ),
      ],
    );
  }
}