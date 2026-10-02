import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/lead.dart';
import '../../models/visit.dart';
import 'services/visit_service.dart';

/// Full visit details screen.
///
/// Displays the complete visit lifecycle including:
/// - Added time
/// - Scheduled time
/// - Started time
/// - Completed time
/// - Cancelled time
/// - Missed time
/// - Last updated time
/// - Visit duration
/// - Customer / lead details
/// - Location
/// - Purpose
/// - Outcome
/// - Completion notes
/// - Next follow-up
/// - Visit photos
///
/// The screen also keeps the existing VisitService actions so the visit can
/// be started, completed or cancelled without going back to the list.
class VisitDetailsScreen extends StatefulWidget {
  final Visit visit;
  final Lead? lead;
  final VisitService service;

  const VisitDetailsScreen({
    super.key,
    required this.visit,
    this.lead,
    required this.service,
  });

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  late Visit _visit;
  Lead? _lead;

  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _visit = widget.visit;
    _lead = widget.lead;
    _loadLatestVisit(loadLead: _lead == null);
  }

  Future<void> _loadLatestVisit({bool loadLead = false}) async {
    if (!mounted) return;

    try {
      final latest = await widget.service.getVisit(_visit.visitId);

      Lead? lead = _lead;
      if (loadLead && latest != null && latest.customerUid.isNotEmpty) {
        final leadSnapshot = await widget.service.findLeadByCustomerUid(
          latest.customerUid,
        );
        if (leadSnapshot != null) {
          lead = Lead.fromMap(
            leadSnapshot.id,
            Map<String, dynamic>.from(leadSnapshot.data()),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        if (latest != null) {
          _visit = latest;
        }
        if (lead != null) {
          _lead = lead;
        }
      });
    } catch (_) {
      // The initial Visit object is still valid, so the screen can render
      // even if a background refresh fails.
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      final latest = await widget.service.getVisit(_visit.visitId);

      Lead? lead = _lead;
      if (latest != null && latest.customerUid.isNotEmpty) {
        final leadSnapshot = await widget.service.findLeadByCustomerUid(
          latest.customerUid,
        );
        if (leadSnapshot != null) {
          lead = Lead.fromMap(
            leadSnapshot.id,
            Map<String, dynamic>.from(leadSnapshot.data()),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        if (latest != null) {
          _visit = latest;
        }
        if (lead != null) {
          _lead = lead;
        }
      });
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to refresh visit details.');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF111827),
          ),
        ),
        title: const Text(
          'Visit Details',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refresh,
            tooltip: 'Refresh',
            icon: _isRefreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF374151),
                  ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF4F46E5),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 14),
            _buildLifecycleCard(),
            const SizedBox(height: 14),
            _buildCustomerCard(),
            const SizedBox(height: 14),
            _buildVisitInfoCard(),
            const SizedBox(height: 14),
            _buildTimingSummaryCard(),
            const SizedBox(height: 14),
            _buildRecordAuditCard(),
            const SizedBox(height: 14),
            _buildLocationCard(),
            if (_visit.photos.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildPhotosCard(),
            ],
            if ((_visit.outcome != null) ||
                (_visit.notes ?? '').trim().isNotEmpty ||
                _visit.nextFollowUpAt != null) ...[
              const SizedBox(height: 14),
              _buildOutcomeCard(),
            ],
            const SizedBox(height: 18),
            _buildActions(),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Visit ID: ${_visit.visitId}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final businessName = (_lead?.businessName ?? '').trim();
    final contactPerson = (_lead?.contactPerson ?? '').trim();
    final category = (_lead?.category ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF312E81),
            Color(0xFF4F46E5),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.13),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withOpacity(.14),
                  ),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName.isEmpty ? 'Customer Visit' : businessName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (contactPerson.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        contactPerson,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.76),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(_visit.status, dark: true),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroPill(
                icon: _visitTypeIcon(_visit.visitType),
                label: _visitTypeLabel(_visit.visitType),
              ),
              if (category.isNotEmpty)
                _heroPill(
                  icon: Icons.category_outlined,
                  label: category,
                ),
            ],
          ),
          if ((_visit.purpose ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.09),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    color: Colors.white,
                    size: 17,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      (_visit.purpose ?? '').trim(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(.92),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
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

  Widget _buildLifecycleCard() {
    final events = <_TimelineEvent>[
      _TimelineEvent(
        title: 'Visit Added',
        subtitle: 'Visit was created in the system',
        time: _visit.createdAt,
        icon: Icons.add_circle_outline_rounded,
        color: const Color(0xFF4F46E5),
      ),
      _TimelineEvent(
        title: 'Scheduled',
        subtitle: 'Planned visit time',
        time: _visit.scheduledAt,
        icon: Icons.event_outlined,
        color: const Color(0xFF2563EB),
      ),
      _TimelineEvent(
        title: 'Visit Started',
        subtitle: 'Executive started the visit',
        time: _visit.startedAt,
        icon: Icons.play_circle_outline_rounded,
        color: const Color(0xFFD97706),
      ),
      _TimelineEvent(
        title: 'Visit Completed',
        subtitle: _visit.outcome == null
            ? 'Completion time will appear here'
            : 'Outcome: ${_outcomeLabel(_visit.outcome!)}',
        time: _visit.completedAt,
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF059669),
      ),
      _TimelineEvent(
        title: 'Visit Cancelled',
        subtitle: 'Visit was cancelled',
        time: _visit.cancelledAt,
        icon: Icons.cancel_outlined,
        color: const Color(0xFFDC2626),
      ),
      _TimelineEvent(
        title: 'Visit Marked Missed',
        subtitle: 'Visit was marked as missed',
        time: _visit.missedAt,
        icon: Icons.event_busy_outlined,
        color: const Color(0xFFEA580C),
      ),
      _TimelineEvent(
        title: 'Last Updated',
        subtitle: 'Latest visit record change',
        time: _visit.updatedAt,
        icon: Icons.update_rounded,
        color: const Color(0xFF6B7280),
      ),
    ];

    return _sectionCard(
      title: 'Visit Timeline',
      icon: Icons.timeline_rounded,
      child: Column(
        children: [
          for (int i = 0; i < events.length; i++)
            _buildTimelineEvent(
              event: events[i],
              isLast: i == events.length - 1,
            ),
          if (_visit.startedAt != null && _visit.completedAt != null) ...[
            const SizedBox(height: 8),
            _buildDurationBanner(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineEvent({
    required _TimelineEvent event,
    required bool isLast,
  }) {
    final hasTime = event.time != null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: event.color.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    event.icon,
                    color: event.color,
                    size: 17,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          event.subtitle,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 10.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (hasTime)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(event.time!),
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateShort(event.time!),
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      '—',
                      style: TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationBanner() {
    final started = _visit.startedAt!;
    final completed = _visit.completedAt!;
    final duration = completed.difference(started);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: Color(0xFF059669),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actual Visit Duration',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Time between start and completion',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDuration(duration),
            style: const TextStyle(
              color: Color(0xFF047857),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    final phone = (_lead?.phone ?? '').trim();
    final email = (_lead?.email ?? '').trim();
    final category = (_lead?.category ?? '').trim();
    final contact = (_lead?.contactPerson ?? '').trim();

    return _sectionCard(
      title: 'Customer',
      icon: Icons.business_outlined,
      child: Column(
        children: [
          _infoRow(
            Icons.business_rounded,
            'Business',
            (_lead?.businessName ?? '').trim().isEmpty
                ? 'Customer'
                : _lead!.businessName,
          ),
          if (contact.isNotEmpty)
            _infoRow(Icons.person_outline_rounded, 'Contact Person', contact),
          if (phone.isNotEmpty) _infoRow(Icons.phone_outlined, 'Phone', phone),
          if (email.isNotEmpty) _infoRow(Icons.email_outlined, 'Email', email),
          if (category.isNotEmpty)
            _infoRow(Icons.category_outlined, 'Category', category),
          _infoRow(
            Icons.fingerprint_rounded,
            'Customer ID',
            _visit.customerUid,
            mono: true,
          ),
          if ((_visit.leadId ?? '').isNotEmpty)
            _infoRow(
              Icons.description_outlined,
              'Lead ID',
              _visit.leadId!,
              mono: true,
            ),
        ],
      ),
    );
  }

  Widget _buildVisitInfoCard() {
    return _sectionCard(
      title: 'Visit Information',
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          _infoRow(
            _visitTypeIcon(_visit.visitType),
            'Visit Type',
            _visitTypeLabel(_visit.visitType),
          ),
          _infoRow(
            Icons.info_outline_rounded,
            'Status',
            _statusData(_visit.status).label,
          ),
          _infoRow(
            Icons.event_outlined,
            'Scheduled For',
            _visit.scheduledAt == null
                ? 'Not scheduled'
                : '${_formatDate(_visit.scheduledAt!)} • ${_formatTime(_visit.scheduledAt!)}',
          ),
          if (_visit.startedAt != null)
            _infoRow(
              Icons.play_circle_outline_rounded,
              'Started At',
              '${_formatDate(_visit.startedAt!)} • ${_formatTime(_visit.startedAt!)}',
            ),
          if (_visit.completedAt != null)
            _infoRow(
              Icons.check_circle_outline_rounded,
              'Completed At',
              '${_formatDate(_visit.completedAt!)} • ${_formatTime(_visit.completedAt!)}',
            ),
          if (_visit.cancelledAt != null)
            _infoRow(
              Icons.cancel_outlined,
              'Cancelled At',
              '${_formatDate(_visit.cancelledAt!)} • ${_formatTime(_visit.cancelledAt!)}',
            ),
          if (_visit.missedAt != null)
            _infoRow(
              Icons.event_busy_outlined,
              'Missed At',
              '${_formatDate(_visit.missedAt!)} • ${_formatTime(_visit.missedAt!)}',
            ),
          _infoRow(
            Icons.add_circle_outline_rounded,
            'Added At',
            _visit.createdAt == null
                ? 'Not available'
                : '${_formatDate(_visit.createdAt!)} • ${_formatTime(_visit.createdAt!)}',
          ),
          _infoRow(
            Icons.update_rounded,
            'Last Updated',
            _visit.updatedAt == null
                ? 'Not available'
                : '${_formatDate(_visit.updatedAt!)} • ${_formatTime(_visit.updatedAt!)}',
          ),
          if ((_visit.purpose ?? '').trim().isNotEmpty)
            _infoRow(
              Icons.flag_outlined,
              'Purpose',
              (_visit.purpose ?? '').trim(),
            ),
        ],
      ),
    );
  }

  Widget _buildTimingSummaryCard() {
    final scheduled = _visit.scheduledAt;
    final started = _visit.startedAt;
    final completed = _visit.completedAt;

    Duration? actualDuration;
    Duration? startDelay;
    Duration? completionFromSchedule;

    if (started != null && completed != null) {
      actualDuration = completed.difference(started);
    }

    if (scheduled != null && started != null) {
      startDelay = started.difference(scheduled);
    }

    if (scheduled != null && completed != null) {
      completionFromSchedule = completed.difference(scheduled);
    }

    return _sectionCard(
      title: 'Timing Summary',
      icon: Icons.timer_outlined,
      child: Column(
        children: [
          _timingRow(icon: Icons.event_outlined, label: 'Scheduled Time', value: _fullDateTime(scheduled), color: const Color(0xFF2563EB)),
          _timingRow(icon: Icons.play_circle_outline_rounded, label: 'Actual Start', value: _fullDateTime(started), color: const Color(0xFFD97706)),
          _timingRow(icon: Icons.check_circle_outline_rounded, label: 'Actual Completion', value: _fullDateTime(completed), color: const Color(0xFF059669)),
          _timingRow(icon: Icons.timer_rounded, label: 'Actual Visit Duration', value: actualDuration == null ? 'Not available' : _formatDurationLong(actualDuration), color: const Color(0xFF7C3AED)),
          if (_visit.cancelledAt != null)
            _timingRow(
              icon: Icons.cancel_outlined,
              label: 'Cancelled At',
              value: _fullDateTime(_visit.cancelledAt),
              color: const Color(0xFFDC2626),
            ),
          if (_visit.missedAt != null)
            _timingRow(
              icon: Icons.event_busy_outlined,
              label: 'Marked Missed At',
              value: _fullDateTime(_visit.missedAt),
              color: const Color(0xFFEA580C),
            ),
          if (startDelay != null)
            _timingRow(icon: startDelay.isNegative ? Icons.fast_forward_rounded : Icons.schedule_rounded, label: startDelay.isNegative ? 'Started Early' : 'Start Delay', value: _formatSignedDuration(startDelay), color: startDelay.isNegative ? const Color(0xFF059669) : const Color(0xFFD97706)),
          if (completionFromSchedule != null)
            _timingRow(icon: Icons.compare_arrows_rounded, label: completionFromSchedule.isNegative ? 'Completed Before Schedule' : 'Time From Schedule', value: _formatSignedDuration(completionFromSchedule), color: const Color(0xFF4F46E5)),
        ],
      ),
    );
  }

  Widget _timingRow({required IconData icon, required String label, required String value, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(.09), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10.5, fontWeight: FontWeight.w600))),
          const SizedBox(width: 10),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF111827), fontSize: 11, height: 1.35, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Widget _buildRecordAuditCard() {
    return _sectionCard(
      title: 'Record & Assignment',
      icon: Icons.manage_accounts_outlined,
      child: Column(
        children: [
          _infoRow(Icons.add_circle_outline_rounded, 'Created At', _fullDateTime(_visit.createdAt)),
          _infoRow(Icons.update_rounded, 'Updated At', _fullDateTime(_visit.updatedAt)),
          _infoRow(Icons.person_add_alt_1_outlined, 'Created By', _visit.createdBy.isEmpty ? 'Not available' : _visit.createdBy, mono: true),
          _infoRow(Icons.assignment_ind_outlined, 'Assigned To', _visit.assignedTo.isEmpty ? 'Not available' : _visit.assignedTo, mono: true),
          _infoRow(Icons.fingerprint_rounded, 'Visit ID', _visit.visitId, mono: true),
          if (_visit.leadCreated) _infoRow(Icons.link_rounded, 'Lead Linked', 'Yes'),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final address = (_visit.address ?? '').trim();
    final area = (_visit.area ?? '').trim();
    final city = (_visit.city ?? '').trim();
    final placeId = (_visit.placeId ?? '').trim();

    final locationParts = <String>[];
    if (address.isNotEmpty) locationParts.add(address);
    if (area.isNotEmpty && !locationParts.contains(area)) {
      locationParts.add(area);
    }
    if (city.isNotEmpty && !locationParts.contains(city)) {
      locationParts.add(city);
    }

    final locationText = locationParts.isEmpty
        ? (_lead?.address ?? '').trim()
        : locationParts.join(', ');

    final hasCoordinates = _visit.latitude != null && _visit.longitude != null;

    return _sectionCard(
      title: 'Visit Location',
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (locationText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    color: Color(0xFF4F46E5),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      locationText,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (hasCoordinates) ...[
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: _smallMeta(
                    'Latitude',
                    _visit.latitude!.toStringAsFixed(6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _smallMeta(
                    'Longitude',
                    _visit.longitude!.toStringAsFixed(6),
                  ),
                ),
              ],
            ),
          ],
          if (placeId.isNotEmpty) ...[
            const SizedBox(height: 10),
            _smallMeta('Google Place ID', placeId, mono: true),
          ],
          if ((_visit.mapsUrl ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.map_outlined,
                    color: Color(0xFF4F46E5),
                    size: 17,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Google Maps location is attached to this visit.',
                      style: TextStyle(
                        color: Color(0xFF3730A3),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
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

  Widget _buildPhotosCard() {
    return _sectionCard(
      title: 'Visit Photos',
      icon: Icons.photo_library_outlined,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _visit.photos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: .92,
        ),
        itemBuilder: (context, index) {
          final url = _visit.photos[index];

          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onTap: () => _openPhoto(index),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, _) => Container(
                  color: const Color(0xFFF3F4F6),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, _, __) => Container(
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOutcomeCard() {
    final notes = (_visit.notes ?? '').trim();

    return _sectionCard(
      title: 'Outcome & Notes',
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_visit.outcome != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF059669),
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _outcomeLabel(_visit.outcome!),
                    style: const TextStyle(
                      color: Color(0xFF047857),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Completion Notes',
              style: TextStyle(
                color: Color(0xFF374151),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                notes,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (_visit.nextFollowUpAt != null) ...[
            const SizedBox(height: 12),
            _infoRow(
              Icons.event_repeat_outlined,
              'Next Follow-up',
              '${_formatDate(_visit.nextFollowUpAt!)} • ${_formatTime(_visit.nextFollowUpAt!)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    final status = _visit.status;

    if (_isLoading) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: SizedBox(
            width: 21,
            height: 21,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    if (status == VisitStatus.planned) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _startVisit,
              icon: const Icon(Icons.play_arrow_rounded, size: 21),
              label: const Text('Start Visit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          _secondaryAction(
            icon: Icons.cancel_outlined,
            label: 'Cancel Visit',
            onTap: _cancelVisit,
            danger: true,
          ),
        ],
      );
    }

    if (status == VisitStatus.inProgress) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _completeVisit,
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text('Complete Visit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          _secondaryAction(
            icon: Icons.cancel_outlined,
            label: 'Cancel Visit',
            onTap: _cancelVisit,
            danger: true,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _secondaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 19,
          color: danger ? const Color(0xFFDC2626) : const Color(0xFF374151),
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              danger ? const Color(0xFFB91C1C) : const Color(0xFF374151),
          side: BorderSide(
            color: danger ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4F46E5),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool mono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 27,
            child: Icon(
              icon,
              size: 17,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: const Color(0xFF374151),
                fontSize: mono ? 9.5 : 11.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallMeta(String label, String value, {bool mono = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF374151),
              fontSize: mono ? 8.5 : 10,
              height: 1.3,
              fontWeight: FontWeight.w700,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.11),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(VisitStatus status, {bool dark = false}) {
    final data = _statusData(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(.13) : data.background,
        borderRadius: BorderRadius.circular(100),
        border: dark
            ? Border.all(color: Colors.white.withOpacity(.13))
            : Border.all(color: data.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data.icon,
            size: 12,
            color: dark ? Colors.white : data.foreground,
          ),
          const SizedBox(width: 5),
          Text(
            data.label,
            style: TextStyle(
              color: dark ? Colors.white : data.foreground,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startVisit() async {
    final confirmed = await _confirmAction(
      title: 'Start this visit?',
      message: 'The current time will be saved as the visit start time.',
      confirmLabel: 'Start Visit',
      icon: Icons.play_arrow_rounded,
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await widget.service.startVisit(_visit.visitId);
      await _loadLatestVisit();
      if (mounted) {
        _showSuccess('Visit started successfully.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to start the visit. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeVisit() async {
    final outcome = await _selectOutcome();
    if (outcome == null) return;

    final notes = await _showCompletionNotesDialog();
    if (notes == null) return;

    setState(() => _isLoading = true);

    try {
      await widget.service.completeVisit(
        visitId: _visit.visitId,
        outcome: outcome,
        notes: notes,
      );

      await _loadLatestVisit();
      if (mounted) {
        _showSuccess('Visit completed successfully.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to complete the visit. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelVisit() async {
    final confirmed = await _confirmAction(
      title: 'Cancel this visit?',
      message: 'This visit will be marked as cancelled.',
      confirmLabel: 'Cancel Visit',
      icon: Icons.cancel_outlined,
      danger: true,
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await widget.service.cancelVisit(_visit.visitId);
      await _loadLatestVisit();
      if (mounted) {
        _showSuccess('Visit cancelled.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to cancel the visit. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: danger
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: danger
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF4F46E5),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Not Now',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    danger ? const Color(0xFFDC2626) : const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                confirmLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<VisitOutcome?> _selectOutcome() async {
    return showModalBottomSheet<VisitOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * .78;

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Visit Outcome',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose what happened during the visit.',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Expanded(
                  child: ListView.separated(
                    itemCount: VisitOutcome.values.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final outcome = VisitOutcome.values[index];

                      return Material(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          onTap: () => Navigator.pop(sheetContext, outcome),
                          borderRadius: BorderRadius.circular(15),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons.flag_outlined,
                                    color: Color(0xFF4F46E5),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    _outcomeLabel(outcome),
                                    style: const TextStyle(
                                      color: Color(0xFF111827),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF9CA3AF),
                                  size: 19,
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

  Future<String?> _showCompletionNotesDialog() async {
    final controller = TextEditingController();
    String? errorText;

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottom = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Visit Completion Notes',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Add a short summary of what happened during the visit.',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        minLines: 4,
                        maxLines: 7,
                        maxLength: 1000,
                        textInputAction: TextInputAction.newline,
                        onChanged: (_) {
                          if (errorText != null) {
                            setModalState(() => errorText = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Notes *',
                          hintText: 'What happened during the visit?',
                          alignLabelWithHint: true,
                          errorText: errorText,
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          counterStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 9,
                          ),
                          labelStyle: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF4F46E5),
                              width: 1.3,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 1.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '* Notes are required to complete the visit.',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 51,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final notes = controller.text.trim();

                            if (notes.isEmpty) {
                              setModalState(
                                () => errorText = 'Please enter visit notes.',
                              );
                              return;
                            }

                            Navigator.pop(sheetContext, notes);
                          },
                          icon: const Icon(Icons.check_rounded, size: 19),
                          label: const Text('Continue & Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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

  void _openPhoto(int index) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(.88),
      builder: (_) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            minScale: .8,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: _visit.photos[index],
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
        );
      },
    );
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

  String _formatDateShort(DateTime date) {
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _fullDateTime(DateTime? date) {
    if (date == null) return 'Not recorded';
    return '${_formatDate(date)} • ${_formatTime(date)}';
  }

  String _formatDurationLong(Duration duration) {
    if (duration.isNegative) return '—';
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (days == 0 && hours == 0 && seconds > 0) parts.add('${seconds}s');
    return parts.isEmpty ? '0s' : parts.join(' ');
  }

  String _formatSignedDuration(Duration duration) {
    final negative = duration.isNegative;
    final absolute = duration.abs();
    final text = _formatDurationLong(absolute);
    return negative ? '$text early' : '$text after';
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '—';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }

    return '${seconds}s';
  }

  String _visitTypeLabel(VisitType type) {
    switch (type) {
      case VisitType.selfAdded:
        return 'Self Added';
      case VisitType.scheduled:
        return 'Scheduled';
    }
  }

  IconData _visitTypeIcon(VisitType type) {
    switch (type) {
      case VisitType.selfAdded:
        return Icons.my_location_rounded;
      case VisitType.scheduled:
        return Icons.event_available_rounded;
    }
  }

  String _outcomeLabel(VisitOutcome outcome) {
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

  _StatusData _statusData(VisitStatus status) {
    switch (status) {
      case VisitStatus.planned:
        return const _StatusData(
          label: 'Planned',
          foreground: Color(0xFF4F46E5),
          background: Color(0xFFEEF2FF),
          border: Color(0xFFE0E7FF),
          icon: Icons.schedule_outlined,
        );
      case VisitStatus.inProgress:
        return const _StatusData(
          label: 'In Progress',
          foreground: Color(0xFFD97706),
          background: Color(0xFFFFFBEB),
          border: Color(0xFFFDE68A),
          icon: Icons.play_circle_outline_rounded,
        );
      case VisitStatus.completed:
        return const _StatusData(
          label: 'Completed',
          foreground: Color(0xFF047857),
          background: Color(0xFFECFDF5),
          border: Color(0xFFD1FAE5),
          icon: Icons.check_circle_outline_rounded,
        );
      case VisitStatus.cancelled:
        return const _StatusData(
          label: 'Cancelled',
          foreground: Color(0xFFB91C1C),
          background: Color(0xFFFEF2F2),
          border: Color(0xFFFECACA),
          icon: Icons.cancel_outlined,
        );
      case VisitStatus.missed:
        return const _StatusData(
          label: 'Missed',
          foreground: Color(0xFF7C3AED),
          background: Color(0xFFF5F3FF),
          border: Color(0xFFE9D5FF),
          icon: Icons.event_busy_outlined,
        );
    }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
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
          backgroundColor: const Color(0xFF111827),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
}

class _TimelineEvent {
  final String title;
  final String subtitle;
  final DateTime? time;
  final IconData icon;
  final Color color;

  const _TimelineEvent({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class _StatusData {
  final String label;
  final Color foreground;
  final Color background;
  final Color border;
  final IconData icon;

  const _StatusData({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
    required this.icon,
  });
}
