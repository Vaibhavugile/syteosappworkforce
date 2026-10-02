import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../models/lead.dart';

class CustomerLeadSelectionScreen extends StatefulWidget {
  const CustomerLeadSelectionScreen({
    super.key,
  });

  @override
  State<CustomerLeadSelectionScreen> createState() =>
      _CustomerLeadSelectionScreenState();
}

class _CustomerLeadSelectionScreenState
    extends State<CustomerLeadSelectionScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final Uuid _uuid = const Uuid();

  bool _isLoading = true;
  bool _isCreatingCustomer = false;

  String _search = '';

  List<Lead> _leads = [];

  @override
  void initState() {
    super.initState();

    _loadLeads();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _search =
            _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD EXISTING LEADS
  // ============================================================

  Future<void> _loadLeads() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final uid = _auth.currentUser?.uid;

      if (uid == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        _showError(
          'You must be logged in to select a customer.',
        );

        return;
      }

      final results = await Future.wait([
        _firestore
            .collection('leads')
            .where(
              'assignedTo',
              isEqualTo: uid,
            )
            .limit(100)
            .get(),

        _firestore
            .collection('leads')
            .where(
              'createdBy',
              isEqualTo: uid,
            )
            .limit(100)
            .get(),
      ]);

      final Map<String, Lead> leadMap =
          <String, Lead>{};

      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          try {
            final lead = Lead.fromMap(
              doc.id,
              doc.data(),
            );

            if (lead.isActive) {
              leadMap[doc.id] = lead;
            }
          } catch (e) {
            debugPrint(
              'Could not parse lead ${doc.id}: $e',
            );
          }
        }
      }

      final leads = leadMap.values.toList();

      leads.sort((a, b) {
        final aDate =
            a.updatedAt ?? a.createdAt;

        final bDate =
            b.updatedAt ?? b.createdAt;

        if (aDate == null && bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        _leads = leads;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Load customers error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError(
        'Unable to load customers. Please try again.',
      );
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Lead> get _filteredLeads {
    if (_search.isEmpty) {
      return _leads;
    }

    return _leads.where((lead) {
      final businessName =
          lead.businessName.toLowerCase();

      final contactPerson =
          lead.contactPerson.toLowerCase();

      final phone =
          lead.phone.toLowerCase();

      final email =
          (lead.email ?? '').toLowerCase();

      final city =
          (lead.city ?? '').toLowerCase();

      final area =
          (lead.area ?? '').toLowerCase();

      final category =
          lead.category.toLowerCase();

      return businessName.contains(_search) ||
          contactPerson.contains(_search) ||
          phone.contains(_search) ||
          email.contains(_search) ||
          city.contains(_search) ||
          area.contains(_search) ||
          category.contains(_search);
    }).toList();
  }

  // ============================================================
  // SELECT EXISTING LEAD
  // ============================================================

  void _selectLead(Lead lead) {
    Navigator.pop(
      context,
      lead,
    );
  }

  // ============================================================
  // OPEN NEW CUSTOMER FORM
  // ============================================================

  Future<void> _openNewCustomerForm() async {
    final lead = await showModalBottomSheet<Lead>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _NewCustomerSheet();
      },
    );

    if (!mounted || lead == null) {
      return;
    }

    Navigator.pop(
      context,
      lead,
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor:
              const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // STATUS LABEL
  // ============================================================

  String _statusLabel(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return 'New';

      case LeadStatus.contacted:
        return 'Contacted';

      case LeadStatus.interested:
        return 'Interested';

      case LeadStatus.followUp:
        return 'Follow Up';

      case LeadStatus.visitScheduled:
        return 'Visit Scheduled';

      case LeadStatus.visitCompleted:
        return 'Visit Completed';

      case LeadStatus.demo:
        return 'Demo';

      case LeadStatus.proposal:
        return 'Proposal';

      case LeadStatus.negotiation:
        return 'Negotiation';

      case LeadStatus.won:
        return 'Won';

      case LeadStatus.lost:
        return 'Lost';

      case LeadStatus.notInterested:
        return 'Not Interested';

      case LeadStatus.invalid:
        return 'Invalid';
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return const Color(0xFF4F46E5);

      case LeadStatus.contacted:
        return const Color(0xFF0284C7);

      case LeadStatus.interested:
        return const Color(0xFF059669);

      case LeadStatus.followUp:
        return const Color(0xFFD97706);

      case LeadStatus.visitScheduled:
        return const Color(0xFF7C3AED);

      case LeadStatus.visitCompleted:
        return const Color(0xFF16A34A);

      case LeadStatus.demo:
        return const Color(0xFF0891B2);

      case LeadStatus.proposal:
        return const Color(0xFF9333EA);

      case LeadStatus.negotiation:
        return const Color(0xFFEA580C);

      case LeadStatus.won:
        return const Color(0xFF15803D);

      case LeadStatus.lost:
        return const Color(0xFFDC2626);

      case LeadStatus.notInterested:
        return const Color(0xFF64748B);

      case LeadStatus.invalid:
        return const Color(0xFF475569);
    }
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();

    if (value.contains('salon') ||
        value.contains('beauty')) {
      return Icons.content_cut_rounded;
    }

    if (value.contains('dental') ||
        value.contains('medical') ||
        value.contains('clinic')) {
      return Icons.local_hospital_rounded;
    }

    if (value.contains('restaurant') ||
        value.contains('food')) {
      return Icons.restaurant_rounded;
    }

    if (value.contains('gym') ||
        value.contains('fitness')) {
      return Icons.fitness_center_rounded;
    }

    if (value.contains('school') ||
        value.contains('education')) {
      return Icons.school_rounded;
    }

    if (value.contains('hotel')) {
      return Icons.hotel_rounded;
    }

    if (value.contains('real estate') ||
        value.contains('property')) {
      return Icons.apartment_rounded;
    }

    return Icons.business_rounded;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filteredLeads = _filteredLeads;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF111827),
          ),
        ),

        title: Text(
          'Select Customer',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
      ),

      body: Column(
        children: [
          _buildSearchSection(),

          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          Color(0xFF4F46E5),
                    ),
                  )
                : filteredLeads.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color:
                            const Color(
                          0xFF4F46E5,
                        ),
                        onRefresh:
                            _loadLeads,
                        child:
                            ListView.builder(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            16,
                            10,
                            16,
                            120,
                          ),
                          itemCount:
                              filteredLeads.length,
                          itemBuilder:
                              (context, index) {
                            return _buildLeadCard(
                              filteredLeads[
                                  index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _openNewCustomerForm,
        backgroundColor:
            const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 6,

        icon: const Icon(
          Icons.person_add_alt_1_rounded,
        ),

        label: Text(
          'New Customer',
          style: GoogleFonts.manrope(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Select an existing customer or add a new one',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color:
                  const Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            height: 52,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF3F4F8),
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color:
                    const Color(0xFFE5E7EB),
              ),
            ),
            child: TextField(
              controller:
                  _searchController,
              textInputAction:
                  TextInputAction.search,

              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color:
                    const Color(0xFF111827),
              ),

              decoration:
                  InputDecoration(
                border:
                    InputBorder.none,

                prefixIcon:
                    const Icon(
                  Icons.search_rounded,
                  color:
                      Color(0xFF6B7280),
                ),

                hintText:
                    'Search business, contact, phone...',

                hintStyle:
                    GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w500,
                  color:
                      const Color(0xFF9CA3AF),
                ),

                suffixIcon:
                    _search.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController
                                  .clear();
                            },
                            icon:
                                const Icon(
                              Icons
                                  .close_rounded,
                              size: 20,
                              color:
                                  Color(
                                0xFF6B7280,
                              ),
                            ),
                          )
                        : null,

                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 4,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LEAD CARD
  // ============================================================

  Widget _buildLeadCard(
    Lead lead,
  ) {
    final statusColor =
        _statusColor(lead.status);

    final locationParts =
        <String>[
      if ((lead.area ?? '')
          .trim()
          .isNotEmpty)
        lead.area!.trim(),

      if ((lead.city ?? '')
          .trim()
          .isNotEmpty)
        lead.city!.trim(),
    ];

    final location =
        locationParts.join(', ');

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              const Color(0xFFE8EAF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.025),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          onTap: () =>
              _selectLead(lead),

          child: Padding(
            padding:
                const EdgeInsets.all(
              15,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFEEF2FF,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                  ),
                  child: Icon(
                    _categoryIcon(
                      lead.category,
                    ),
                    color:
                        const Color(
                      0xFF4F46E5,
                    ),
                    size: 23,
                  ),
                ),

                const SizedBox(
                  width: 13,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lead.businessName,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  GoogleFonts
                                      .manrope(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                color:
                                    const Color(
                                  0xFF111827,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          _statusBadge(
                            _statusLabel(
                              lead.status,
                            ),
                            statusColor,
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        lead.contactPerson,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            GoogleFonts
                                .manrope(
                          fontSize: 12.5,
                          fontWeight:
                              FontWeight
                                  .w600,
                          color:
                              const Color(
                            0xFF6B7280,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 9,
                      ),

                      Row(
                        children: [
                          const Icon(
                            Icons
                                .phone_outlined,
                            size: 15,
                            color:
                                Color(
                              0xFF9CA3AF,
                            ),
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Expanded(
                            child: Text(
                              lead.phone,
                              style:
                                  GoogleFonts
                                      .manrope(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight
                                        .w600,
                                color:
                                    const Color(
                                  0xFF4B5563,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (location
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 5,
                        ),

                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .location_on_outlined,
                              size: 15,
                              color:
                                  Color(
                                0xFF9CA3AF,
                              ),
                            ),

                            const SizedBox(
                              width: 5,
                            ),

                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    GoogleFonts
                                        .manrope(
                                  fontSize:
                                      12,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  color:
                                      const Color(
                                    0xFF4B5563,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                const Padding(
                  padding:
                      EdgeInsets.only(
                    top: 16,
                  ),
                  child: Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                        Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    String label,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            color.withOpacity(0.09),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 9.5,
          fontWeight:
              FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final hasSearch =
        _search.isNotEmpty;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFEEF2FF,
                ),
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
              child: const Icon(
                Icons
                    .people_outline_rounded,
                size: 38,
                color:
                    Color(0xFF4F46E5),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              hasSearch
                  ? 'No customer found'
                  : 'No customers yet',
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.manrope(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
                color:
                    const Color(
                  0xFF111827,
                ),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              hasSearch
                  ? 'Try another business name, phone number or contact.'
                  : 'You can create the customer directly while adding a visit.',
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.manrope(
                fontSize: 13,
                height: 1.5,
                fontWeight:
                    FontWeight.w500,
                color:
                    const Color(
                  0xFF6B7280,
                ),
              ),
            ),

            if (!hasSearch) ...[
              const SizedBox(
                height: 20,
              ),

              OutlinedButton.icon(
                onPressed:
                    _openNewCustomerForm,

                icon: const Icon(
                  Icons
                      .person_add_alt_1_rounded,
                  size: 18,
                ),

                label: Text(
                  'Create Customer',
                  style:
                      GoogleFonts.manrope(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                style:
                    OutlinedButton
                        .styleFrom(
                  foregroundColor:
                      const Color(
                    0xFF4F46E5,
                  ),
                  side:
                      const BorderSide(
                    color:
                        Color(0xFF4F46E5),
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ================================================================
// NEW CUSTOMER SHEET
// ================================================================

class _NewCustomerSheet
    extends StatefulWidget {
  const _NewCustomerSheet();

  @override
  State<_NewCustomerSheet> createState() =>
      _NewCustomerSheetState();
}

class _NewCustomerSheetState
    extends State<_NewCustomerSheet> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final Uuid _uuid = const Uuid();

  final _formKey =
      GlobalKey<FormState>();

  final _businessNameController =
      TextEditingController();

  final _contactPersonController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  final _alternatePhoneController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _categoryController =
      TextEditingController();

  final _addressController =
      TextEditingController();

  final _cityController =
      TextEditingController();

  final _areaController =
      TextEditingController();

  final _notesController =
      TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _categoryController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  // ============================================================
  // CREATE CUSTOMER + LEAD
  // ============================================================

  Future<void> _createCustomer() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      _showError(
        'You must be logged in.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final businessName =
          _businessNameController.text
              .trim();

      final contactPerson =
          _contactPersonController.text
              .trim();

      final phone =
          _phoneController.text.trim();

      final alternatePhone =
          _alternatePhoneController
              .text
              .trim();

      final email =
          _emailController.text.trim();

      final category =
          _categoryController.text
              .trim();

      final address =
          _addressController.text
              .trim();

      final city =
          _cityController.text.trim();

      final area =
          _areaController.text.trim();

      final notes =
          _notesController.text.trim();

      // --------------------------------------------------------
      // CHECK IF PHONE ALREADY EXISTS
      // --------------------------------------------------------

      final existingSnapshot =
          await _firestore
              .collection('leads')
              .where(
                'phone',
                isEqualTo: phone,
              )
              .where(
                'isActive',
                isEqualTo: true,
              )
              .limit(1)
              .get();

      if (existingSnapshot.docs
          .isNotEmpty) {
        final existingDoc =
            existingSnapshot.docs.first;

        final existingLead =
            Lead.fromMap(
          existingDoc.id,
          existingDoc.data(),
        );

        if (!mounted) return;

        final useExisting =
            await _showExistingCustomerDialog(
          existingLead,
        );

        if (useExisting == true) {
          if (!mounted) return;

          Navigator.pop(
            context,
            existingLead,
          );

          return;
        }

        if (!mounted) return;

        setState(() {
          _isSaving = false;
        });

        return;
      }

      // --------------------------------------------------------
      // CUSTOMER UID
      // --------------------------------------------------------

      final customerUid =
          _uuid.v4();

      // --------------------------------------------------------
      // LEAD DOCUMENT
      // --------------------------------------------------------

      final leadDocument =
          _firestore
              .collection('leads')
              .doc();

      final now = DateTime.now();

      final lead = Lead(
        leadId: leadDocument.id,

        customerUid:
            customerUid,

        businessName:
            businessName,

        category:
            category.isEmpty
                ? 'Other'
                : category,

        contactPerson:
            contactPerson,

        phone:
            phone,

        alternatePhone:
            alternatePhone.isEmpty
                ? null
                : alternatePhone,

        email:
            email.isEmpty
                ? null
                : email,

        address:
            address.isEmpty
                ? null
                : address,

        city:
            city.isEmpty
                ? null
                : city,

        area:
            area.isEmpty
                ? null
                : area,

        latitude: null,
        longitude: null,
        placeId: null,
        mapsUrl: null,

        photos:
            const [],

        status:
            LeadStatus.newLead,

        source:
            LeadSource.selfVisit,

        priority:
            LeadPriority.medium,

        createdBy:
            user.uid,

        assignedTo:
            user.uid,

        notes:
            notes.isEmpty
                ? null
                : notes,

        nextFollowUpAt:
            null,

        createdAt:
            now,

        updatedAt:
            now,

        isActive:
            true,
      );

      final data =
          lead.toMap();

      data['createdAt'] =
          FieldValue.serverTimestamp();

      data['updatedAt'] =
          FieldValue.serverTimestamp();

      await leadDocument.set(
        data,
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // RETURN CREATED LEAD
      // --------------------------------------------------------

      Navigator.pop(
        context,
        lead,
      );
    } catch (e) {
      debugPrint(
        'Create customer error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError(
        'Unable to create customer. Please try again.',
      );
    }
  }

  // ============================================================
  // EXISTING CUSTOMER DIALOG
  // ============================================================

  Future<bool?> _showExistingCustomerDialog(
    Lead lead,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
          ),

          title: Text(
            'Customer already exists',
            style:
                GoogleFonts.manrope(
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
              color:
                  const Color(
                0xFF111827,
              ),
            ),
          ),

          content: Text(
            '${lead.businessName} is already saved with this phone number.\n\nWould you like to use this existing customer for the visit?',
            style:
                GoogleFonts.manrope(
              fontSize: 13,
              height: 1.5,
              fontWeight:
                  FontWeight.w500,
              color:
                  const Color(
                0xFF6B7280,
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: Text(
                'Use another number',
                style:
                    GoogleFonts.manrope(
                  fontWeight:
                      FontWeight.w700,
                  color:
                      const Color(
                    0xFF6B7280,
                  ),
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF4F46E5,
                ),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: Text(
                'Use Existing',
                style:
                    GoogleFonts.manrope(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.manrope(
              fontWeight:
                  FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor:
              const Color(0xFFDC2626),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      );
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController
        controller,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int maxLines = 1,
    bool required = false,
    IconData? prefixIcon,
    String? Function(String?)?
        validator,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 15,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style:
                    GoogleFonts.manrope(
                  fontSize: 12.5,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      const Color(
                    0xFF374151,
                  ),
                ),
              ),

              if (required)
                Text(
                  ' *',
                  style:
                      GoogleFonts.manrope(
                    fontSize: 12.5,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        const Color(
                      0xFFDC2626,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 7,
          ),

          TextFormField(
            controller: controller,
            keyboardType:
                keyboardType,
            textInputAction:
                textInputAction,
            maxLines:
                maxLines,
            validator:
                validator,

            style:
                GoogleFonts.manrope(
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
              color:
                  const Color(
                0xFF111827,
              ),
            ),

            decoration:
                InputDecoration(
              hintText: hint,

              hintStyle:
                  GoogleFonts.manrope(
                fontSize: 13,
                fontWeight:
                    FontWeight.w500,
                color:
                    const Color(
                  0xFF9CA3AF,
                ),
              ),

              prefixIcon:
                  prefixIcon == null
                      ? null
                      : Icon(
                          prefixIcon,
                          size: 19,
                          color:
                              const Color(
                            0xFF9CA3AF,
                          ),
                        ),

              filled: true,

              fillColor:
                  const Color(
                0xFFF8F9FC,
              ),

              contentPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 14,
                vertical: 14,
              ),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFFE5E7EB),
                ),
              ),

              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFFE5E7EB),
                ),
              ),

              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFF4F46E5),
                  width: 1.4,
                ),
              ),

              errorBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFFDC2626),
                ),
              ),

              focusedErrorBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFFDC2626),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return SafeArea(
      top: false,
      child: Container(
        constraints:
            BoxConstraints(
          maxHeight:
              MediaQuery.of(context)
                      .size
                      .height *
                  0.94,
        ),
        decoration:
            const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding:
                EdgeInsets.fromLTRB(
              20,
              14,
              20,
              24 + bottomInset,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFE5E7EB,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFEEF2FF,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .person_add_alt_1_rounded,
                        color:
                            Color(
                          0xFF4F46E5,
                        ),
                        size: 23,
                      ),
                    ),

                    const SizedBox(
                      width: 13,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'New Customer',
                            style:
                                GoogleFonts
                                    .manrope(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight
                                      .w800,
                              color:
                                  const Color(
                                0xFF111827,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            'This customer will automatically become a Lead.',
                            style:
                                GoogleFonts
                                    .manrope(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .w500,
                              color:
                                  const Color(
                                0xFF6B7280,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 24,
                ),

                Container(
                  padding:
                      const EdgeInsets.all(
                    13,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFF5F7FF,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                    border:
                        Border.all(
                      color:
                          const Color(
                        0xFFE0E7FF,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .auto_awesome_rounded,
                        size: 18,
                        color:
                            Color(
                          0xFF4F46E5,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Text(
                          'You can add a business on the spot. We will create the Lead automatically and connect it to this Visit.',
                          style:
                              GoogleFonts
                                  .manrope(
                            fontSize: 11.5,
                            height: 1.45,
                            fontWeight:
                                FontWeight
                                    .w600,
                            color:
                                const Color(
                              0xFF4B5563,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                Text(
                  'BUSINESS DETAILS',
                  style:
                      GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 0.8,
                    color:
                        const Color(
                      0xFF9CA3AF,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _field(
                  label: 'Business Name',
                  hint:
                      'e.g. Royal Fitness',
                  controller:
                      _businessNameController,
                  prefixIcon:
                      Icons.business_rounded,
                  required: true,
                  textInputAction:
                      TextInputAction.next,
                  validator: (value) {
                    if ((value ?? '')
                        .trim()
                        .isEmpty) {
                      return 'Business name is required';
                    }

                    return null;
                  },
                ),

                _field(
                  label: 'Category',
                  hint:
                      'e.g. Salon, Restaurant, Gym',
                  controller:
                      _categoryController,
                  prefixIcon:
                      Icons.category_outlined,
                  textInputAction:
                      TextInputAction.next,
                ),

                _field(
                  label: 'Contact Person',
                  hint:
                      'Owner / manager name',
                  controller:
                      _contactPersonController,
                  prefixIcon:
                      Icons.person_outline_rounded,
                  required: true,
                  textInputAction:
                      TextInputAction.next,
                  validator: (value) {
                    if ((value ?? '')
                        .trim()
                        .isEmpty) {
                      return 'Contact person is required';
                    }

                    return null;
                  },
                ),

                _field(
                  label: 'Phone',
                  hint:
                      'Primary contact number',
                  controller:
                      _phoneController,
                  prefixIcon:
                      Icons.phone_outlined,
                  keyboardType:
                      TextInputType.phone,
                  textInputAction:
                      TextInputAction.next,
                  required: true,
                  validator: (value) {
                    final phone =
                        (value ?? '')
                            .trim();

                    if (phone.isEmpty) {
                      return 'Phone number is required';
                    }

                    if (phone.length <
                        7) {
                      return 'Enter a valid phone number';
                    }

                    return null;
                  },
                ),

                _field(
                  label:
                      'Alternate Phone',
                  hint:
                      'Optional',
                  controller:
                      _alternatePhoneController,
                  prefixIcon:
                      Icons
                          .phone_android_outlined,
                  keyboardType:
                      TextInputType.phone,
                  textInputAction:
                      TextInputAction.next,
                ),

                _field(
                  label: 'Email',
                  hint:
                      'Optional',
                  controller:
                      _emailController,
                  prefixIcon:
                      Icons
                          .email_outlined,
                  keyboardType:
                      TextInputType.emailAddress,
                  textInputAction:
                      TextInputAction.next,
                  validator: (value) {
                    final email =
                        (value ?? '')
                            .trim();

                    if (email.isEmpty) {
                      return null;
                    }

                    if (!email
                        .contains('@')) {
                      return 'Enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'LOCATION',
                  style:
                      GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 0.8,
                    color:
                        const Color(
                      0xFF9CA3AF,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _field(
                  label: 'Address',
                  hint:
                      'Business address',
                  controller:
                      _addressController,
                  prefixIcon:
                      Icons
                          .location_on_outlined,
                  maxLines: 2,
                  textInputAction:
                      TextInputAction.next,
                ),

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Expanded(
                      child: _field(
                        label: 'Area',
                        hint: 'Area',
                        controller:
                            _areaController,
                        prefixIcon:
                            Icons
                                .location_city_outlined,
                        textInputAction:
                            TextInputAction.next,
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: _field(
                        label: 'City',
                        hint: 'City',
                        controller:
                            _cityController,
                        prefixIcon:
                            Icons
                                .map_outlined,
                        textInputAction:
                            TextInputAction.done,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'NOTES',
                  style:
                      GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 0.8,
                    color:
                        const Color(
                      0xFF9CA3AF,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _field(
                  label: 'Notes',
                  hint:
                      'Anything you want to remember about this customer',
                  controller:
                      _notesController,
                  prefixIcon:
                      Icons
                          .notes_outlined,
                  maxLines: 4,
                  textInputAction:
                      TextInputAction.newline,
                ),

                const SizedBox(
                  height: 4,
                ),

                // ------------------------------------------------
                // SAVE
                // ------------------------------------------------

                SizedBox(
                  width:
                      double.infinity,
                  height: 54,
                  child:
                      ElevatedButton(
                    onPressed:
                        _isSaving
                            ? null
                            : _createCustomer,

                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF4F46E5,
                      ),
                      disabledBackgroundColor:
                          const Color(
                        0xFFA5B4FC,
                      ),
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                      ),
                    ),

                    child: _isSaving
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2.2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              const Icon(
                                Icons
                                    .check_circle_outline_rounded,
                                size: 20,
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              Text(
                                'Create Customer & Continue',
                                style:
                                    GoogleFonts
                                        .manrope(
                                  fontSize:
                                      14,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Center(
                  child: Text(
                    'A Lead will be created automatically.',
                    style:
                        GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w500,
                      color:
                          const Color(
                        0xFF9CA3AF,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}