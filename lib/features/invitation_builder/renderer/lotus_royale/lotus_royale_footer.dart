import 'package:flutter/material.dart';

import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';

class LotusRoyaleFooter extends StatelessWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const LotusRoyaleFooter({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  static const String _backgroundAsset =
      'assets/invitations/lotus_royale/backgrounds/footer.webp';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 500;
        final height = compact ? 500.0 : 430.0;

        return SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.02),
                      Colors.white.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 22 : 48,
                    vertical: compact ? 30 : 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: _buildContent(compact),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    return Image.asset(
      _backgroundAsset,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.backgroundColor,
                theme.secondaryColor,
                theme.backgroundColor,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool compact) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTopDecoration(compact),
        SizedBox(height: compact ? 15 : 11),
        Text(
          'WITH LOVE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.primaryColor,
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.5,
            fontFamily: theme.bodyFont,
          ),
        ),
        SizedBox(height: compact ? 8 : 6),
        _buildNames(compact),
        SizedBox(height: compact ? 9 : 7),
        _buildDate(compact),
        SizedBox(height: compact ? 13 : 10),
        _buildDivider(compact),
        SizedBox(height: compact ? 11 : 9),
        Text(
          'Thank you for being part of our story.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.textColor.withValues(alpha: 0.78),
            fontSize: compact ? 11 : 12,
            height: 1.35,
            fontStyle: FontStyle.italic,
            fontFamily: theme.bodyFont,
          ),
        ),
        SizedBox(height: compact ? 12 : 10),
        _buildHeart(compact),
        SizedBox(height: compact ? 12 : 9),
        Text(
          'FOREVER BEGINS HERE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.primaryColor,
            fontSize: compact ? 7 : 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
            fontFamily: theme.bodyFont,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Made with love',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.textColor.withValues(alpha: 0.52),
            fontSize: 8,
            letterSpacing: 1,
            fontFamily: theme.bodyFont,
          ),
        ),
      ],
    );
  }

  Widget _buildTopDecoration(bool compact) {
    final width = compact ? 42.0 : 58.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _goldLine(width),
        const SizedBox(width: 9),
        _goldDiamond(),
        const SizedBox(width: 9),
        Icon(
          Icons.local_florist_rounded,
          color: theme.accentColor,
          size: compact ? 16 : 18,
        ),
        const SizedBox(width: 9),
        _goldDiamond(),
        const SizedBox(width: 9),
        _goldLine(width),
      ],
    );
  }

  Widget _buildNames(bool compact) {
    final bride = invitation.brideName.trim().isEmpty
        ? 'Bride'
        : invitation.brideName.trim();
    final groom = invitation.groomName.trim().isEmpty
        ? 'Groom'
        : invitation.groomName.trim();

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            bride,
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: compact ? 31 : 35,
              height: 1,
              fontWeight: FontWeight.w500,
              fontFamily: theme.headingFont,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '&',
              style: TextStyle(
                color: theme.accentColor,
                fontSize: compact ? 22 : 25,
                height: 1,
                fontFamily: theme.scriptFont,
              ),
            ),
          ),
          Text(
            groom,
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: compact ? 31 : 35,
              height: 1,
              fontWeight: FontWeight.w500,
              fontFamily: theme.headingFont,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDate(bool compact) {
    final date = invitation.weddingDate.trim();
    final time = invitation.weddingTime.trim();

    if (date.isEmpty && time.isEmpty) {
      return const SizedBox.shrink();
    }

    final text = date.isNotEmpty && time.isNotEmpty
        ? '$date  •  $time'
        : date.isNotEmpty
            ? date
            : time;

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: theme.accentColor,
        fontSize: compact ? 9.5 : 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        fontFamily: theme.bodyFont,
      ),
    );
  }

  Widget _buildDivider(bool compact) {
    final width = compact ? 42.0 : 55.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _goldLine(width, opacity: 0.65),
        const SizedBox(width: 8),
        _goldDiamond(),
        const SizedBox(width: 8),
        Icon(
          Icons.favorite,
          color: theme.accentColor,
          size: compact ? 10 : 11,
        ),
        const SizedBox(width: 8),
        _goldDiamond(),
        const SizedBox(width: 8),
        _goldLine(width, opacity: 0.65),
      ],
    );
  }

  Widget _buildHeart(bool compact) {
    final size = compact ? 40.0 : 44.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.28),
        border: Border.all(
          color: theme.accentColor.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accentColor.withValues(alpha: 0.10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(
        Icons.favorite,
        color: theme.primaryColor,
        size: compact ? 15 : 17,
      ),
    );
  }

  Widget _goldLine(double width, {double opacity = 0.75}) {
    return Container(
      width: width,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            theme.accentColor.withValues(alpha: opacity),
          ],
        ),
      ),
    );
  }

  Widget _goldDiamond() {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: 5,
        height: 5,
        color: theme.accentColor,
      ),
    );
  }
}
