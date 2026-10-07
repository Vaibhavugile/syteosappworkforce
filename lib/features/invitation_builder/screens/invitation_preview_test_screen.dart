import 'package:flutter/material.dart';

import '../models/invitation_event.dart';
import '../models/invitation_model.dart';
import '../models/invitation_photo.dart';
import '../renderer/invitation_renderer.dart';
import '../services/invitation_publish_service.dart';
import '../widgets/lotus_royale_opening.dart';

class InvitationPreviewTestScreen extends StatefulWidget {
  const InvitationPreviewTestScreen({
    super.key,
    this.invitation,
  });

  /// Optional invitation.
  ///
  /// If an invitation is provided, it will be displayed.
  /// Otherwise a demo Lotus Royale invitation is used.
  final InvitationModel? invitation;

  @override
  State<InvitationPreviewTestScreen> createState() =>
      _InvitationPreviewTestScreenState();
}

class _InvitationPreviewTestScreenState
    extends State<InvitationPreviewTestScreen> {
  final InvitationPublishService _publishService =
      InvitationPublishService();

  bool _isPublishing = false;

  InvitationModel? _publishedInvitation;

  /// Controls whether the opening envelope has been completed.
  bool _invitationOpened = false;

  // ===========================================================================
  // DEMO INVITATION
  // ===========================================================================

  InvitationModel _buildTestInvitation() {
    final DateTime weddingDate =
        DateTime.now().add(const Duration(days: 45));

    return InvitationModel(
      id: 'test_lotus_royale_001',
      userId: 'test_user',

      templateId: 'lotus_royale',
      themeId: 'lotus_royale',

      // -----------------------------------------------------------------------
      // COUPLE
      // -----------------------------------------------------------------------

      brideName: 'Ananya',
      groomName: 'Arjun',

      brideDescription:
          'A dreamer with a heart full of love and a smile that lights up every room.',

      groomDescription:
          'A believer in beautiful journeys, endless laughter and forever.',

      // -----------------------------------------------------------------------
      // WEDDING DETAILS
      // -----------------------------------------------------------------------

      weddingDate:
          '${weddingDate.day.toString().padLeft(2, '0')} '
          '${_monthName(weddingDate.month)} '
          '${weddingDate.year}',

      weddingTime: '7:00 PM',

      // -----------------------------------------------------------------------
      // STORY
      // -----------------------------------------------------------------------

      storyTitle: 'A Story Written in Love',

      storyText:
          'What started with a simple hello slowly became a beautiful journey '
          'filled with laughter, friendship, countless memories and a love '
          'that grew stronger with every passing day. '
          'Now, surrounded by the people who mean the most to us, '
          'we are ready to begin our forever.',

      // -----------------------------------------------------------------------
      // VENUE
      // -----------------------------------------------------------------------

      venueName: 'The Grand Lotus Palace',

      venueAddress: 'MG Road, Pune, Maharashtra',

      venueLatitude: 18.5204,
      venueLongitude: 73.8567,

      // -----------------------------------------------------------------------
      // EVENTS
      // -----------------------------------------------------------------------

      events: [
        InvitationEvent(
          id: 'event_mehendi',
          name: 'Mehendi',
          date: 'Friday, 14 November 2026',
          time: '4:00 PM',
          venue: 'Garden Courtyard',
          description:
              'An afternoon filled with music, laughter and beautiful mehendi designs.',
          icon: 'mehendi',
          enabled: true,
        ),
        InvitationEvent(
          id: 'event_sangeet',
          name: 'Sangeet',
          date: 'Saturday, 15 November 2026',
          time: '7:00 PM',
          venue: 'Royal Ballroom',
          description:
              'An evening of music, dance and unforgettable celebrations.',
          icon: 'sangeet',
          enabled: true,
        ),
        InvitationEvent(
          id: 'event_wedding',
          name: 'Wedding Ceremony',
          date: 'Sunday, 16 November 2026',
          time: '7:00 PM',
          venue: 'Lotus Lawn',
          description:
              'Join us as we exchange vows and begin our forever together.',
          icon: 'wedding',
          enabled: true,
        ),
        InvitationEvent(
          id: 'event_reception',
          name: 'Reception',
          date: 'Sunday, 16 November 2026',
          time: '9:00 PM',
          venue: 'Grand Ballroom',
          description:
              'Dinner, music and a beautiful evening with our loved ones.',
          icon: 'reception',
          enabled: true,
        ),
      ],

      // -----------------------------------------------------------------------
      // DEMO PHOTOS
      // -----------------------------------------------------------------------

      photos: const [
        InvitationPhoto(
          id: 'couple_photo',
          url: 'https://cdn.corenexis.com/f/Hpp3irZzSuU.jpg',
          type: InvitationPhotoType.couple,
          order: 0,
        ),
        InvitationPhoto(
          id: 'bride_photo',
          url:
              'https://images.unsplash.com/photo-1529634806980-85c3dd6d34ac?auto=format&fit=crop&w=900&q=82',
          type: InvitationPhotoType.bride,
          order: 0,
        ),
        InvitationPhoto(
          id: 'groom_photo',
          url:
              'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=900&q=82',
          type: InvitationPhotoType.groom,
          order: 0,
        ),
        InvitationPhoto(
          id: 'story_photo_1',
          url:
              'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?auto=format&fit=crop&w=1200&q=82',
          type: InvitationPhotoType.story,
          order: 0,
        ),
        InvitationPhoto(
          id: 'story_photo_2',
          url:
              'https://images.unsplash.com/photo-1507504031003-b417219a0fde?auto=format&fit=crop&w=1200&q=82',
          type: InvitationPhotoType.story,
          order: 1,
        ),
        InvitationPhoto(
          id: 'gallery_photo_1',
          url:
              'https://images.unsplash.com/photo-1519225421980-715cb0215aed?auto=format&fit=crop&w=1200&q=82',
          type: InvitationPhotoType.gallery,
          order: 0,
        ),
        InvitationPhoto(
          id: 'gallery_photo_2',
          url:
              'https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&w=1200&q=82',
          type: InvitationPhotoType.gallery,
          order: 1,
        ),
        InvitationPhoto(
          id: 'gallery_photo_3',
          url:
              'https://images.unsplash.com/photo-1504150558240-0b4fd8946624?auto=format&fit=crop&w=1200&q=82',
          type: InvitationPhotoType.gallery,
          order: 2,
        ),
        InvitationPhoto(
          id: 'gallery_photo_4',
          url:
              'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=1200&q=82',
          type: InvitationPhotoType.gallery,
          order: 3,
        ),
        InvitationPhoto(
          id: 'gallery_photo_5',
          url:
              'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?auto=format&fit=crop&w=1200&q=82',
          type: InvitationPhotoType.gallery,
          order: 4,
        ),
        InvitationPhoto(
          id: 'venue_photo',
          url:
              'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=1400&q=82',
          type: InvitationPhotoType.venue,
          order: 0,
        ),
      ],

      // -----------------------------------------------------------------------
      // FEATURES
      // -----------------------------------------------------------------------

      countdownEnabled: true,
      rsvpEnabled: true,
      musicEnabled: false,
      musicId: null,

      // -----------------------------------------------------------------------
      // PUBLISHING
      // -----------------------------------------------------------------------

      published: false,
      slug: '',

      // -----------------------------------------------------------------------
      // TIMESTAMPS
      // -----------------------------------------------------------------------

      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  // ===========================================================================
  // CURRENT INVITATION
  // ===========================================================================

  InvitationModel get _currentInvitation =>
      _publishedInvitation ??
      widget.invitation ??
      _buildTestInvitation();

  // ===========================================================================
  // OPENING
  // ===========================================================================

  void _handleInvitationOpened() {
    if (!mounted) return;

    setState(() {
      _invitationOpened = true;
    });
  }

  void _replayOpening() {
    setState(() {
      _invitationOpened = false;
    });
  }

  // ===========================================================================
  // PUBLISH
  // ===========================================================================

  Future<void> _publishInvitation() async {
    if (_isPublishing) return;

    final InvitationModel currentInvitation =
        _currentInvitation;

    if (!currentInvitation.canPublish) {
      _showMessage(
        'Please complete the required invitation details before publishing.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final PublishedInvitationResult result =
          await _publishService.publish(
        currentInvitation,
      );

      if (!mounted) return;

      setState(() {
        _publishedInvitation = result.invitation;
      });

      await _showPublishedDialog(result);
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Could not publish invitation.\n$error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  // ===========================================================================
  // PUBLISHED DIALOG
  // ===========================================================================

  Future<void> _showPublishedDialog(
    PublishedInvitationResult result,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E8B57),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Invitation Published',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Your wedding invitation is now saved as a public invitation.',
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F3ED),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: SelectableText(
                  result.url,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D4C41),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Slug: ${result.slug}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF806F68),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFF8B3A3A)
            : const Color(0xFF3D6B52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        content: Text(message),
      ),
    );
  }

  // ===========================================================================
  // PUBLISH BUTTON
  // ===========================================================================

  Widget _buildPublishButton() {
    final bool published =
        _publishedInvitation?.published == true;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          14,
        ),
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                _isPublishing ? null : _publishInvitation,
            icon: _isPublishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : Icon(
                    published
                        ? Icons.public_rounded
                        : Icons.publish_rounded,
                  ),
            label: Text(
              _isPublishing
                  ? 'Publishing...'
                  : published
                      ? 'Published'
                      : 'Publish Invitation',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFFA83D58),
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  const Color(0xFFB8899A),
              elevation: 4,
              shadowColor:
                  const Color(0xFFA83D58).withValues(
                alpha: 0.25,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PREVIEW
  // ===========================================================================

  Widget _buildInvitationPreview(
    InvitationModel invitation,
  ) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final bool isDesktop =
            constraints.maxWidth >= 700;

        // ---------------------------------------------------------------
        // DESKTOP / TABLET
        // ---------------------------------------------------------------

        if (isDesktop) {
          return Container(
            width: 430,
            margin: const EdgeInsets.symmetric(
              vertical: 24,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  blurRadius: 35,
                  spreadRadius: 2,
                  offset: const Offset(0, 15),
                  color: Colors.black.withValues(
                    alpha: 0.12,
                  ),
                ),
              ],
            ),
            child: InvitationRenderer(
              invitation: invitation,
              isPreview: true,
            ),
          );
        }

        // ---------------------------------------------------------------
        // MOBILE
        // ---------------------------------------------------------------

        return InvitationRenderer(
          invitation: invitation,
          isPreview: true,
        );
      },
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final InvitationModel currentInvitation =
        _currentInvitation;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F1EC),

      // -----------------------------------------------------------------------
      // APP BAR
      // -----------------------------------------------------------------------

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF3D2926),
        centerTitle: true,
        title: const Text(
          'Lotus Royale Preview',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          if (_invitationOpened)
            IconButton(
              tooltip: 'Replay opening',
              onPressed: _replayOpening,
              icon: const Icon(
                Icons.replay_rounded,
              ),
            ),
        ],
      ),

      // -----------------------------------------------------------------------
      // PREVIEW + PUBLISH
      // -----------------------------------------------------------------------

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _invitationOpened
                    ? _buildInvitationPreview(
                        currentInvitation,
                      )
                    : LotusRoyaleOpening(
                        invitation:
                            currentInvitation,
                        onOpened:
                            _handleInvitationOpened,
                      ),
              ),
            ),

            // -----------------------------------------------------------------
            // PUBLISH ACTION
            // -----------------------------------------------------------------

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, -5),
                    color: Colors.black.withValues(
                      alpha: 0.07,
                    ),
                  ),
                ],
              ),
              child: _buildPublishButton(),
            ),
          ],
        ),
      ),
    );
  }
}