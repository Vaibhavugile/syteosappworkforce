import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/lead.dart';
import '../../models/visit.dart';
import '../visits/services/visit_service.dart';
import '../visits/visit_details_screen.dart';
import 'services/daily_history_service.dart';
import 'widgets/daily_map.dart';
import 'widgets/daily_summary.dart';
import 'widgets/date_selector.dart';
import 'widgets/timeline_event_card.dart';

class DailyHistoryScreen extends StatefulWidget {
  const DailyHistoryScreen({
    super.key,
  });

  @override
  State<DailyHistoryScreen> createState() =>
      _DailyHistoryScreenState();
}

class _DailyHistoryScreenState
    extends State<DailyHistoryScreen> {
  final _historyService =
      DailyHistoryService.instance;

  final _visitService =
      VisitService.instance;

  DateTime _selectedDate = DateTime.now();

  DailyHistoryData? _data;

  final Map<String, Lead> _leads = {};

  bool _loading = true;
  bool _loadingLeads = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data =
          await _historyService
              .getHistoryForDate(
        _selectedDate,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _data = data;
      });

      await _loadLeads(
        data.visits,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadLeads(
    List<Visit> visits,
  ) async {
    if (visits.isEmpty) {
      return;
    }

    setState(() {
      _loadingLeads = true;
    });

    try {
      final customerIds = visits
          .map((v) => v.customerUid)
          .where(
            (id) => id.trim().isNotEmpty,
          )
          .toSet();

      for (final customerUid in customerIds) {
        if (_leads.containsKey(customerUid)) {
          continue;
        }

        final snapshot =
            await _visitService
                .findLeadByCustomerUid(
          customerUid,
        );

        if (snapshot == null) {
          continue;
        }

        final lead = Lead.fromMap(
          snapshot.id,
          Map<String, dynamic>.from(
            snapshot.data(),
          ),
        );

        _leads[customerUid] = lead;
      }
    } catch (_) {
      // Lead information is supplementary.
      // The history should still work without it.
    } finally {
      if (mounted) {
        setState(() {
          _loadingLeads = false;
        });
      }
    }
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(
        const Duration(days: 1),
      );
    });

    _loadHistory();
  }

  void _nextDay() {
    final tomorrow =
        _selectedDate.add(
      const Duration(days: 1),
    );

    if (tomorrow.isAfter(
      DateTime.now(),
    )) {
      return;
    }

    setState(() {
      _selectedDate = tomorrow;
    });

    _loadHistory();
  }

  void _today() {
    setState(() {
      _selectedDate = DateTime.now();
    });

    _loadHistory();
  }

  void _selectDate(
    DateTime date,
  ) {
    setState(() {
      _selectedDate = date;
    });

    _loadHistory();
  }

  Future<void> _openVisit(
    Visit visit,
  ) async {
    final lead =
        _leads[visit.customerUid];

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitDetailsScreen(
          visit: visit,
          lead: lead,
          service: _visitService,
        ),
      ),
    );

    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F8FC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding:
              const EdgeInsets.only(left: 12),
          child: Material(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(13),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(13),
              onTap: () =>
                  Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF111827),
                size: 21,
              ),
            ),
          ),
        ),
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Daily History',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Your complete sales activity timeline',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading
                ? null
                : _loadHistory,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4F46E5),
        ),
      );
    }

    if (_error != null &&
        _data == null) {
      return _buildError();
    }

    final data = _data;

    if (data == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: _loadHistory,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding:
            const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          35,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            DateSelector(
              date: _selectedDate,
              onPrevious: _previousDay,
              onNext: _nextDay,
              onToday: _today,
              onDateSelected: _selectDate,
            ),

            const SizedBox(height: 14),

            _buildDayHero(data),

            const SizedBox(height: 18),

            DailySummary(
              data: data,
            ),

            const SizedBox(height: 22),

            _buildMapSection(data),

            const SizedBox(height: 24),

            _buildTimelineSection(data),

            const SizedBox(height: 24),

            _buildOutcomeSection(data),

            const SizedBox(height: 24),

            _buildDayMetrics(data),
          ],
        ),
      ),
    );
  }

  Widget _buildDayHero(
    DailyHistoryData data,
  ) {
    final first =
        data.firstActivityTime;

    final last =
        data.lastActivityTime;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF111827),
            Color(0xFF312E81),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      Colors.white.withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activity Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat(
                        'EEEE, dd MMMM yyyy',
                      ).format(
                        _selectedDate,
                      ),
                      style: const TextStyle(
                        color: Color(0xFFC7D2FE),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroMetric(
                '${data.activities.length}',
                'Activities',
              ),
              _heroMetric(
                '${data.totalVisits}',
                'Visits',
              ),
              _heroMetric(
                '${data.locationCount}',
                'Locations',
              ),
            ],
          ),
          if (first != null ||
              last != null) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color:
                    Colors.white.withOpacity(.07),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    color: Color(0xFFA5B4FC),
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _activityWindowText(
                        first,
                        last,
                      ),
                      style: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroMetric(
    String value,
    String label,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _activityWindowText(
    DateTime? first,
    DateTime? last,
  ) {
    if (first == null &&
        last == null) {
      return 'No activity recorded.';
    }

    if (first != null &&
        last != null) {
      return '${DateFormat('hh:mm a').format(first)}'
          ' — '
          '${DateFormat('hh:mm a').format(last)}';
    }

    final value = first ?? last!;

    return DateFormat(
      'hh:mm a',
    ).format(value);
  }

  Widget _buildMapSection(
    DailyHistoryData data,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Visit Route',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Recorded visit locations in chronological order',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 12),
        DailyMap(
          visits: data.visits,
          leadsByCustomerUid: _leads,
          onVisitTap: _openVisit,
        ),
        if (_loadingLeads)
          const Padding(
            padding:
                EdgeInsets.only(top: 7),
            child: Text(
              'Loading customer information…',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 9,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineSection(
    DailyHistoryData data,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Timeline',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Every visit lifecycle event recorded today',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius:
                    BorderRadius.circular(9),
              ),
              child: Text(
                '${data.activities.length}',
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (data.activities.isEmpty)
          _buildEmptyCard(
            icon: Icons.timeline_outlined,
            title: 'No activity for this day',
            subtitle:
                'Created, scheduled, started and completed visit events will appear here.',
          )
        else
          ...data.activities.map(
            (activity) {
              final lead =
                  _leads[
                    activity.visit.customerUid
                  ];

              return TimelineEventCard(
                activity: activity,
                lead: lead,
                onTap: () {
                  _openVisit(
                    activity.visit,
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildOutcomeSection(
    DailyHistoryData data,
  ) {
    final outcomes = <_OutcomeItem>[
      _OutcomeItem(
        'Interested',
        data.interested,
        Icons.thumb_up_alt_outlined,
      ),
      _OutcomeItem(
        'Not Interested',
        data.notInterested,
        Icons.thumb_down_alt_outlined,
      ),
      _OutcomeItem(
        'Follow-up Required',
        data.followUpRequired,
        Icons.schedule_outlined,
      ),
      _OutcomeItem(
        'Demo Requested',
        data.demoRequested,
        Icons.slideshow_outlined,
      ),
      _OutcomeItem(
        'Proposal Requested',
        data.proposalRequested,
        Icons.description_outlined,
      ),
      _OutcomeItem(
        'Converted',
        data.converted,
        Icons.verified_outlined,
      ),
      _OutcomeItem(
        'No Response',
        data.noResponse,
        Icons.phone_missed_outlined,
      ),
      _OutcomeItem(
        'Not Available',
        data.notAvailable,
        Icons.person_off_outlined,
      ),
      _OutcomeItem(
        'Other',
        data.other,
        Icons.more_horiz_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Visit Outcomes',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Customer response from completed visits',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(19),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: outcomes.map(
              (item) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color:
                            const Color(0xFF6366F1),
                        size: 17,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.label,
                          style:
                              const TextStyle(
                            color:
                                Color(0xFF4B5563),
                            fontSize: 10.5,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${item.value}',
                        style:
                            const TextStyle(
                          color:
                              Color(0xFF111827),
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayMetrics(
    DailyHistoryData data,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Day Details',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          _detailRow(
            Icons.add_location_alt_outlined,
            'Created',
            '${data.totalCreated}',
          ),
          _detailRow(
            Icons.event_available_outlined,
            'Scheduled',
            '${data.totalScheduled}',
          ),
          _detailRow(
            Icons.play_circle_outline,
            'Started',
            '${data.totalStarted}',
          ),
          _detailRow(
            Icons.check_circle_outline,
            'Completed',
            '${data.totalCompleted}',
          ),
          _detailRow(
            Icons.cancel_outlined,
            'Cancelled',
            '${data.totalCancelled}',
          ),
          _detailRow(
            Icons.event_busy_outlined,
            'Missed',
            '${data.totalMissed}',
          ),
          _detailRow(
            Icons.location_on_outlined,
            'GPS locations',
            '${data.locationCount}',
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF9CA3AF),
            size: 34,
          ),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 9.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 30,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load daily history',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 17,
              ),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF111827),
                foregroundColor: Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeItem {
  final String label;
  final int value;
  final IconData icon;

  const _OutcomeItem(
    this.label,
    this.value,
    this.icon,
  );
}