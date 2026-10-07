import 'package:flutter/material.dart';

import '../config/invitation_templates.dart';
import '../config/invitation_themes.dart';
import '../models/invitation_model.dart';
import '../models/invitation_template.dart';
import '../models/invitation_theme.dart';

import 'sections/hero_section.dart';
import 'sections/story_section.dart';
import 'sections/couple_section.dart';
import 'sections/events_section.dart';
import 'sections/gallery_section.dart';
import 'sections/venue_section.dart';
import 'sections/countdown_section.dart';
import 'sections/rsvp_section.dart';
import 'sections/footer_section.dart';

// Lotus Royale
import 'lotus_royale/lotus_royale_hero.dart';
import 'lotus_royale/lotus_royale_story.dart';
import 'lotus_royale/lotus_royale_couple.dart';
import 'lotus_royale/lotus_royale_events.dart';
import 'lotus_royale/lotus_royale_gallery.dart';
import 'lotus_royale/lotus_royale_venue.dart';
import 'lotus_royale/lotus_royale_countdown.dart';
import 'lotus_royale/lotus_royale_rsvp.dart';
import 'lotus_royale/lotus_royale_footer.dart';
import 'premium_3d_scroll_section.dart';

class InvitationRenderer extends StatefulWidget {
  final InvitationModel invitation;

  /// Optional template override.
  ///
  /// If not supplied, the renderer uses invitation.templateId.
  final InvitationTemplate? template;

  /// Optional theme override.
  ///
  /// If not supplied, the renderer uses the template's theme.
  final InvitationTheme? theme;

  /// When true, the invitation is being shown
  /// inside the builder/editor preview.
  final bool isPreview;

  const InvitationRenderer({
    super.key,
    required this.invitation,
    this.template,
    this.theme,
    this.isPreview = false,
  });

  @override
  State<InvitationRenderer> createState() =>
      _InvitationRendererState();
}

class _InvitationRendererState extends State<InvitationRenderer> {
  late final ScrollController _scrollController;
  late final ValueNotifier<double> _scrollNotifier;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollNotifier = ValueNotifier<double>(0.0);

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;

      if (_scrollNotifier.value != offset) {
        _scrollNotifier.value = offset;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _scrollNotifier.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // RESOLVED TEMPLATE
  // ---------------------------------------------------------------------------

  InvitationTemplate get resolvedTemplate {
    return widget.template ??
        InvitationTemplates.getById(
          widget.invitation.templateId,
        );
  }

  // ---------------------------------------------------------------------------
  // RESOLVED THEME
  // ---------------------------------------------------------------------------

  InvitationTheme get resolvedTheme {
    return widget.theme ??
        InvitationThemes.getById(
          resolvedTemplate.themeId,
        );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final InvitationTemplate currentTemplate =
        resolvedTemplate;

    final InvitationTheme currentTheme =
        resolvedTheme;

    return Container(
      width: double.infinity,
      color: currentTheme.backgroundColor,
      child: Theme(
        data: _buildThemeData(
          context,
          currentTheme,
        ),
        child: _buildInvitation(
          currentTemplate,
          currentTheme,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INVITATION
  // ---------------------------------------------------------------------------

  Widget _buildInvitation(
    InvitationTemplate template,
    InvitationTheme theme,
  ) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionList(
            template,
            theme,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION LIST
  // ---------------------------------------------------------------------------

  Widget _buildSectionList(
    InvitationTemplate template,
    InvitationTheme theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final section in template.sections)
          RepaintBoundary(
            child: Premium3DScrollSection(
              scrollNotifier: _scrollNotifier,
              child: _buildSection(
                section,
                template,
                theme,
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION ROUTER
  // ---------------------------------------------------------------------------

  Widget _buildSection(
    String sectionId,
    InvitationTemplate template,
    InvitationTheme theme,
  ) {
    final bool isLotusRoyale =
        template.id == 'lotus_royale';

    switch (sectionId) {
      // =======================================================================
      // HERO
      // =======================================================================

      case 'hero':
        if (isLotusRoyale) {
          return LotusRoyaleHero(
            invitation: widget.invitation,
            theme: theme,
            isPreview: widget.isPreview,
          );
        }

        return InvitationHeroSection(
          invitation: widget.invitation,
          theme: theme,
          enablePetals: template.enablePetals,
          enableParallax: template.enableParallax,
          enable3DTilt: template.enable3DTilt,
          isPreview: widget.isPreview,
        );

      // =======================================================================
      // STORY
      // =======================================================================

      case 'story':
        if (isLotusRoyale) {
          return LotusRoyaleStory(
            invitation: widget.invitation,
            theme: theme,
            isPreview: widget.isPreview,
          );
        }

        return InvitationStorySection(
          invitation: widget.invitation,
          theme: theme,
          isPreview: widget.isPreview,
        );

      // =======================================================================
      // COUPLE
      // =======================================================================

      case 'couple':
        if (isLotusRoyale) {
          return LotusRoyaleCouple(
            invitation: widget.invitation,
            theme: theme,
            isPreview: widget.isPreview,
          );
        }

        return InvitationCoupleSection(
          invitation: widget.invitation,
          theme: theme,
          isPreview: widget.isPreview,
        );

      // =======================================================================
      // EVENTS
      // =======================================================================

      case 'events':
        if (isLotusRoyale) {
          return LotusRoyaleEvents(
            invitation: widget.invitation,
            theme: theme,
            isPreview: widget.isPreview,
          );
        }

        return InvitationEventsSection(
          invitation: widget.invitation,
          theme: theme,
          isPreview: widget.isPreview,
        );

      // =======================================================================
      // GALLERY
      // =======================================================================

      case 'gallery':
        if (isLotusRoyale) {
          return LotusRoyaleGallery(
            invitation: widget.invitation,
            theme: theme,
            galleryStyle: template.galleryStyle,
            isPreview: widget.isPreview,
          );
        }

        return InvitationGallerySection(
          invitation: widget.invitation,
          theme: theme,
          galleryStyle: template.galleryStyle,
          isPreview: widget.isPreview,
        );

      // =======================================================================
      // VENUE
      // =======================================================================

      case 'venue':
        if (isLotusRoyale) {
          return LotusRoyaleVenue(
            invitation: widget.invitation,
            theme: theme,
            isPreview: widget.isPreview,
          );
        }

        return InvitationVenueSection(
          invitation: widget.invitation,
          theme: theme,
          isPreview: widget.isPreview,
        );

      // =======================================================================
      // COUNTDOWN
      // =======================================================================

      case 'countdown':
        if (isLotusRoyale) {
          return LotusRoyaleCountdown(
            invitation: widget.invitation,
            theme: theme,
            isPreview: widget.isPreview,
          );
        }

        return InvitationCountdownSection(
          invitation: widget.invitation,
          theme: theme,
          isPreview: widget.isPreview,
        );

      // =======================================================================
      // RSVP
      // =======================================================================

      // case 'rsvp':
      //   if (isLotusRoyale) {
      //     return LotusRoyaleRsvp(
      //       invitation: widget.invitation,
      //       theme: theme,
      //       isPreview: widget.isPreview,
      //     );
      //   }

        return InvitationRsvpSection(
          invitation: widget.invitation,
          theme: theme,
          isPreview: widget.isPreview,
        );

      // =======================================================================
      // FOOTER
      // =======================================================================

      case 'footer':
        if (isLotusRoyale) {
          return LotusRoyaleFooter(
            invitation: widget.invitation,
            theme: theme,
            isPreview: widget.isPreview,
          );
        }

        return InvitationFooterSection(
          invitation: widget.invitation,
          theme: theme,
          isPreview: widget.isPreview,
        );

      // =======================================================================
      // UNKNOWN SECTION
      // =======================================================================

      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // PLACEHOLDER SECTION
  // ---------------------------------------------------------------------------

  Widget _placeholderSection({
    required String title,
    required String subtitle,
    required InvitationTheme theme,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 260,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 60,
      ),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              fontFamily: theme.headingFont,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.mutedTextColor,
              fontSize: 14,
              height: 1.5,
              fontFamily: theme.bodyFont,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // THEME DATA
  // ---------------------------------------------------------------------------

  ThemeData _buildThemeData(
    BuildContext context,
    InvitationTheme theme,
  ) {
    final ThemeData baseTheme =
        Theme.of(context);

    return baseTheme.copyWith(
      scaffoldBackgroundColor:
          theme.backgroundColor,

      colorScheme:
          baseTheme.colorScheme.copyWith(
        primary: theme.primaryColor,
        secondary: theme.accentColor,
        surface: theme.backgroundColor,
      ),

      textTheme:
          baseTheme.textTheme.apply(
        bodyColor: theme.textColor,
        displayColor: theme.textColor,
      ),
    );
  }
}
