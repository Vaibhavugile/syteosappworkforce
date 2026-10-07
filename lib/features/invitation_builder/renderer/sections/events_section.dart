import 'package:flutter/material.dart';

import '../../models/invitation_event.dart';
import '../../models/invitation_model.dart';
import '../../models/invitation_theme.dart';

class InvitationEventsSection extends StatefulWidget {
  final InvitationModel invitation;
  final InvitationTheme theme;
  final bool isPreview;

  const InvitationEventsSection({
    super.key,
    required this.invitation,
    required this.theme,
    this.isPreview = false,
  });

  @override
  State<InvitationEventsSection> createState() =>
      _InvitationEventsSectionState();
}

class _InvitationEventsSectionState
    extends State<InvitationEventsSection>
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
        milliseconds: 1400,
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
    final events =
        widget.invitation.enabledEvents;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 82,
      ),
      color: widget.theme.backgroundColor,
      child: Column(
        children: [
          _buildHeading(),

          const SizedBox(height: 42),

          if (events.isEmpty)
            _buildEmptyEvents()
          else
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildTimeline(events),
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
          'THE CELEBRATION',
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
          'Wedding Events',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.theme.textColor,
            fontFamily:
                widget.theme.headingFont,
            fontSize: 38,
            height: 1.1,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Join us as we celebrate every beautiful moment.',
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
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyEvents() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.theme.accentColor
              .withValues(alpha: 0.25),
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 34,
            color: widget.theme.accentColor,
          ),
          const SizedBox(height: 14),
          Text(
            'Your wedding events will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.theme.mutedTextColor,
              fontFamily: widget.theme.bodyFont,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TIMELINE
  // ===========================================================================

  Widget _buildTimeline(
    List<InvitationEvent> events,
  ) {
    return Column(
      children: [
        for (int index = 0;
            index < events.length;
            index++)
          _buildEventItem(
            events[index],
            index,
            events.length,
          ),
      ],
    );
  }

  // ===========================================================================
  // EVENT ITEM
  // ===========================================================================

  Widget _buildEventItem(
    InvitationEvent event,
    int index,
    int total,
  ) {
    final bool isLast =
        index == total - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              children: [
                _buildTimelineDot(
                  event,
                  index,
                ),

                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: widget.theme.accentColor
                          .withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 24,
              ),
              child: _buildEventCard(
                event,
                index,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TIMELINE DOT
  // ===========================================================================

  Widget _buildTimelineDot(
    InvitationEvent event,
    int index,
  ) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.theme.backgroundColor,
        border: Border.all(
          color: widget.theme.accentColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.theme.accentColor
                .withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _eventIcon(event.icon),
          size: 19,
          color: widget.theme.primaryColor,
        ),
      ),
    );
  }

  // ===========================================================================
  // EVENT CARD
  // ===========================================================================

  Widget _buildEventCard(
    InvitationEvent event,
    int index,
  ) {
    final String eventName =
        event.name.trim().isEmpty
            ? 'Wedding Event'
            : event.name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.theme.secondaryColor
            .withValues(alpha: 0.16),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: widget.theme.accentColor
              .withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            _eventNumber(index),
            style: TextStyle(
              color: widget.theme.accentColor,
              fontFamily: widget.theme.bodyFont,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            eventName,
            style: TextStyle(
              color: widget.theme.textColor,
              fontFamily:
                  widget.theme.headingFont,
              fontSize: 27,
              height: 1.1,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          if (event.date.trim().isNotEmpty)
            _buildInfoRow(
              icon: Icons.calendar_month_outlined,
              value: event.date,
            ),

          if (event.time.trim().isNotEmpty)
            _buildInfoRow(
              icon: Icons.access_time_rounded,
              value: event.time,
            ),

          if (event.venue.trim().isNotEmpty)
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              value: event.venue,
            ),

          if (event.description
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event.description,
              style: TextStyle(
                color:
                    widget.theme.mutedTextColor,
                fontFamily:
                    widget.theme.bodyFont,
                fontSize: 12,
                height: 1.65,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // INFO ROW
  // ===========================================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: widget.theme.primaryColor,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color:
                    widget.theme.mutedTextColor,
                fontFamily:
                    widget.theme.bodyFont,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EVENT ICON
  // ===========================================================================

  IconData _eventIcon(
    String iconName,
  ) {
    switch (iconName.toLowerCase()) {
      case 'favorite':
      case 'heart':
        return Icons.favorite_rounded;

      case 'music':
      case 'sangeet':
        return Icons.music_note_rounded;

      case 'celebration':
      case 'party':
        return Icons.celebration_rounded;

      case 'restaurant':
      case 'food':
        return Icons.restaurant_rounded;

      case 'ring':
      case 'wedding':
        return Icons.diamond_rounded;

      case 'brush':
      case 'mehendi':
        return Icons.brush_rounded;

      case 'church':
        return Icons.account_balance_rounded;

      case 'event':
      default:
        return Icons.event_rounded;
    }
  }

  // ===========================================================================
  // EVENT NUMBER
  // ===========================================================================

  String _eventNumber(
    int index,
  ) {
    return 'EVENT ${index + 1}'
        .padLeft(7, '0');
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