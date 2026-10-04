import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/lead.dart';
import '../../../models/visit.dart';

class DailyMap extends StatefulWidget {
  final List<Visit> visits;
  final Map<String, Lead> leadsByCustomerUid;
  final ValueChanged<Visit>? onVisitTap;

  const DailyMap({
    super.key,
    required this.visits,
    required this.leadsByCustomerUid,
    this.onVisitTap,
  });

  @override
  State<DailyMap> createState() => _DailyMapState();
}

class _DailyMapState extends State<DailyMap> {
  GoogleMapController? _controller;

  static const LatLng _fallback =
      LatLng(18.5204, 73.8567);

  List<Visit> get _locationVisits {
    return widget.visits.where((visit) {
      return visit.latitude != null &&
          visit.longitude != null;
    }).toList();
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};

    for (var i = 0;
        i < _locationVisits.length;
        i++) {
      final visit = _locationVisits[i];

      final lat = visit.latitude!;
      final lng = visit.longitude!;

      final lead =
          widget.leadsByCustomerUid[
              visit.customerUid];

      final business =
          lead?.businessName.trim().isNotEmpty == true
              ? lead!.businessName
              : 'Visit ${i + 1}';

      markers.add(
        Marker(
          markerId: MarkerId(
            visit.visitId,
          ),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: '${i + 1}. $business',
            snippet: visit.address ??
                '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
          ),
          onTap: () {
            _showVisitSheet(
              context,
              visit,
              i + 1,
            );
          },
        ),
      );
    }

    return markers;
  }

  Set<Polyline> get _polylines {
    if (_locationVisits.length < 2) {
      return {};
    }

    return {
      Polyline(
        polylineId:
            const PolylineId('daily_route'),
        points: _locationVisits
            .map(
              (visit) => LatLng(
                visit.latitude!,
                visit.longitude!,
              ),
            )
            .toList(),
        width: 5,
        color: const Color(0xFF4F46E5),
       patterns: <PatternItem>[
  PatternItem.dash(20),
  PatternItem.gap(10),
],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_locationVisits.isEmpty) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map_outlined,
                  color: Color(0xFF9CA3AF),
                  size: 38,
                ),
                SizedBox(height: 10),
                Text(
                  'No recorded visit locations',
                  style: TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Visits with GPS coordinates will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final first = _locationVisits.first;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(20),
      child: SizedBox(
        height: 350,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(
                target: LatLng(
                  first.latitude!,
                  first.longitude!,
                ),
                zoom: 14.5,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              onMapCreated: (controller) {
                _controller = controller;

                Future.delayed(
                  const Duration(
                    milliseconds: 300,
                  ),
                  _fitAllMarkers,
                );
              },
            ),

            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(.10),
                      blurRadius: 12,
                      offset:
                          const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      color: Color(0xFF4F46E5),
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${_locationVisits.length} locations',
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: 12,
              top: 12,
              child: Material(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(12),
                  onTap: _fitAllMarkers,
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.fit_screen_rounded,
                      color: Color(0xFF374151),
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fitAllMarkers() async {
    final controller = _controller;

    if (controller == null ||
        _locationVisits.isEmpty) {
      return;
    }

    if (_locationVisits.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            _locationVisits.first.latitude!,
            _locationVisits.first.longitude!,
          ),
          16,
        ),
      );
      return;
    }

    double minLat =
        _locationVisits.first.latitude!;
    double maxLat = minLat;
    double minLng =
        _locationVisits.first.longitude!;
    double maxLng = minLng;

    for (final visit in _locationVisits) {
      final lat = visit.latitude!;
      final lng = visit.longitude!;

      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        minLat,
        minLng,
      ),
      northeast: LatLng(
        maxLat,
        maxLng,
      ),
    );

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        70,
      ),
    );
  }

  void _showVisitSheet(
    BuildContext context,
    Visit visit,
    int number,
  ) {
    final lead =
        widget.leadsByCustomerUid[
            visit.customerUid];

    final business =
        lead?.businessName.trim().isNotEmpty == true
            ? lead!.businessName
            : 'Visit $number';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFD1D5DB),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  business,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                if ((lead?.contactPerson ?? '')
                    .trim()
                    .isNotEmpty)
                  Text(
                    lead!.contactPerson,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 14),
                _infoRow(
                  Icons.location_on_outlined,
                  visit.address ??
                      'Recorded GPS location',
                ),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.gps_fixed_rounded,
                  '${visit.latitude!.toStringAsFixed(6)}, '
                  '${visit.longitude!.toStringAsFixed(6)}',
                ),
                if (visit.outcome != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.check_circle_outline,
                    _outcomeLabel(
                      visit.outcome!,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );

                          widget.onVisitTap
                              ?.call(visit);
                        },
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 17,
                        ),
                        label: const Text(
                          'View Visit',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _openMaps(visit);
                        },
                        icon: const Icon(
                          Icons.map_outlined,
                          size: 17,
                        ),
                        label: const Text(
                          'Open Maps',
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(
                            0xFF111827,
                          ),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6366F1),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
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

  Future<void> _openMaps(
    Visit visit,
  ) async {
    final latitude = visit.latitude;
    final longitude = visit.longitude;

    if (latitude == null ||
        longitude == null) {
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/'
      '?api=1&query=$latitude,$longitude',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}