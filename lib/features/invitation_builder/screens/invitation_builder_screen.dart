import 'package:flutter/material.dart';

import '../models/invitation_event.dart';
import '../models/invitation_model.dart';
import '../models/invitation_photo.dart';
import 'invitation_preview_test_screen.dart';

class InvitationBuilderScreen extends StatefulWidget {
  const InvitationBuilderScreen({
    super.key,
  });

  @override
  State<InvitationBuilderScreen> createState() =>
      _InvitationBuilderScreenState();
}

class _InvitationBuilderScreenState
    extends State<InvitationBuilderScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _brideNameController =
      TextEditingController();

  final TextEditingController _groomNameController =
      TextEditingController();

  final TextEditingController _brideDescriptionController =
      TextEditingController();

  final TextEditingController _groomDescriptionController =
      TextEditingController();

  final TextEditingController _weddingDateController =
      TextEditingController();

  final TextEditingController _weddingTimeController =
      TextEditingController();

  final TextEditingController _storyTitleController =
      TextEditingController();

  final TextEditingController _storyTextController =
      TextEditingController();

  final TextEditingController _venueNameController =
      TextEditingController();

  final TextEditingController _venueAddressController =
      TextEditingController();

  // ============================================================
  // SETTINGS
  // ============================================================

  bool _countdownEnabled = true;

  bool _rsvpEnabled = true;

  bool _musicEnabled = false;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDefaultData();
  }

  @override
  void dispose() {
    _brideNameController.dispose();
    _groomNameController.dispose();

    _brideDescriptionController.dispose();
    _groomDescriptionController.dispose();

    _weddingDateController.dispose();
    _weddingTimeController.dispose();

    _storyTitleController.dispose();
    _storyTextController.dispose();

    _venueNameController.dispose();
    _venueAddressController.dispose();

    super.dispose();
  }

  // ============================================================
  // DEFAULT DATA
  // ============================================================

  void _loadDefaultData() {
    final DateTime weddingDate =
        DateTime.now().add(
      const Duration(days: 45),
    );

    _brideNameController.text = 'Ananya';

    _groomNameController.text = 'Arjun';

    _brideDescriptionController.text =
        'A dreamer with a heart full of love and a smile that lights up every room.';

    _groomDescriptionController.text =
        'A believer in beautiful journeys, endless laughter and forever.';

    _weddingDateController.text =
        '${weddingDate.day.toString().padLeft(2, '0')} '
        '${_monthName(weddingDate.month)} '
        '${weddingDate.year}';

    _weddingTimeController.text = '7:00 PM';

    _storyTitleController.text =
        'A Story Written in Love';

    _storyTextController.text =
        'What started with a simple hello slowly became a beautiful journey '
        'filled with laughter, friendship, countless memories and a love '
        'that grew stronger with every passing day. '
        'Now, surrounded by the people who mean the most to us, '
        'we are ready to begin our forever.';

    _venueNameController.text =
        'The Grand Lotus Palace';

    _venueAddressController.text =
        'MG Road, Pune, Maharashtra';
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

  // ============================================================
  // BUILD INVITATION
  // ============================================================

  InvitationModel _buildInvitation() {
    return InvitationModel(
      id: 'builder_lotus_royale_001',

      userId: 'test_user',

      templateId: 'lotus_royale',

      themeId: 'lotus_royale',

      // --------------------------------------------------------
      // COUPLE
      // --------------------------------------------------------

      brideName:
          _brideNameController.text.trim(),

      groomName:
          _groomNameController.text.trim(),

      brideDescription:
          _brideDescriptionController.text.trim(),

      groomDescription:
          _groomDescriptionController.text.trim(),

      // --------------------------------------------------------
      // WEDDING
      // --------------------------------------------------------

      weddingDate:
          _weddingDateController.text.trim(),

      weddingTime:
          _weddingTimeController.text.trim(),

      // --------------------------------------------------------
      // STORY
      // --------------------------------------------------------

      storyTitle:
          _storyTitleController.text.trim(),

      storyText:
          _storyTextController.text.trim(),

      // --------------------------------------------------------
      // VENUE
      // --------------------------------------------------------

      venueName:
          _venueNameController.text.trim(),

      venueAddress:
          _venueAddressController.text.trim(),

      venueLatitude: null,

      venueLongitude: null,

      // --------------------------------------------------------
      // EVENTS
      //
      // Five premium event entries for the Lotus Royale
      // Events section.
      // --------------------------------------------------------

      events: const [
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
          id: 'event_haldi',

          name: 'Haldi',

          date: 'Thursday, 13 November 2026',

          time: '10:00 AM',

          venue: 'Garden Courtyard',

          description:
              'A joyful morning filled with family, flowers, blessings and celebration.',

          icon: 'haldi',

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

      // --------------------------------------------------------
      // PHOTOS
      // --------------------------------------------------------

      photos: const [
        // Main couple image
        InvitationPhoto(
          id: 'demo_couple',
          url: 'https://cdn.corenexis.com/f/Hpp3irZzSuU.jpg',
          type: InvitationPhotoType.couple,
          order: 0,
        ),

        // Bride portrait
        InvitationPhoto(
          id: 'demo_bride',
          url: 'https://cdn.corenexis.com/f/ZlNYBaRFeJq.jpeg',
          type: InvitationPhotoType.bride,
          order: 0,
        ),

        // Groom portrait
        InvitationPhoto(
          id: 'demo_groom',
          url: 'https://cdn.corenexis.com/f/xzx6uQvsMb0.webp',
          type: InvitationPhotoType.groom,
          order: 0,
        ),

        // Story images
        InvitationPhoto(
          id: 'demo_story_1',
          url: 'https://cdn.corenexis.com/f/g2yZaYU8qpf.jpeg',
          type: InvitationPhotoType.story,
          order: 0,
        ),
        InvitationPhoto(
          id: 'demo_story_2',
          url: 'https://cdn.corenexis.com/f/gRo7M8deRRc.png',
          type: InvitationPhotoType.story,
          order: 1,
        ),

        // Gallery images
        InvitationPhoto(
          id: 'demo_gallery_1',
          url: 'https://cdn.corenexis.com/f/g2yZaYU8qpf.jpeg',
          type: InvitationPhotoType.gallery,
          order: 0,
        ),
        InvitationPhoto(
          id: 'demo_gallery_2',
          url: 'https://cdn.corenexis.com/f/gRo7M8deRRc.png',
          type: InvitationPhotoType.gallery,
          order: 1,
        ),
        InvitationPhoto(
          id: 'demo_gallery_3',
          url: 'https://cdn.corenexis.com/f/gRo7M8deRRc.png',
          type: InvitationPhotoType.gallery,
          order: 2,
        ),
        InvitationPhoto(
          id: 'demo_gallery_4',
          url: 'https://cdn.corenexis.com/f/gRo7M8deRRc.png',
          type: InvitationPhotoType.gallery,
          order: 3,
        ),
        InvitationPhoto(
          id: 'demo_gallery_5',
          url: 'https://cdn.corenexis.com/f/gRo7M8deRRc.png',
          type: InvitationPhotoType.gallery,
          order: 4,
        ),

        // Venue image
        InvitationPhoto(
          id: 'demo_venue',
          url: 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=1400&q=82',
          type: InvitationPhotoType.venue,
          order: 0,
        ),
      ],

      // --------------------------------------------------------
      // FEATURES
      // --------------------------------------------------------

      countdownEnabled:
          _countdownEnabled,

      rsvpEnabled:
          _rsvpEnabled,

      musicEnabled:
          _musicEnabled,

      musicId: null,

      // --------------------------------------------------------
      // PUBLISH
      // --------------------------------------------------------

      published: false,

      slug: '',

      // --------------------------------------------------------
      // DATES
      // --------------------------------------------------------

      createdAt: DateTime.now(),

      updatedAt: DateTime.now(),
    );
  }

  // ============================================================
  // OPEN PREVIEW
  // ============================================================

  void _openPreview() {
    final InvitationModel invitation =
        _buildInvitation();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            InvitationPreviewTestScreen(
          invitation: invitation,
        ),
      ),
    );
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (_) {
          setState(() {});
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,

          filled: true,

          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5D8D1),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFA83D58),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D2926),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF806F68),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COUPLE SECTION
  // ============================================================

  Widget _buildCoupleSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'The Couple',
          subtitle:
              'Tell us about the bride and groom.',
        ),

        _textField(
          label: 'Bride Name',
          hint: 'Enter bride name',
          controller:
              _brideNameController,
        ),

        _textField(
          label: 'Groom Name',
          hint: 'Enter groom name',
          controller:
              _groomNameController,
        ),

        _textField(
          label: 'Bride Description',
          hint:
              'Write a short description',
          controller:
              _brideDescriptionController,
          maxLines: 3,
        ),

        _textField(
          label: 'Groom Description',
          hint:
              'Write a short description',
          controller:
              _groomDescriptionController,
          maxLines: 3,
        ),
      ],
    );
  }

  // ============================================================
  // WEDDING SECTION
  // ============================================================

  Widget _buildWeddingSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Wedding Details',
          subtitle:
              'Set the main wedding date and time.',
        ),

        _textField(
          label: 'Wedding Date',
          hint:
              'Example: 25 December 2026',
          controller:
              _weddingDateController,
        ),

        _textField(
          label: 'Wedding Time',
          hint:
              'Example: 7:00 PM',
          controller:
              _weddingTimeController,
        ),
      ],
    );
  }

  // ============================================================
  // STORY SECTION
  // ============================================================

  Widget _buildStorySection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Our Story',
          subtitle:
              'Share the story behind your beautiful journey.',
        ),

        _textField(
          label: 'Story Title',
          hint:
              'Example: A Story Written in Love',
          controller:
              _storyTitleController,
        ),

        _textField(
          label: 'Story',
          hint:
              'Tell your story...',
          controller:
              _storyTextController,
          maxLines: 7,
        ),
      ],
    );
  }

  // ============================================================
  // VENUE SECTION
  // ============================================================

  Widget _buildVenueSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Venue',
          subtitle:
              'Where will you celebrate your special day?',
        ),

        _textField(
          label: 'Venue Name',
          hint:
              'Example: The Grand Lotus Palace',
          controller:
              _venueNameController,
        ),

        _textField(
          label: 'Venue Address',
          hint:
              'Enter complete address',
          controller:
              _venueAddressController,
          maxLines: 3,
        ),
      ],
    );
  }

  // ============================================================
  // FEATURES SECTION
  // ============================================================

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Invitation Features',
          subtitle:
              'Choose which features appear on your invitation.',
        ),

        _featureSwitch(
          title: 'Countdown',
          subtitle:
              'Show a countdown until the wedding.',
          value:
              _countdownEnabled,
          onChanged: (value) {
            setState(() {
              _countdownEnabled =
                  value;
            });
          },
        ),

        _featureSwitch(
          title: 'RSVP',
          subtitle:
              'Allow guests to respond to your invitation.',
          value:
              _rsvpEnabled,
          onChanged: (value) {
            setState(() {
              _rsvpEnabled =
                  value;
            });
          },
        ),

        _featureSwitch(
          title: 'Background Music',
          subtitle:
              'Play music on the invitation.',
          value:
              _musicEnabled,
          onChanged: (value) {
            setState(() {
              _musicEnabled =
                  value;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // FEATURE SWITCH
  // ============================================================

  Widget _featureSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5D8D1),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor:
            const Color(0xFFA83D58),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF3D2926),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF806F68),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F2EE),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F2EE),

        foregroundColor:
            const Color(0xFF3D2926),

        elevation: 0,

        title: const Text(
          'Create Invitation',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 12,
            ),
            child: TextButton.icon(
              onPressed: _openPreview,
              icon: const Icon(
                Icons.visibility_outlined,
              ),
              label: const Text(
                'Preview',
              ),
              style:
                  TextButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xFFA83D58,
                ),
              ),
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            120,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TEMPLATE
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                margin:
                    const EdgeInsets.only(
                  bottom: 28,
                ),
                decoration:
                    BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xFFA83D58),
                      Color(0xFFC56B7F),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withValues(
                          alpha: 0.18,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Lotus Royale',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),

                          SizedBox(
                            height: 4,
                          ),

                          Text(
                            'Premium floral wedding invitation',
                            style:
                                TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // COUPLE
              // ==================================================

              _buildCoupleSection(),

              const SizedBox(
                height: 28,
              ),

              // ==================================================
              // WEDDING
              // ==================================================

              _buildWeddingSection(),

              const SizedBox(
                height: 28,
              ),

              // ==================================================
              // STORY
              // ==================================================

              _buildStorySection(),

              const SizedBox(
                height: 28,
              ),

              // ==================================================
              // VENUE
              // ==================================================

              _buildVenueSection(),

              const SizedBox(
                height: 28,
              ),

              // ==================================================
              // FEATURES
              // ==================================================

              _buildFeaturesSection(),

              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),

      // ========================================================
      // BOTTOM PREVIEW BUTTON
      // ========================================================

      bottomNavigationBar:
          SafeArea(
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12,
          ),
          decoration:
              BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset:
                    const Offset(
                  0,
                  -5,
                ),
                color:
                    Colors.black.withValues(
                  alpha: 0.08,
                ),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child:
                ElevatedButton.icon(
              onPressed: _openPreview,
              icon: const Icon(
                Icons.visibility_rounded,
              ),
              label: const Text(
                'Preview Invitation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFA83D58,
                ),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}