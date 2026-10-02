import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/lead.dart';
import '../../models/visit.dart';
import 'customer_selection_screen.dart';
import 'services/visit_service.dart';

class AddVisitScreen extends StatefulWidget {
  const AddVisitScreen({super.key});

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen> {
  static const _indigo = Color(0xFF4F46E5);
  static const _background = Color(0xFFF7F8FC);
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  // TESTING ONLY: replace this with your Google Places API key.
  // Later we can move this key to Firestore / a backend.
  static const String _googlePlacesApiKey =
      'AIzaSyAsHkvRLLcGhLuVLeFTK0nKP71Uk2CI2oY';
  static const double _nearbyRadiusMeters = 100.0;

  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _purposeController = TextEditingController(text: 'Client Meeting');
  final _notesController = TextEditingController();
  final _nearbySearchController = TextEditingController();

  final _service = VisitService.instance;
  final Geocoding _geocoding = Geocoding();
  final _picker = ImagePicker();
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  VisitType _visitType = VisitType.selfAdded;
  DateTime _scheduledAt = DateTime.now();

  double? _latitude;
  double? _longitude;
  String? _placeId;
  String? _mapsUrl;
  String? _selectedPlaceName;
  Position? _currentPosition;
  final List<_NearbyPlace> _nearbyPlaces = [];
  String? _nearbyPlacesError;

  List<_NearbyPlace> get _filteredNearbyPlaces {
    final query = _nearbySearchController.text.trim().toLowerCase();
    if (query.isEmpty) return List<_NearbyPlace>.unmodifiable(_nearbyPlaces);

    return _nearbyPlaces.where((place) {
      final haystack = [
        place.name,
        place.address,
        place.primaryType ?? '',
        _prettyPlaceType(place.primaryType ?? ''),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  bool _isSaving = false;
  bool _isGettingLocation = false;
  bool _isLoadingNearbyPlaces = false;
  bool _isUploadingPhotos = false;

  final List<XFile> _photos = [];
  Lead? _selectedLead;

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    _nearbySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntro(),
                const SizedBox(height: 20),
                _buildSection(
                  'Visit Type',
                  'Choose how this visit was created',
                  _buildVisitTypeSelector(),
                ),
                const SizedBox(height: 18),
                _buildSection(
                  'Customer',
                  'Select the customer this visit belongs to',
                  _buildCustomerSection(),
                ),
                const SizedBox(height: 18),
                _buildSection(
                  'Visit Schedule',
                  'When will you meet the customer?',
                  _buildScheduleSection(),
                ),
                const SizedBox(height: 18),
                _buildSection(
                  'Location',
                  'Where will the visit happen?',
                  _buildLocationSection(),
                ),
                const SizedBox(height: 18),
                _buildSection(
                  'Visit Purpose',
                  'What is the objective of this visit?',
                  _buildPurposeSection(),
                ),
                const SizedBox(height: 18),
                _buildSection(
                  'Photos',
                  'Optional photos related to the visit',
                  _buildPhotosSection(),
                ),
                const SizedBox(height: 18),
                _buildSection(
                  'Lead',
                  'This visit will stay connected to the selected lead',
                  _buildLeadSection(),
                ),
                const SizedBox(height: 18),
                _buildSection(
                  'Notes',
                  'Add any additional information',
                  _buildNotesSection(),
                ),
                const SizedBox(height: 26),
                _buildSaveButton(),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'You can edit visit details later.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(13),
            child: const Icon(Icons.arrow_back_rounded, color: _text, size: 21),
          ),
        ),
      ),
      titleSpacing: 16,
      title: const Text(
        'Add Visit',
        style: TextStyle(
          color: _text,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          _IntroIcon(),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create a new visit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select a customer, schedule the visit and capture the important details.',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildVisitTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _visitTypeCard(
            VisitType.selfAdded,
            Icons.add_location_alt_outlined,
            'Self Added',
            'Add a visit manually',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _visitTypeCard(
            VisitType.scheduled,
            Icons.event_available_outlined,
            'Scheduled',
            'Pre-planned customer visit',
          ),
        ),
      ],
    );
  }

  Widget _visitTypeCard(
    VisitType type,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final selected = _visitType == type;
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () {
              if (type == VisitType.selfAdded) {
                setState(() {
                  _visitType = type;
                  _scheduledAt = DateTime.now();
                });
              } else {
                setState(() {
                  _visitType = type;
                  final now = DateTime.now();
                  _scheduledAt = now.add(const Duration(hours: 1));
                });
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? _indigo : _border,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? _indigo : Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : _muted,
                size: 19,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: selected ? const Color(0xFF312E81) : const Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return _selectedLead == null
        ? _buildSelectCustomerCard()
        : _buildSelectedCustomerCard();
  }

  Widget _buildSelectCustomerCard() {
    return InkWell(
      onTap: _isSaving ? null : _selectCustomer,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDE1EA)),
        ),
        child: const Row(
          children: [
            _SquareIcon(icon: Icons.person_search_rounded),
            SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Customer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Search and select an existing customer or lead',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCustomerCard() {
    final lead = _selectedLead!;
    final location = [
      if ((lead.area ?? '').trim().isNotEmpty) lead.area!.trim(),
      if ((lead.city ?? '').trim().isNotEmpty) lead.city!.trim(),
    ].join(', ');

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE1EA)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SquareIcon(icon: Icons.business_rounded),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.businessName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lead.contactPerson,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _isSaving ? null : _selectCustomer,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _indigo),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                _customerInfoRow(Icons.phone_outlined, lead.phone),
                if ((lead.email ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _customerInfoRow(Icons.email_outlined, lead.email!.trim()),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _customerInfoRow(Icons.location_on_outlined, location),
                ],
                if (lead.category.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _customerInfoRow(Icons.category_outlined, lead.category),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectCustomer() async {
    FocusScope.of(context).unfocus();

    final lead = await Navigator.push<Lead>(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerLeadSelectionScreen(),
      ),
    );

    if (lead == null || !mounted) return;

    setState(() {
      _selectedLead = lead;
      _addressController.text = lead.address ?? '';
      _cityController.text = lead.city ?? '';
      _areaController.text = lead.area ?? '';
      _latitude = lead.latitude;
      _longitude = lead.longitude;
      _placeId = lead.placeId;
      _mapsUrl = lead.mapsUrl;
      _selectedPlaceName = null;

      if (_purposeController.text.trim().isEmpty) {
        _purposeController.text = 'Client Meeting';
      }
    });

    FocusScope.of(context).unfocus();
  }

  Widget _buildScheduleSection() {
    if (_visitType == VisitType.selfAdded) {
      final now = DateTime.now();
      final displayTime = _scheduledAt;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF059669),
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Visit time is automatic',
                    style: TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(displayTime)} • ${_formatTime(displayTime)}',
                    style: const TextStyle(
                      color: Color(0xFF047857),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Self Added visits use the current mobile date and time.',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 9.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh current time',
              onPressed: _isSaving
                  ? null
                  : () => setState(() => _scheduledAt = now),
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        InkWell(
          onTap: _isSaving ? null : _selectDate,
          borderRadius: BorderRadius.circular(14),
          child: _selectionTile(
            Icons.calendar_today_outlined,
            'Visit Date',
            _formatDate(_scheduledAt),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _isSaving ? null : _selectTime,
          borderRadius: BorderRadius.circular(14),
          child: _selectionTile(
            Icons.access_time_outlined,
            'Visit Time',
            _formatTime(_scheduledAt),
          ),
        ),
      ],
    );
  }

  Widget _selectionTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _indigo, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final hasLocation = _latitude != null && _longitude != null;
    final hasSelectedPlace = _selectedPlaceName != null && _placeId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_visitType == VisitType.selfAdded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.gps_fixed_rounded, color: _indigo, size: 18),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Self Added visits require a nearby place selected within 100 meters of your current mobile location.',
                    style: TextStyle(
                      color: Color(0xFF3730A3),
                      fontSize: 10.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (hasSelectedPlace)
          _buildSelectedPlaceCard()
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_outlined, color: Color(0xFF9CA3AF), size: 21),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _visitType == VisitType.selfAdded
                        ? 'No nearby place selected yet.'
                        : 'You can select a customer place or capture a location.',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Material(
                color: hasLocation ? const Color(0xFFECFDF5) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _isGettingLocation || _isSaving ? null : _getCurrentLocation,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasLocation ? const Color(0xFFA7F3D0) : _border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: hasLocation ? const Color(0xFFD1FAE5) : Colors.white,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: _isGettingLocation
                              ? const Padding(
                                  padding: EdgeInsets.all(11),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF059669),
                                  ),
                                )
                              : Icon(
                                  hasLocation
                                      ? Icons.location_on_rounded
                                      : Icons.my_location_outlined,
                                  color: hasLocation ? const Color(0xFF059669) : _indigo,
                                  size: 19,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasLocation ? 'Location captured' : 'Find nearby places',
                                style: const TextStyle(
                                  color: _text,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                hasLocation
                                    ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                                    : 'Use current GPS location',
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: 48,
              height: 68,
              child: Material(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _isGettingLocation || _isSaving || _currentPosition == null
                      ? null
                      : _loadNearbyPlaces,
                  borderRadius: BorderRadius.circular(14),
                  child: const Icon(Icons.refresh_rounded, color: _indigo, size: 21),
                ),
              ),
            ),
          ],
        ),
        if (_nearbyPlacesError != null) ...[
          const SizedBox(height: 9),
          _buildPlacesError(),
        ],
        if (_isLoadingNearbyPlaces) ...[
          const SizedBox(height: 12),
          _buildNearbyLoading(),
        ],
        if (!_isLoadingNearbyPlaces && _nearbyPlaces.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.near_me_rounded, size: 15, color: _indigo),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Nearby places',
                  style: TextStyle(color: _text, fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${_filteredNearbyPlaces.length}/${_nearbyPlaces.length}',
                style: const TextStyle(color: _muted, fontSize: 9.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildNearbySearchField(),
          const SizedBox(height: 8),
          if (_filteredNearbyPlaces.isEmpty)
            _buildNoNearbySearchResults()
          else
            ..._filteredNearbyPlaces.map(_buildNearbyPlaceCard),
        ],
        if (hasLocation && _addressController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _textField(
            controller: _addressController,
            label: 'Address',
            hint: 'Selected place address',
            icon: Icons.home_outlined,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _textField(
                  controller: _cityController,
                  label: 'City',
                  hint: 'Pune',
                  icon: Icons.location_city_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _textField(
                  controller: _areaController,
                  label: 'Area',
                  hint: 'Baner',
                  icon: Icons.map_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
        ],
        if (_mapsUrl != null) ...[
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF059669)),
              SizedBox(width: 6),
              Text(
                'Google Maps location linked to this visit',
                style: TextStyle(
                  color: Color(0xFF047857),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedPlaceCard() {
    final distance = _currentPosition != null && _latitude != null && _longitude != null
        ? Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            _latitude!,
            _longitude!,
          )
        : null;

    final within100 = distance != null && distance <= _nearbyRadiusMeters;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: within100 ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: within100 ? const Color(0xFFA7F3D0) : const Color(0xFFFED7AA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: within100 ? const Color(0xFFD1FAE5) : const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              within100 ? Icons.verified_rounded : Icons.location_off_rounded,
              color: within100 ? const Color(0xFF059669) : const Color(0xFFEA580C),
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPlaceName ?? 'Selected place',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: within100 ? const Color(0xFF065F46) : const Color(0xFF9A3412),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                if (_addressController.text.trim().isNotEmpty)
                  Text(
                    _addressController.text.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 10, height: 1.35),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.radar_rounded,
                      size: 13,
                      color: within100 ? const Color(0xFF059669) : const Color(0xFFEA580C),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      distance == null
                          ? 'Distance unavailable'
                          : '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} m from you',
                      style: TextStyle(
                        color: within100 ? const Color(0xFF047857) : const Color(0xFFC2410C),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Change place',
            onPressed: _isSaving ? null : _loadNearbyPlaces,
            icon: const Icon(Icons.swap_horiz_rounded, color: _indigo, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbySearchField() {
    return TextField(
      controller: _nearbySearchController,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: _text,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Search these nearby places...',
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _indigo,
          size: 19,
        ),
        suffixIcon: _nearbySearchController.text.isEmpty
            ? const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    '20 max',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _nearbySearchController.clear();
                  setState(() {});
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 18,
                ),
              ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _indigo, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildNoNearbySearchResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: Color(0xFF9CA3AF),
            size: 27,
          ),
          const SizedBox(height: 7),
          const Text(
            'No matching place found',
            style: TextStyle(
              color: _text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Try another name from the ${_nearbyPlaces.length} places found within 100 m.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 9.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyPlaceCard(_NearbyPlace place) {
    final selected = _placeId == place.placeId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _isSaving ? null : () => _selectNearbyPlace(place),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? _indigo : _border, width: selected ? 1.2 : 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: selected ? _indigo : Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    _iconForPlaceType(place.primaryType),
                    color: selected ? Colors.white : _indigo,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _text, fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        place.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 9.5, height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded, size: 12, color: _indigo),
                          const SizedBox(width: 4),
                          Text(
                            '${place.distanceMeters.toStringAsFixed(place.distanceMeters < 10 ? 1 : 0)} m away',
                            style: const TextStyle(color: _indigo, fontSize: 9, fontWeight: FontWeight.w800),
                          ),
                          if (place.primaryType != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _prettyPlaceType(place.primaryType!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                  color: selected ? _indigo : const Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: _indigo),
          ),
          SizedBox(height: 9),
          Text(
            'Finding nearby places within 100 m...',
            style: TextStyle(color: _muted, fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _nearbyPlacesError!,
              style: const TextStyle(color: Color(0xFF9A3412), fontSize: 10, height: 1.35, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeSection() {
    const purposes = [
      'Client Meeting',
      'Product Demo',
      'Follow-up',
      'Site Visit',
      'Proposal',
    ];

    return Column(
      children: [
        _textField(
          controller: _purposeController,
          label: 'Purpose',
          hint: 'e.g. Product demo / client meeting',
          icon: Icons.track_changes_outlined,
          required: true,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: purposes.map((purpose) {
            final selected = _purposeController.text.trim() == purpose;
            return GestureDetector(
              onTap: _isSaving
                  ? null
                  : () => setState(() {
                        _purposeController.text = purpose;
                      }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? _indigo : _border),
                ),
                child: Text(
                  purpose,
                  style: TextStyle(
                    color: selected ? _indigo : const Color(0xFF4B5563),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      children: [
        if (_photos.isEmpty) _buildPhotoEmptyState() else _buildPhotoGrid(),
        const SizedBox(height: 12),
        Material(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: _isSaving ? null : _pickPhotos,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: _indigo, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Add Photos',
                    style: TextStyle(color: _indigo, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Up to 6 photos will be uploaded securely to Firebase Storage when you save the visit.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 9.5, height: 1.4),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.photo_library_outlined, color: Color(0xFF9CA3AF), size: 28),
          SizedBox(height: 8),
          Text(
            'No photos added',
            style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 3),
          Text(
            'Photos are optional',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.file(File(photo.path), fit: BoxFit.cover),
            ),
            Positioned(
              right: 5,
              top: 5,
              child: GestureDetector(
                onTap: _isSaving
                    ? null
                    : () => setState(() => _photos.removeAt(index)),
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 15),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeadSection() {
    final lead = _selectedLead;

    if (lead == null) {
      return Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 19),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Select a customer first. The visit will automatically connect to that customer and lead.',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 10.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.link_rounded, color: Color(0xFF059669), size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lead connected',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${lead.businessName} • ${lead.leadId}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 9.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _textField(
      controller: _notesController,
      label: 'Notes',
      hint: 'Add meeting details, requirements, observations...',
      icon: Icons.notes_outlined,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w500),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, size: 19, color: const Color(0xFF9CA3AF)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 45),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        labelStyle: const TextStyle(color: _muted, fontSize: 11),
        hintStyle: const TextStyle(color: Color(0xFFC4C7CE), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        border: _inputBorder(_border),
        enabledBorder: _inputBorder(_border),
        focusedBorder: _inputBorder(_indigo, 1.3),
        errorBorder: _inputBorder(const Color(0xFFEF4444)),
        focusedErrorBorder: _inputBorder(const Color(0xFFEF4444), 1.3),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildSaveButton() {
    final busy = _isSaving || _isUploadingPhotos;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: busy ? null : _saveVisit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _indigo,
          disabledBackgroundColor: const Color(0xFF818CF8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: busy
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    _isUploadingPhotos ? 'Uploading photos...' : 'Saving visit...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Save Visit',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    if (_visitType == VisitType.selfAdded) return;
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = _scheduledAt.isBefore(now) ? now : _scheduledAt;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _indigo),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      );
    });
  }

  Future<void> _selectTime() async {
    if (_visitType == VisitType.selfAdded) return;
    FocusScope.of(context).unfocus();

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _indigo),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
      _nearbyPlacesError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Please enable location services.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError('Location permission is required.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission is permanently denied. Enable it from Settings.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      String address = '';
      String city = '';
      String area = '';

      try {
        final placemarks = await _geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          address = [
            if ((p.name ?? '').trim().isNotEmpty) p.name!.trim(),
            if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
            if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
          ].where((e) => e.isNotEmpty).join(', ');
          city = (p.locality ?? p.subAdministrativeArea ?? '').trim();
          area = (p.subLocality ?? p.subAdministrativeArea ?? '').trim();
        }
      } catch (_) {
        // Google Places result will still provide the actual selected address.
      }

      setState(() {
        _currentPosition = position;
        _latitude = position.latitude;
        _longitude = position.longitude;
        _selectedPlaceName = null;
        _placeId = null;
        _mapsUrl =
            'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
        if (address.isNotEmpty) _addressController.text = address;
        if (city.isNotEmpty) _cityController.text = city;
        if (area.isNotEmpty) _areaController.text = area;
      });

      await _loadNearbyPlaces(position: position);

      if (!mounted) return;
      if (_nearbyPlaces.isEmpty) {
        _showMessage('No Google place was found within 100 m.');
      } else {
        _showSuccess('${_nearbyPlaces.length} nearby place(s) found.');
      }
    } catch (_) {
      _showError('Unable to get your current location.');
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _loadNearbyPlaces({Position? position}) async {
    final current = position ?? _currentPosition;
    if (current == null) {
      _showError('Capture your current location first.');
      return;
    }

    if (_googlePlacesApiKey.trim().isEmpty ||
        _googlePlacesApiKey.contains('PASTE_YOUR')) {
      setState(() {
        _nearbyPlacesError =
            'Add your Google Places API key in _googlePlacesApiKey before testing nearby places.';
      });
      return;
    }

    setState(() {
      _isLoadingNearbyPlaces = true;
      _nearbyPlacesError = null;
      _nearbySearchController.clear();
    });

    try {
      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:searchNearby'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _googlePlacesApiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.primaryType',
        },
        body: jsonEncode({
          'maxResultCount': 20,
          'rankPreference': 'DISTANCE',
          'locationRestriction': {
            'circle': {
              'center': {
                'latitude': current.latitude,
                'longitude': current.longitude,
              },
              'radius': _nearbyRadiusMeters,
            },
          },
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Unable to load nearby places.';
        try {
          final body = jsonDecode(response.body);
          final apiMessage = body['error']?['message'];
          if (apiMessage is String && apiMessage.trim().isNotEmpty) {
            message = apiMessage.trim();
          }
        } catch (_) {}
        throw StateError(message);
      }

      final decoded = jsonDecode(response.body);
      final rawPlaces = decoded['places'];
      final places = <_NearbyPlace>[];

      if (rawPlaces is List) {
        for (final raw in rawPlaces) {
          if (raw is! Map<String, dynamic>) continue;

          final location = raw['location'];
          final lat = (location?['latitude'] as num?)?.toDouble();
          final lng = (location?['longitude'] as num?)?.toDouble();
          final placeId = raw['id']?.toString();
          final name = raw['displayName']?['text']?.toString().trim();
          final address = raw['formattedAddress']?.toString().trim();
          final primaryType = raw['primaryType']?.toString();

          if (lat == null || lng == null || placeId == null || placeId.isEmpty) {
            continue;
          }

          final distance = Geolocator.distanceBetween(
            current.latitude,
            current.longitude,
            lat,
            lng,
          );

          // Local validation is intentional even though Google also applies
          // the 100 m location restriction.
          if (distance > _nearbyRadiusMeters) continue;

          places.add(
            _NearbyPlace(
              placeId: placeId,
              name: name == null || name.isEmpty ? 'Unnamed place' : name,
              address: address == null || address.isEmpty ? 'Address unavailable' : address,
              latitude: lat,
              longitude: lng,
              distanceMeters: distance,
              primaryType: primaryType,
            ),
          );
        }
      }

      places.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      if (!mounted) return;
      setState(() {
        _nearbyPlaces
          ..clear()
          ..addAll(places);
        _nearbyPlacesError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nearbyPlaces.clear();
        _nearbyPlacesError = _placesFriendlyError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingNearbyPlaces = false);
      }
    }
  }

  Future<void> _selectNearbyPlace(_NearbyPlace place) async {
    if (_currentPosition == null) {
      _showError('Current location is required before selecting a place.');
      return;
    }

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      place.latitude,
      place.longitude,
    );

    if (distance > _nearbyRadiusMeters) {
      _showError('This place is ${distance.toStringAsFixed(0)} m away. It must be within 100 m.');
      return;
    }

    String city = '';
    String area = '';
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        place.latitude,
        place.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        city = (p.locality ?? p.subAdministrativeArea ?? '').trim();
        area = (p.subLocality ?? p.subAdministrativeArea ?? '').trim();
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _selectedPlaceName = place.name;
      _placeId = place.placeId;
      _latitude = place.latitude;
      _longitude = place.longitude;
      _addressController.text = place.address;
      if (city.isNotEmpty) _cityController.text = city;
      if (area.isNotEmpty) _areaController.text = area;
      _mapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}&query_place_id=${Uri.encodeComponent(place.placeId)}';
    });

    FocusScope.of(context).unfocus();
    _showSuccess('${place.name} selected • ${distance.toStringAsFixed(distance < 10 ? 1 : 0)} m away');
  }

  IconData _iconForPlaceType(String? type) {
    if (type == null) return Icons.place_outlined;
    final value = type.toLowerCase();
    if (value.contains('restaurant') || value.contains('cafe') || value.contains('food')) {
      return Icons.restaurant_outlined;
    }
    if (value.contains('office') || value.contains('corporate')) {
      return Icons.business_outlined;
    }
    if (value.contains('school') || value.contains('university')) {
      return Icons.school_outlined;
    }
    if (value.contains('hospital') || value.contains('doctor')) {
      return Icons.local_hospital_outlined;
    }
    if (value.contains('store') || value.contains('shopping')) {
      return Icons.storefront_outlined;
    }
    if (value.contains('hotel')) return Icons.hotel_outlined;
    if (value.contains('bank')) return Icons.account_balance_outlined;
    return Icons.place_outlined;
  }

  String _prettyPlaceType(String type) {
    final cleaned = type.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return '';
    return cleaned
        .split(' ')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _placesFriendlyError(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '').trim();
    final lower = message.toLowerCase();

    if (lower.contains('api key') || lower.contains('permission_denied') || lower.contains('request denied')) {
      return 'Google Places rejected the request. Check the API key, Places API (New), billing and key restrictions.';
    }
    if (lower.contains('network') || lower.contains('socket') || lower.contains('timed out')) {
      return 'Unable to reach Google Places. Please check your internet connection.';
    }
    return message.isEmpty ? 'Unable to load nearby places.' : message;
  }

  Future<void> _pickPhotos() async {
    try {
      final remaining = 6 - _photos.length;
      if (remaining <= 0) {
        _showMessage('Maximum 6 photos can be added.');
        return;
      }

      final images = await _picker.pickMultiImage(imageQuality: 80);
      if (images.isEmpty || !mounted) return;

      final selected = images.take(remaining).toList();

      setState(() => _photos.addAll(selected));

      if (images.length > remaining) {
        _showMessage('Only $remaining more photo(s) could be added.');
      }
    } catch (_) {
      _showError('Unable to select photos.');
    }
  }

  Future<({List<String> urls, List<Reference> references})> _uploadPhotos(String visitId) async {
    if (_photos.isEmpty) {
      return (urls: <String>[], references: <Reference>[]);
    }

    setState(() => _isUploadingPhotos = true);

    final urls = <String>[];
    final references = <Reference>[];

    try {
      for (var i = 0; i < _photos.length; i++) {
        final file = File(_photos[i].path);

        // Do not silently skip a selected photo. If it disappeared from the
        // device before saving, fail the save so the user knows about it.
        if (!await file.exists()) {
          throw StateError(
            'Photo ${i + 1} is no longer available on this device.',
          );
        }

        final extension = _extensionFromPath(_photos[i].path);
        final fileName = '${_uuid.v4()}.$extension';

        final ref = _storage.ref().child(
          'visits/$visitId/photos/$fileName',
        );

        await ref.putFile(file);
        references.add(ref);
        urls.add(await ref.getDownloadURL());
      }

      return (urls: urls, references: references);
    } catch (_) {
      // If one of the uploads fails, remove anything that was already
      // uploaded so Storage does not accumulate orphaned files.
      await _deleteUploadedPhotos(references);
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhotos = false);
      }
    }
  }

  Future<void> _deleteUploadedPhotos(List<Reference> references) async {
    if (references.isEmpty) return;

    for (final reference in references) {
      try {
        await reference.delete();
      } catch (_) {
        // Cleanup should never hide the original save/upload error.
      }
    }
  }

  String _extensionFromPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return 'jpg';
    return path.substring(dot + 1).toLowerCase();
  }

  Future<void> _saveVisit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final lead = _selectedLead;
    if (lead == null) {
      _showError('Please select a customer before saving the visit.');
      return;
    }

    final now = DateTime.now();

    if (_visitType == VisitType.selfAdded) {
      _scheduledAt = now;
    } else if (_scheduledAt.isBefore(now)) {
      _showError('Please select a future visit date and time.');
      return;
    }

    if (_visitType == VisitType.selfAdded) {
      if (_currentPosition == null || _latitude == null || _longitude == null) {
        _showError('Capture your current location and select a nearby place first.');
        return;
      }

      if (_placeId == null || _selectedPlaceName == null) {
        _showError('Please select a place from the nearby places list.');
        return;
      }

      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _latitude!,
        _longitude!,
      );

      if (distance > _nearbyRadiusMeters) {
        _showError('Selected place is ${distance.toStringAsFixed(0)} m away. Self Added visits require a place within 100 m.');
        return;
      }
    }

    final uid = _service.currentUserUid;
    if (uid == null) {
      _showError('Your session has expired. Please login again.');
      return;
    }

    setState(() => _isSaving = true);

    final visitId = _uuid.v4();
    List<Reference> uploadedPhotoReferences = [];

    try {
      final uploadResult = await _uploadPhotos(visitId);
      final photoUrls = uploadResult.urls;
      uploadedPhotoReferences = uploadResult.references;

      final visit = Visit(
        visitId: visitId,
        customerUid: lead.customerUid,
        leadId: lead.leadId,
        visitType: _visitType,
        status: VisitStatus.planned,
        createdBy: uid,
        assignedTo: uid,
        scheduledAt: _scheduledAt,
        startedAt: null,
        completedAt: null,
        latitude: _latitude,
        longitude: _longitude,
        address: _nullableText(_addressController.text),
        city: _nullableText(_cityController.text),
        area: _nullableText(_areaController.text),
        placeId: _placeId,
        mapsUrl: _mapsUrl,
        photos: photoUrls,
        purpose: _purposeController.text.trim(),
        outcome: null,
        notes: _nullableText(_notesController.text),
        nextFollowUpAt: null,
        createLead: false,
        leadCreated: true,
        createdAt: now,
        updatedAt: now,
      );

      try {
        await _service.createVisit(visit: visit);
      } catch (_) {
        // Firestore failed after Storage succeeded. Remove the uploaded
        // photos so the visit does not leave orphaned Storage files.
        await _deleteUploadedPhotos(uploadedPhotoReferences);
        rethrow;
      }

      if (!mounted) return;

      _showSuccess('Visit created successfully.');
      await Future.delayed(const Duration(milliseconds: 450));

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingPhotos = false;
        });
      }
    }
  }

  String? _nullableText(String value) {
    final result = value.trim();
    return result.isEmpty ? null : result;
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: const Color(0xFF065F46),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: const Color(0xFF991B1B),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: _text,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('permission-denied')) {
      return 'You do not have permission to create this visit.';
    }

    if (message.contains('network') || message.contains('unavailable')) {
      return 'Please check your internet connection.';
    }

    if (message.contains('storage')) {
      return 'Photo upload failed. Please try again.';
    }

    return 'Unable to create visit. Please try again.';
  }
}

class _NearbyPlace {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final String? primaryType;

  const _NearbyPlace({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.primaryType,
  });
}

class _IntroIcon extends StatelessWidget {
  const _IntroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.location_on_outlined,
        color: Color(0xFFA5B4FC),
        size: 24,
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  final IconData icon;

  const _SquareIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: const Color(0xFF4F46E5), size: 23),
    );
  }
}
