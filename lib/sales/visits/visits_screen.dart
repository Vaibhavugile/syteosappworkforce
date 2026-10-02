import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/lead.dart';
import '../../models/visit.dart';
import 'add_visit_screen.dart';
import 'services/visit_service.dart';
import 'visit_details_screen.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() =>
      _VisitsScreenState();
}

class _VisitsScreenState
    extends State<VisitsScreen> {
  final VisitService _service =
      VisitService.instance;

  int _selectedFilter = 0;

  final List<String> _filters = [
    'All',
    'Today',
    'Upcoming',
    'Completed',
    'Self Added',
  ];

  String _searchQuery = '';

  final Map<String, Lead?> _leadCache = {};

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FC),
      body: SafeArea(
        child: StreamBuilder<List<Visit>>(
          stream: _service.watchMyVisits(),
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.hasError) {
              return _buildErrorState(
                snapshot.error,
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return _buildLoadingState();
            }

            final visits =
                snapshot.data ?? [];

            final filteredVisits =
                _filterVisits(visits);

            return Column(
              children: [
                _buildHeader(),

                _buildSummary(visits),

                _buildFilters(),

                Expanded(
                  child:
                      filteredVisits.isEmpty
                          ? _buildEmptyState(
                              hasSearch:
                                  _searchQuery
                                      .isNotEmpty,
                            )
                          : RefreshIndicator(
                              color:
                                  const Color(
                                0xFF4F46E5,
                              ),
                              onRefresh:
                                  _refreshVisits,
                              child:
                                  ListView.separated(
                                physics:
                                    const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  110,
                                ),
                                itemCount:
                                    filteredVisits
                                        .length,
                                separatorBuilder:
                                    (_, __) =>
                                        const SizedBox(
                                  height: 12,
                                ),
                                itemBuilder:
                                    (
                                  context,
                                  index,
                                ) {
                                  return _buildVisitCard(
                                    filteredVisits[
                                        index],
                                  );
                                },
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton:
          _buildAddButton(),
      floatingActionButtonLocation:
          FloatingActionButtonLocation
              .centerFloat,
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visits',
                  style: TextStyle(
                    color:
                        Color(0xFF111827),
                    fontSize: 28,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _searchQuery.isEmpty
                      ? 'Manage your field visits'
                      : 'Searching visits',
                  style: const TextStyle(
                    color:
                        Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _headerButton(
            icon: Icons.search_rounded,
            active:
                _searchQuery.isNotEmpty,
            onTap:
                _showSearchDialog,
          ),
          const SizedBox(width: 8),
          _headerButton(
            icon:
                Icons.filter_list_rounded,
            active:
                _selectedFilter != 0,
            onTap:
                _showFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Material(
      color: active
          ? const Color(0xFF111827)
          : Colors.white,
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? const Color(0xFF111827)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Icon(
            icon,
            size: 21,
            color: active
                ? Colors.white
                : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(
    List<Visit> visits,
  ) {
    final now = DateTime.now();

    final todayCount =
        visits.where(
      (visit) {
        final date =
            visit.scheduledAt;

        if (date == null) {
          return false;
        }

        return _isSameDay(
          date,
          now,
        );
      },
    ).length;

    final upcomingCount =
        visits.where(
      (visit) {
        final date =
            visit.scheduledAt;

        if (date == null) {
          return false;
        }

        return date.isAfter(now) &&
            visit.status !=
                VisitStatus.completed &&
            visit.status !=
                VisitStatus.cancelled &&
            visit.status !=
                VisitStatus.missed;
      },
    ).length;

    final completedCount =
        visits.where(
      (visit) =>
          visit.status ==
          VisitStatus.completed,
    ).length;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              value:
                  visits.length.toString(),
              label: 'Total',
              icon:
                  Icons.location_on_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryItem(
              value:
                  todayCount.toString(),
              label: 'Today',
              icon:
                  Icons.today_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryItem(
              value:
                  upcomingCount.toString(),
              label: 'Upcoming',
              icon:
                  Icons.schedule_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryItem(
              value:
                  completedCount.toString(),
              label: 'Completed',
              icon:
                  Icons.check_circle_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 17,
            color:
                const Color(0xFF6366F1),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 9,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount:
            _filters.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 8),
        itemBuilder:
            (context, index) {
          final selected =
              _selectedFilter ==
                  index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter =
                    index;
              });
            },
            child:
                AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 200,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration:
                  BoxDecoration(
                color: selected
                    ? const Color(
                        0xFF111827,
                      )
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  30,
                ),
                border: Border.all(
                  color: selected
                      ? const Color(
                          0xFF111827,
                        )
                      : const Color(
                          0xFFE5E7EB,
                        ),
                ),
              ),
              alignment:
                  Alignment.center,
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(
                          0xFF6B7280,
                        ),
                  fontSize: 11,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // FILTER DATA
  // ============================================================

  List<Visit> _filterVisits(
    List<Visit> visits,
  ) {
    Iterable<Visit> result =
        visits;

    final now = DateTime.now();

    switch (_selectedFilter) {
      case 1:
        result = result.where(
          (visit) {
            final date =
                visit.scheduledAt;

            return date != null &&
                _isSameDay(
                  date,
                  now,
                );
          },
        );
        break;

      case 2:
        result = result.where(
          (visit) {
            final date =
                visit.scheduledAt;

            return date != null &&
                date.isAfter(now) &&
                visit.status !=
                    VisitStatus.completed &&
                visit.status !=
                    VisitStatus.cancelled &&
                visit.status !=
                    VisitStatus.missed;
          },
        );
        break;

      case 3:
        result = result.where(
          (visit) =>
              visit.status ==
              VisitStatus.completed,
        );
        break;

      case 4:
        result = result.where(
          (visit) =>
              visit.visitType ==
              VisitType.selfAdded,
        );
        break;

      case 0:
      default:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final query =
          _searchQuery.toLowerCase();

      result = result.where(
        (visit) {
          final values = [
            visit.visitId,
            visit.customerUid,
            visit.leadId ?? '',
            visit.purpose ?? '',
            visit.address ?? '',
            visit.city ?? '',
            visit.area ?? '',
            visit.notes ?? '',
          ];

          return values.any(
            (value) => value
                .toLowerCase()
                .contains(query),
          );
        },
      );
    }

    final list =
        result.toList();

    list.sort(
      (a, b) {
        final aDate =
            a.scheduledAt;

        final bDate =
            b.scheduledAt;

        if (aDate == null &&
            bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return aDate.compareTo(
          bDate,
        );
      },
    );

    return list;
  }

  // ============================================================
  // VISIT CARD
  // ============================================================

  Widget _buildVisitCard(
    Visit visit,
  ) {
    return FutureBuilder<Lead?>(
      future: _getLead(visit),
      builder:
          (context, snapshot) {
        final lead =
            snapshot.data;

        final businessName =
            lead?.businessName ??
                'Customer';

        final contactPerson =
            lead?.contactPerson ??
                '';

        final category =
            lead?.category ?? '';

        final location =
            _visitLocation(
          visit,
          lead,
        );

        return Material(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(22),
          child: InkWell(
            onTap: () =>
                _openVisitDetails(
              visit,
              lead,
            ),
            borderRadius:
                BorderRadius.circular(22),
            child: Container(
              padding:
                  const EdgeInsets.all(17),
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
                border: Border.all(
                  color:
                      const Color(
                    0xFFE5E7EB,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      _businessIcon(
                        category,
                        visit,
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
                                  child:
                                      Text(
                                    businessName,
                                    maxLines:
                                        1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(
                                        0xFF111827,
                                      ),
                                      fontSize:
                                          15,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                _statusBadge(
                                  visit.status,
                                ),
                              ],
                            ),
                            if (contactPerson
                                .isNotEmpty) ...[
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                contactPerson,
                                maxLines:
                                    1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                    0xFF6B7280,
                                  ),
                                  fontSize:
                                      11,
                                  fontWeight:
                                      FontWeight
                                          .w500,
                                ),
                              ),
                            ],
                            if (category
                                .isNotEmpty) ...[
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                category,
                                maxLines:
                                    1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                    0xFF9CA3AF,
                                  ),
                                  fontSize:
                                      10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Container(
                    height: 1,
                    color:
                        const Color(
                      0xFFF1F3F5,
                    ),
                  ),
                  const SizedBox(
                    height: 13,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .schedule_outlined,
                        size: 16,
                        color:
                            Color(
                          0xFF6B7280,
                        ),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Expanded(
                        child: Text(
                          _scheduleText(
                            visit,
                          ),
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF4B5563,
                            ),
                            fontSize:
                                11,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),
                      if (visit.visitType ==
                          VisitType.selfAdded)
                        _typeBadge(
                          'Self Added',
                        ),
                    ],
                  ),
                  if (location
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 9,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .location_on_outlined,
                          size: 16,
                          color:
                              Color(
                            0xFF9CA3AF,
                          ),
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF6B7280,
                              ),
                              fontSize:
                                  11,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons
                              .chevron_right_rounded,
                          size: 19,
                          color:
                              Color(
                            0xFFB0B5BD,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (visit.status ==
                          VisitStatus
                              .completed &&
                      visit.outcome !=
                          null) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    _buildOutcome(
                      visit.outcome!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutcome(
    VisitOutcome outcome,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF9FAFB),
        borderRadius:
            BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          const Icon(
            Icons
                .check_circle_outline,
            size: 15,
            color:
                Color(0xFF10B981),
          ),
          const SizedBox(width: 7),
          const Text(
            'Outcome',
            style: TextStyle(
              color:
                  Color(0xFF9CA3AF),
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _outcomeLabel(outcome),
            style:
                const TextStyle(
              color:
                  Color(0xFF374151),
              fontSize: 10,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LEAD LOOKUP
  // ============================================================

  Future<Lead?> _getLead(
    Visit visit,
  ) async {
    final key =
        visit.leadId ??
        visit.customerUid;

    if (_leadCache.containsKey(key)) {
      return _leadCache[key];
    }

    try {
      DocumentSnapshot<
          Map<String, dynamic>> snapshot;

      if (visit.leadId != null &&
          visit.leadId!.isNotEmpty) {
        snapshot =
            await FirebaseFirestore
                .instance
                .collection('leads')
                .doc(visit.leadId)
                .get();
      } else {
        final query =
            await FirebaseFirestore
                .instance
                .collection('leads')
                .where(
                  'customerUid',
                  isEqualTo:
                      visit.customerUid,
                )
                .limit(1)
                .get();

        if (query.docs.isEmpty) {
          _leadCache[key] = null;
          return null;
        }

        snapshot =
            query.docs.first;
      }

      if (!snapshot.exists ||
          snapshot.data() == null) {
        _leadCache[key] = null;
        return null;
      }

      final lead = Lead.fromMap(
        snapshot.id,
        snapshot.data()!,
      );

      _leadCache[key] = lead;

      return lead;
    } catch (e) {
      debugPrint(
        'Lead lookup error: $e',
      );

      _leadCache[key] = null;

      return null;
    }
  }

  // ============================================================
  // BUSINESS ICON
  // ============================================================

  Widget _businessIcon(
    String category,
    Visit visit,
  ) {
    IconData icon;

    final value =
        category.toLowerCase();

    if (value.contains('salon') ||
        value.contains('beauty')) {
      icon =
          Icons.content_cut_rounded;
    } else if (value.contains(
          'clinic',
        ) ||
        value.contains('medical') ||
        value.contains('dental')) {
      icon =
          Icons.local_hospital_outlined;
    } else if (value.contains('gym') ||
        value.contains('fitness')) {
      icon =
          Icons.fitness_center_outlined;
    } else if (value.contains(
          'restaurant',
        ) ||
        value.contains('food')) {
      icon =
          Icons.restaurant_outlined;
    } else if (value.contains(
          'school',
        ) ||
        value.contains('education')) {
      icon =
          Icons.school_outlined;
    } else if (value.contains('hotel')) {
      icon =
          Icons.hotel_outlined;
    } else if (value.contains(
          'real estate',
        ) ||
        value.contains('property')) {
      icon =
          Icons.apartment_outlined;
    } else if (value.contains('it')) {
      icon =
          Icons.computer_outlined;
    } else {
      icon =
          Icons.business_outlined;
    }

    final color =
        _visitColor(visit);

    return Container(
      width: 48,
      height: 48,
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(.10),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Icon(
        icon,
        color: color,
        size: 22,
      ),
    );
  }

  Color _visitColor(
    Visit visit,
  ) {
    switch (visit.status) {
      case VisitStatus.completed:
        return const Color(
          0xFF10B981,
        );

      case VisitStatus.inProgress:
        return const Color(
          0xFF4F46E5,
        );

      case VisitStatus.cancelled:
        return const Color(
          0xFFEF4444,
        );

      case VisitStatus.missed:
        return const Color(
          0xFFF97316,
        );

      case VisitStatus.planned:
        return const Color(
          0xFF6366F1,
        );
    }
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    VisitStatus status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(.09),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  Color _statusColor(
    VisitStatus status,
  ) {
    switch (status) {
      case VisitStatus.planned:
        return const Color(
          0xFFD97706,
        );

      case VisitStatus.inProgress:
        return const Color(
          0xFF4F46E5,
        );

      case VisitStatus.completed:
        return const Color(
          0xFF059669,
        );

      case VisitStatus.cancelled:
        return const Color(
          0xFFDC2626,
        );

      case VisitStatus.missed:
        return const Color(
          0xFFEA580C,
        );
    }
  }

  String _statusLabel(
    VisitStatus status,
  ) {
    switch (status) {
      case VisitStatus.planned:
        return 'Planned';

      case VisitStatus.inProgress:
        return 'In Progress';

      case VisitStatus.completed:
        return 'Completed';

      case VisitStatus.cancelled:
        return 'Cancelled';

      case VisitStatus.missed:
        return 'Missed';
    }
  }

  // ============================================================
  // TYPE BADGE
  // ============================================================

  Widget _typeBadge(
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFEEF2FF),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          color:
              Color(0xFF4F46E5),
          fontSize: 8,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState({
    required bool hasSearch,
  }) {
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
              child: Icon(
                hasSearch
                    ? Icons
                        .search_off_rounded
                    : Icons
                        .location_off_outlined,
                color:
                    const Color(
                  0xFF6366F1,
                ),
                size: 34,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              hasSearch
                  ? 'No visits found'
                  : _selectedFilter == 0
                      ? 'No visits yet'
                      : 'No matching visits',
              style:
                  const TextStyle(
                color:
                    Color(0xFF111827),
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 7,
            ),
            Text(
              hasSearch
                  ? 'Try another business name, customer, location or visit detail.'
                  : 'Start by adding a visit to a customer.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Color(0xFF9CA3AF),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            if (!hasSearch) ...[
              const SizedBox(
                height: 20,
              ),
              OutlinedButton.icon(
                onPressed:
                    _addVisit,
                icon: const Icon(
                  Icons
                      .add_location_alt_outlined,
                  size: 18,
                ),
                label: const Text(
                  'Add Visit',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                style:
                    OutlinedButton.styleFrom(
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
                        BorderRadius.circular(
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

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildHeader(),
        _buildSummarySkeleton(),
        const SizedBox(
          height: 8,
        ),
        Expanded(
          child: ListView.separated(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              110,
            ),
            itemCount: 5,
            separatorBuilder:
                (_, __) =>
                    const SizedBox(
              height: 12,
            ),
            itemBuilder:
                (_, __) =>
                    _loadingCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySkeleton() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        12,
      ),
      child: Row(
        children: List.generate(
          4,
          (index) {
            return Expanded(
              child: Container(
                height: 85,
                margin:
                    EdgeInsets.only(
                  right:
                      index == 3
                          ? 0
                          : 10,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFFE5E7EB,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      height: 175,
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFE5E7EB,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState(
    Object? error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFFEF2F2,
                ),
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
              ),
              child: const Icon(
                Icons
                    .error_outline_rounded,
                color:
                    Color(0xFFDC2626),
                size: 34,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'Unable to load visits',
              style:
                  TextStyle(
                color:
                    Color(0xFF111827),
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'Please check your connection and try again.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Color(0xFF6B7280),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text(
                'Try Again',
              ),
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
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADD BUTTON
  // ============================================================

  Widget _buildAddButton() {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child:
          FloatingActionButton.extended(
        onPressed: _addVisit,
        backgroundColor:
            const Color(0xFF111827),
        foregroundColor:
            Colors.white,
        elevation: 8,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
        icon: const Icon(
          Icons
              .add_location_alt_outlined,
          size: 20,
        ),
        label: const Text(
          'Add Visit',
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD VISIT
  // ============================================================

  Future<void> _addVisit() async {
    final result =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AddVisitScreen(),
      ),
    );

    if (result == true &&
        mounted) {
      _showMessage(
        'Visit added successfully.',
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _showSearchDialog() {
    final controller =
        TextEditingController(
      text: _searchQuery,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
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
          title: const Text(
            'Search Visits',
            style:
                TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF111827),
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction:
                TextInputAction.search,
            onSubmitted: (_) {
              Navigator.pop(
                dialogContext,
              );

              setState(() {
                _searchQuery =
                    controller.text
                        .trim();
              });
            },
            decoration:
                InputDecoration(
              hintText:
                  'Business, customer, location...',
              prefixIcon:
                  const Icon(
                Icons.search_rounded,
              ),
              suffixIcon:
                  controller.text
                          .isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            controller
                                .clear();
                          },
                          icon:
                              const Icon(
                            Icons
                                .close_rounded,
                          ),
                        )
                      : null,
              filled: true,
              fillColor:
                  const Color(
                0xFFF7F8FC,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                setState(() {
                  _searchQuery =
                      '';
                });
              },
              child: const Text(
                'Clear',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                setState(() {
                  _searchQuery =
                      controller.text
                          .trim();
                });
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
                    11,
                  ),
                ),
              ),
              child:
                  const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // FILTER SHEET
  // ============================================================

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(
                28,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFD1D5DB,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Filter Visits',
                    style:
                        TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(
                        0xFF111827,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                ...List.generate(
                  _filters.length,
                  (index) {
                    final selected =
                        _selectedFilter ==
                            index;

                    return ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      onTap: () {
                        setState(() {
                          _selectedFilter =
                              index;
                        });

                        Navigator.pop(
                          sheetContext,
                        );
                      },
                      leading:
                          Container(
                        width: 40,
                        height: 40,
                        decoration:
                            BoxDecoration(
                          color: selected
                              ? const Color(
                                  0xFFEEF2FF,
                                )
                              : const Color(
                                  0xFFF9FAFB,
                                ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                        child: Icon(
                          _filterIcon(
                            index,
                          ),
                          color: selected
                              ? const Color(
                                  0xFF4F46E5,
                                )
                              : const Color(
                                  0xFF6B7280,
                                ),
                          size: 19,
                        ),
                      ),
                      title: Text(
                        _filters[index],
                        style:
                            TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected
                                  ? FontWeight
                                      .w800
                                  : FontWeight
                                      .w600,
                          color:
                              const Color(
                            0xFF111827,
                          ),
                        ),
                      ),
                      trailing:
                          selected
                              ? const Icon(
                                  Icons
                                      .check_circle_rounded,
                                  color:
                                      Color(
                                    0xFF4F46E5,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .radio_button_unchecked_rounded,
                                  color:
                                      Color(
                                    0xFFD1D5DB,
                                  ),
                                ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _filterIcon(
    int index,
  ) {
    switch (index) {
      case 1:
        return Icons.today_outlined;
      case 2:
        return Icons.schedule_outlined;
      case 3:
        return Icons.check_circle_outline;
      case 4:
        return Icons
            .add_location_alt_outlined;
      default:
        return Icons
            .format_list_bulleted_rounded;
    }
  }

  // ============================================================
  // VISIT DETAILS
  // ============================================================

  Future<void> _openVisitDetails(
    Visit visit,
    Lead? lead,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisitDetailsScreen(
          visit: visit,
          lead: lead,
          service: _service,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _scheduleText(
    Visit visit,
  ) {
    final date =
        visit.scheduledAt;

    if (date == null) {
      return 'Schedule not set';
    }

    final dateText =
        _isSameDay(
      date,
      DateTime.now(),
    )
            ? 'Today'
            : _isTomorrow(date)
                ? 'Tomorrow'
                : _formatDateShort(
                    date,
                  );

    return '$dateText • ${_formatTime(date)}';
  }

  String _visitLocation(
    Visit visit,
    Lead? lead,
  ) {
    final parts = <String>[];

    if ((visit.area ?? '')
        .trim()
        .isNotEmpty) {
      parts.add(
        visit.area!.trim(),
      );
    } else if ((lead?.area ?? '')
        .trim()
        .isNotEmpty) {
      parts.add(
        lead!.area!.trim(),
      );
    }

    if ((visit.city ?? '')
        .trim()
        .isNotEmpty) {
      parts.add(
        visit.city!.trim(),
      );
    } else if ((lead?.city ?? '')
        .trim()
        .isNotEmpty) {
      parts.add(
        lead!.city!.trim(),
      );
    }

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    if ((visit.address ?? '')
        .trim()
        .isNotEmpty) {
      return visit.address!.trim();
    }

    if ((lead?.address ?? '')
        .trim()
        .isNotEmpty) {
      return lead!.address!.trim();
    }

    return '';
  }

  bool _isSameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }

  bool _isTomorrow(
    DateTime date,
  ) {
    final tomorrow =
        DateTime.now().add(
      const Duration(days: 1),
    );

    return _isSameDay(
      date,
      tomorrow,
    );
  }

  String _formatDateShort(
    DateTime date,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(
    DateTime date,
  ) {
    final hour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final minute =
        date.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }

  String _outcomeLabel(
    VisitOutcome outcome,
  ) {
    switch (outcome) {
      case VisitOutcome.interested:
        return 'Interested';

      case VisitOutcome.notInterested:
        return 'Not Interested';

      case VisitOutcome.followUpRequired:
        return 'Follow-up Required';

      case VisitOutcome.demoRequested:
        return 'Demo Requested';

      case VisitOutcome.proposalRequested:
        return 'Proposal Requested';

      case VisitOutcome.noResponse:
        return 'No Response';

      case VisitOutcome.notAvailable:
        return 'Not Available';

      case VisitOutcome.converted:
        return 'Converted';

      case VisitOutcome.other:
        return 'Other';
    }
  }

  Future<void> _refreshVisits() async {
    /*
     * The screen is already backed by a Firestore stream,
     * so there is no manual fetch to perform here.
     *
     * A short delay gives RefreshIndicator a proper
     * refresh interaction while Firestore continues
     * delivering live updates.
     */
    await Future.delayed(
      const Duration(
        milliseconds: 350,
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          backgroundColor:
              const Color(0xFF111827),
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
          content: Text(
            message,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      );
  }
}

// ============================================================================
// VISIT DETAILS SHEET
// ============================================================================

class _VisitDetailsSheet
    extends StatefulWidget {
  final Visit visit;
  final Lead? lead;
  final VisitService service;
  final VoidCallback onChanged;

  const _VisitDetailsSheet({
    required this.visit,
    required this.lead,
    required this.service,
    required this.onChanged,
  });

  @override
  State<_VisitDetailsSheet> createState() =>
      _VisitDetailsSheetState();
}

class _VisitDetailsSheetState
    extends State<_VisitDetailsSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final lead = widget.lead;

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        24,
      ),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(
            28,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFD1D5DB,
                    ),
                    borderRadius:
                        BorderRadius.circular(
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
                    width: 52,
                    height: 52,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFEEF2FF,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .location_on_rounded,
                      color:
                          Color(0xFF4F46E5),
                      size: 25,
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
                          lead?.businessName ??
                              'Customer',
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF111827,
                            ),
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        if ((lead?.contactPerson ??
                                '')
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            lead!
                                .contactPerson,
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF6B7280,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _statusBadge(
                    visit.status,
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              _detailRow(
                Icons
                    .calendar_today_outlined,
                'Schedule',
                _scheduleText(
                  visit,
                ),
              ),
              if ((lead?.phone ?? '')
                  .isNotEmpty)
                _detailRow(
                  Icons.phone_outlined,
                  'Phone',
                  lead!.phone,
                ),
              if ((lead?.email ?? '')
                  .isNotEmpty)
                _detailRow(
                  Icons.email_outlined,
                  'Email',
                  lead!.email!,
                ),
              if ((visit.purpose ?? '')
                  .isNotEmpty)
                _detailRow(
                  Icons
                      .track_changes_outlined,
                  'Purpose',
                  visit.purpose!,
                ),
              if (_location(
                    visit,
                    lead,
                  ).isNotEmpty)
                _detailRow(
                  Icons
                      .location_on_outlined,
                  'Location',
                  _location(
                    visit,
                    lead,
                  ),
                ),
              if ((visit.notes ?? '')
                  .isNotEmpty)
                _detailRow(
                  Icons.notes_outlined,
                  'Notes',
                  visit.notes!,
                ),
              const SizedBox(
                height: 18,
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final status =
        widget.visit.status;

    if (status ==
            VisitStatus.completed ||
        status ==
            VisitStatus.cancelled ||
        status ==
            VisitStatus.missed) {
      return _closeButton();
    }

    if (status ==
        VisitStatus.inProgress) {
      return Row(
        children: [
          Expanded(
            child: _actionButton(
              label:
                  'Complete Visit',
              icon:
                  Icons.check_circle_outline,
              color:
                  const Color(0xFF059669),
              onTap:
                  _completeVisit,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: _actionButton(
              label: 'Cancel',
              icon:
                  Icons.close_rounded,
              color:
                  const Color(0xFFDC2626),
              outlined: true,
              onTap:
                  _cancelVisit,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'Start Visit',
            icon:
                Icons.play_arrow_rounded,
            color:
                const Color(0xFF4F46E5),
            onTap:
                _startVisit,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _actionButton(
            label: 'Cancel',
            icon:
                Icons.close_rounded,
            color:
                const Color(0xFFDC2626),
            outlined: true,
            onTap:
                _cancelVisit,
          ),
        ),
      ],
    );
  }

  Widget _closeButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed:
            _loading
                ? null
                : () =>
                    Navigator.pop(
                      context,
                    ),
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              const Color(
            0xFF111827,
          ),
          side:
              const BorderSide(
            color:
                Color(0xFFE5E7EB),
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),
        ),
        child: const Text(
          'Close',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return SizedBox(
      height: 48,
      child: outlined
          ? OutlinedButton.icon(
              onPressed:
                  _loading
                      ? null
                      : onTap,
              icon: Icon(
                icon,
                size: 18,
              ),
              label: Text(
                label,
                style:
                    const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    color,
                side:
                    BorderSide(
                  color: color.withOpacity(
                    .35,
                  ),
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed:
                  _loading
                      ? null
                      : onTap,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                        color:
                            Colors.white,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 18,
                    ),
              label: Text(
                label,
                style:
                    const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    color,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF9FAFB),
        borderRadius:
            BorderRadius.circular(
          13,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color:
                const Color(
              0xFF6366F1,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF9CA3AF,
                    ),
                    fontSize: 9,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF374151,
                    ),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startVisit() async {
    setState(() {
      _loading = true;
    });

    try {
      await widget.service.startVisit(
        widget.visit.visitId,
      );

      if (!mounted) return;

      widget.onChanged();
    } catch (e) {
      _showError(
        'Unable to start visit.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _completeVisit() async {
    final outcome =
        await _selectOutcome();

    if (outcome == null) {
      return;
    }

    final notes =
        await _showCompletionNotesDialog();

    if (notes == null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await widget.service.completeVisit(
        visitId:
            widget.visit.visitId,
        outcome: outcome,
        notes: notes,
      );

      if (!mounted) return;

      widget.onChanged();
    } catch (e) {
      _showError(
        'Unable to complete visit.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<String?> _showCompletionNotesDialog() async {
    final controller = TextEditingController();

    final result =
        await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x660F172A),
      builder: (sheetContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset =
                MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(
                bottom: bottomInset,
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1D5DB),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFECFDF5),
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.notes_rounded,
                                color: Color(0xFF059669),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Visit Notes',
                                    style: TextStyle(
                                      color:
                                          Color(0xFF111827),
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.w800,
                                      letterSpacing: -.25,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Add a note before completing this visit.',
                                    style: TextStyle(
                                      color:
                                          Color(0xFF9CA3AF),
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          minLines: 4,
                          maxLines: 7,
                          maxLength: 1000,
                          textCapitalization:
                              TextCapitalization.sentences,
                          keyboardType:
                              TextInputType.multiline,
                          decoration: InputDecoration(
                            labelText: 'Notes *',
                            hintText:
                                'What happened during the visit?',
                            alignLabelWithHint: true,
                            errorText: errorText,
                            filled: true,
                            fillColor:
                                const Color(0xFFF8FAFC),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(
                                left: 14,
                                right: 10,
                                top: 14,
                              ),
                              child: Icon(
                                Icons.edit_note_rounded,
                                color:
                                    Color(0xFF6B7280),
                              ),
                            ),
                            prefixIconConstraints:
                                const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF4F46E5),
                                width: 1.5,
                              ),
                            ),
                            errorBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            focusedErrorBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFEF4444),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '* Notes are required to complete the visit.',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final notes =
                                  controller.text.trim();

                              if (notes.isEmpty) {
                                setSheetState(() {
                                  errorText =
                                      'Please enter visit notes.';
                                });
                                return;
                              }

                              Navigator.pop(
                                sheetContext,
                                notes,
                              );
                            },
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 19,
                            ),
                            label: const Text(
                              'Continue & Complete',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF059669),
                              foregroundColor:
                                  Colors.white,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton(
                            onPressed: () =>
                                Navigator.pop(
                              sheetContext,
                              null,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w700,
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
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<VisitOutcome?>
      _selectOutcome() async {
    return showModalBottomSheet<
        VisitOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x660F172A),
      builder: (sheetContext) {
        const outcomes = [
          VisitOutcome.interested,
          VisitOutcome.notInterested,
          VisitOutcome.followUpRequired,
          VisitOutcome.demoRequested,
          VisitOutcome.proposalRequested,
          VisitOutcome.noResponse,
          VisitOutcome.notAvailable,
          VisitOutcome.converted,
          VisitOutcome.other,
        ];

        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(sheetContext).size.height * .78,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.flag_outlined,
                          color: Color(0xFF4F46E5),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visit Outcome',
                              style: TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.25,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'How did this visit go?',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  color: Color(0xFFF1F3F5),
                ),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    itemCount: outcomes.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final outcome = outcomes[index];
                      final label = _outcomeLabel(outcome);
                      final icon = _outcomeIcon(outcome);

                      return Material(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pop(
                            sheetContext,
                            outcome,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: const Color(0xFF4F46E5),
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: Color(0xFF1F2937),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFFB0B5BD),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _outcomeIcon(VisitOutcome outcome) {
    switch (outcome) {
      case VisitOutcome.interested:
        return Icons.thumb_up_alt_outlined;
      case VisitOutcome.notInterested:
        return Icons.thumb_down_alt_outlined;
      case VisitOutcome.followUpRequired:
        return Icons.event_repeat_outlined;
      case VisitOutcome.demoRequested:
        return Icons.play_circle_outline_rounded;
      case VisitOutcome.proposalRequested:
        return Icons.description_outlined;
      case VisitOutcome.noResponse:
        return Icons.notifications_none_rounded;
      case VisitOutcome.notAvailable:
        return Icons.person_off_outlined;
      case VisitOutcome.converted:
        return Icons.check_circle_outline_rounded;
      case VisitOutcome.other:
        return Icons.more_horiz_rounded;
    }
  }

  Future<void> _cancelVisit() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Cancel Visit?',
          ),
          content:
              const Text(
            'Are you sure you want to cancel this visit?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text(
                'No',
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFDC2626,
                ),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Cancel Visit',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await widget.service.cancelVisit(
        widget.visit.visitId,
      );

      if (!mounted) return;

      widget.onChanged();
    } catch (e) {
      _showError(
        'Unable to cancel visit.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _scheduleText(
    Visit visit,
  ) {
    final date =
        visit.scheduledAt;

    if (date == null) {
      return 'Schedule not set';
    }

    final today =
        DateTime.now();

    String dateText;

    if (_isSameDay(
      date,
      today,
    )) {
      dateText = 'Today';
    } else if (_isSameDay(
      date,
      today.add(
        const Duration(
          days: 1,
        ),
      ),
    )) {
      dateText = 'Tomorrow';
    } else {
      dateText =
          '${date.day}/${date.month}/${date.year}';
    }

    return '$dateText • ${_formatTime(date)}';
  }

  String _formatTime(
    DateTime date,
  ) {
    final hour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final minute =
        date.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }

  String _location(
    Visit visit,
    Lead? lead,
  ) {
    if ((visit.address ?? '')
        .isNotEmpty) {
      return visit.address!;
    }

    final values = [
      visit.area,
      visit.city,
      lead?.area,
      lead?.city,
      lead?.address,
    ];

    for (final value
        in values) {
      if (value != null &&
          value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  bool _isSameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  Color _statusColor(
    VisitStatus status,
  ) {
    switch (status) {
      case VisitStatus.planned:
        return const Color(
          0xFFD97706,
        );
      case VisitStatus.inProgress:
        return const Color(
          0xFF4F46E5,
        );
      case VisitStatus.completed:
        return const Color(
          0xFF059669,
        );
      case VisitStatus.cancelled:
        return const Color(
          0xFFDC2626,
        );
      case VisitStatus.missed:
        return const Color(
          0xFFEA580C,
        );
    }
  }

  String _statusLabel(
    VisitStatus status,
  ) {
    switch (status) {
      case VisitStatus.planned:
        return 'Planned';
      case VisitStatus.inProgress:
        return 'In Progress';
      case VisitStatus.completed:
        return 'Completed';
      case VisitStatus.cancelled:
        return 'Cancelled';
      case VisitStatus.missed:
        return 'Missed';
    }
  }

  Widget _statusBadge(
    VisitStatus status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(.09),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        _statusLabel(status),
        style:
            TextStyle(
          color: color,
          fontSize: 8,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  static String _outcomeLabel(
    VisitOutcome outcome,
  ) {
    switch (outcome) {
      case VisitOutcome.interested:
        return 'Interested';
      case VisitOutcome.notInterested:
        return 'Not Interested';
      case VisitOutcome.followUpRequired:
        return 'Follow-up Required';
      case VisitOutcome.demoRequested:
        return 'Demo Requested';
      case VisitOutcome.proposalRequested:
        return 'Proposal Requested';
      case VisitOutcome.noResponse:
        return 'No Response';
      case VisitOutcome.notAvailable:
        return 'Not Available';
      case VisitOutcome.converted:
        return 'Converted';
      case VisitOutcome.other:
        return 'Other';
    }
  }

  void _showError(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor:
              const Color(0xFF991B1B),
          behavior:
              SnackBarBehavior.floating,
          content: Text(
            message,
            style:
                const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      );
  }
}