import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/attendance_record.dart';
import '../models/attendance_break.dart';
import '../services/attendance_service.dart';
import 'attendance_history_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4F46E5);
  static const Color _background = Color(0xFFF7F8FC);
  static const Color _text = Color(0xFF171923);
  static const Color _muted = Color(0xFF73778A);
  static const Color _border = Color(0xFFE7E9F2);
  static const Color _green = Color(0xFF10B981);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);

  final AttendanceService _attendanceService = AttendanceService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  AttendanceRecord? _attendance;
  File? _selectedPhoto;
  List<AttendanceBreak> _breaks = <AttendanceBreak>[];
  AttendanceBreak? _activeBreak;

  bool _loading = true;
  bool _gettingLocation = false;
  bool _saving = false;

  double? _distanceMeters;
  double? _accuracyMeters;
  bool? _insideOffice;
  String? _locationMessage;
  String? _officeName;
  double? _officeRadiusMeters;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _openHistory() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AttendanceHistoryScreen(),
      ),
    );
  }

  Future<void> _loadToday() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final attendance = await _attendanceService.getTodayAttendance();

      if (!mounted) return;

      final breaks = await _attendanceService.getTodayBreaks();

      if (!mounted) return;

      setState(() {
        _attendance = attendance;
        _breaks = breaks;
        _activeBreak = _findActiveBreak(breaks);
      });

      await _refreshLocation(showMessages: false);
    } catch (e) {
      if (!mounted) return;
      _showError(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshLocation({
    bool showMessages = true,
  }) async {
    if (_gettingLocation || _saving) return;

    setState(() {
      _gettingLocation = true;
      _locationMessage = null;
    });

    try {
      final result = await _attendanceService.validateOfficeDistance(
        position: await _attendanceService.getCurrentPosition(),
      );

      if (!mounted) return;

      setState(() {
        _distanceMeters = result.distanceMeters;
        _accuracyMeters = result.position.accuracy;
        _insideOffice = result.allowed;
        _officeName = result.office.name;
        _officeRadiusMeters = result.office.radiusMeters;
      });

      if (showMessages) {
        if (result.allowed) {
          _showSuccess(
            'You are ${_formatDistance(result.distanceMeters)} '
            'from $_officeName.',
          );
        } else {
          _showError(
            'You are ${_formatDistance(result.distanceMeters)} '
            'from the office. You must be within '
            '${result.office.radiusMeters.toStringAsFixed(0)}m.',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _insideOffice = null;
        _distanceMeters = null;
        _accuracyMeters = null;
      });

      if (showMessages) {
        _showError(_friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_saving) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (image == null) return;

      if (!mounted) return;

      setState(() {
        _selectedPhoto = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Unable to open the camera. Please try again.');
    }
  }

  Future<void> _chooseGalleryPhoto() async {
    if (_saving) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (image == null) return;

      if (!mounted) return;

      setState(() {
        _selectedPhoto = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Unable to select the photo.');
    }
  }

  Future<void> _capturePhotoForAttendance() async {
    if (_saving) return;

    if (_insideOffice != true) {
      await _refreshLocation();

      if (_insideOffice != true) {
        return;
      }
    }

    await _takePhoto();
  }

  Future<void> _submitAttendance() async {
    if (_saving) return;

    if (_activeBreak != null) {
      _showError(
        'Please end your ${_activeBreak!.displayLabel.toLowerCase()} before checking out.',
      );
      return;
    }

    final attendance = _attendance;
    final isCheckIn = attendance == null || !attendance.isCheckedIn;
    final isCheckOut =
        attendance != null &&
        attendance.isCheckedIn &&
        !attendance.isCheckedOut;

    if (!isCheckIn && !isCheckOut) {
      _showError('Today\'s attendance is already completed.');
      return;
    }

    if (_insideOffice != true) {
      await _refreshLocation();

      if (_insideOffice != true) {
        return;
      }
    }

    if (_selectedPhoto == null) {
      _showError(
        isCheckIn
            ? 'Please take your check-in photo first.'
            : 'Please take your check-out photo first.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      AttendanceRecord saved;

      if (isCheckIn) {
        saved = await _attendanceService.checkIn(
          photoFile: _selectedPhoto!,
        );
      } else {
        saved = await _attendanceService.checkOut(
          photoFile: _selectedPhoto!,
        );
      }

      if (!mounted) return;

      setState(() {
        _attendance = saved;
        _selectedPhoto = null;
      });

      await _refreshLocation(showMessages: false);

      if (!mounted) return;

      _showSuccess(
        isCheckIn
            ? 'Check-in recorded successfully.'
            : 'Check-out recorded successfully.',
      );
    } catch (e) {
      if (!mounted) return;
      _showError(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }


  AttendanceBreak? _findActiveBreak(List<AttendanceBreak> breaks) {
    for (final item in breaks) {
      if (item.isActive) return item;
    }
    return null;
  }

  bool get _canStartBreak {
    return _attendance?.isCheckedIn == true &&
        _attendance?.isCheckedOut != true &&
        !_saving;
  }

  Future<void> _reloadBreaks() async {
    try {
      final breaks = await _attendanceService.getTodayBreaks();
      if (!mounted) return;
      setState(() {
        _breaks = breaks;
        _activeBreak = _findActiveBreak(breaks);
      });
    } catch (e) {
      if (!mounted) return;
      _showError(_friendlyError(e));
    }
  }

  Future<void> _openBreakPicker() async {
    if (!_canStartBreak) {
      _showError('You must be checked in and not checked out to start a break.');
      return;
    }

    AttendanceBreakType selected = AttendanceBreakType.lunch;
    final customController = TextEditingController();
    final noteController = TextEditingController();

    final shouldStart = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isOther = selected == AttendanceBreakType.other;

            return SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Start a Break',
                        style: TextStyle(
                          color: _text,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Choose the type of break you are taking.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: AttendanceBreakType.values.map((type) {
                          final active = selected == type;
                          return InkWell(
                            onTap: () {
                              setSheetState(() => selected = type);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? _primary.withOpacity(.10)
                                    : _background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active ? _primary : _border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _breakIcon(type),
                                    size: 17,
                                    color: active ? _primary : _muted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    type.label,
                                    style: TextStyle(
                                      color: active ? _primary : _text,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (isOther) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: customController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Break name',
                            hintText: 'e.g. Client call break',
                            filled: true,
                            fillColor: _background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Note (optional)',
                          hintText: 'Add a short note',
                          filled: true,
                          fillColor: _background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (isOther &&
                                customController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter a name for this break.'),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(sheetContext, true);
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text(
                            'START BREAK',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: .5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
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

    if (shouldStart != true) {
      customController.dispose();
      noteController.dispose();
      return;
    }

    try {
      setState(() => _saving = true);
      final started = await _attendanceService.startBreak(
        type: selected,
        customLabel: selected == AttendanceBreakType.other
            ? customController.text.trim()
            : null,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _breaks = [started, ..._breaks];
        _activeBreak = started;
      });

      _showSuccess('${started.displayLabel} started.');
    } catch (e) {
      if (mounted) {
        _showError(_friendlyError(e));
      }
    } finally {
      customController.dispose();
      noteController.dispose();
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _endBreak() async {
    final active = _activeBreak;
    if (active == null || _saving) return;

    setState(() => _saving = true);

    try {
      final ended = await _attendanceService.endBreak(active.breakId);
      if (!mounted) return;

      setState(() {
        _breaks = _breaks
            .map((item) => item.breakId == ended.breakId ? ended : item)
            .toList();
        _activeBreak = null;
      });

      _showSuccess(
        '${ended.displayLabel} ended • ${ended.durationLabel}.',
      );
    } catch (e) {
      if (mounted) {
        _showError(_friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  IconData _breakIcon(AttendanceBreakType type) {
    switch (type) {
      case AttendanceBreakType.lunch:
        return Icons.restaurant_rounded;
      case AttendanceBreakType.tea:
        return Icons.emoji_food_beverage_rounded;
      case AttendanceBreakType.coffee:
        return Icons.coffee_rounded;
      case AttendanceBreakType.shortBreak:
        return Icons.free_breakfast_rounded;
      case AttendanceBreakType.personal:
        return Icons.person_outline_rounded;
      case AttendanceBreakType.prayer:
        return Icons.self_improvement_rounded;
      case AttendanceBreakType.meeting:
        return Icons.groups_rounded;
      case AttendanceBreakType.medical:
        return Icons.medical_services_outlined;
      case AttendanceBreakType.other:
        return Icons.more_horiz_rounded;
    }
  }

  Color _breakColor(AttendanceBreakType type) {
    switch (type) {
      case AttendanceBreakType.lunch:
        return const Color(0xFF10B981);
      case AttendanceBreakType.tea:
        return const Color(0xFFF59E0B);
      case AttendanceBreakType.coffee:
        return const Color(0xFF92400E);
      case AttendanceBreakType.shortBreak:
        return const Color(0xFF6366F1);
      case AttendanceBreakType.personal:
        return const Color(0xFF8B5CF6);
      case AttendanceBreakType.prayer:
        return const Color(0xFF0EA5E9);
      case AttendanceBreakType.meeting:
        return const Color(0xFF2563EB);
      case AttendanceBreakType.medical:
        return const Color(0xFFEF4444);
      case AttendanceBreakType.other:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildBreaksCard() {
    final active = _activeBreak;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                active == null
                    ? Icons.free_breakfast_outlined
                    : _breakIcon(active.type),
                active == null ? _orange : _breakColor(active.type),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Breaks',
                      style: TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Track lunch, tea, coffee and other breaks.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_canStartBreak && active == null)
                TextButton.icon(
                  onPressed: _saving ? null : _openBreakPicker,
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text(
                    'Break',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (active != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _orange.withOpacity(.07),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _orange.withOpacity(.16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _breakIcon(active.type),
                      color: _orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active.displayLabel,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Started ${active.startedAt == null ? '--' : DateFormat('hh:mm a').format(active.startedAt!)} • Running',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _saving ? null : _endBreak,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _orange,
                      side: BorderSide(color: _orange.withOpacity(.35)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'END',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_breaks.isEmpty)
            _emptyBreaks()
          else
            ..._breaks.take(5).map(_breakRow),
          if (_breaks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: _muted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Break time: ${_formatMinutes(_breaks.fold<int>(0, (sum, item) => sum + item.durationMinutes))}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_breaks.length} break${_breaks.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyBreaks() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.free_breakfast_outlined, color: _muted),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No breaks recorded',
                  style: TextStyle(
                    color: _text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Start a break whenever you need one.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakRow(AttendanceBreak item) {
    final color = _breakColor(item.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _breakIcon(item.type),
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayLabel,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.startedAt == null
                      ? 'Not recorded'
                      : '${DateFormat('hh:mm a').format(item.startedAt!)}'
                          '${item.endedAt == null ? ' • Running' : ' - ${DateFormat('hh:mm a').format(item.endedAt!)}'}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.durationLabel,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  bool get _canCheckIn {
    final attendance = _attendance;
    return attendance == null || !attendance.isCheckedIn;
  }

  bool get _canCheckOut {
    final attendance = _attendance;
    return attendance != null &&
        attendance.isCheckedIn &&
        !attendance.isCheckedOut &&
        _activeBreak == null;
  }

  bool get _completed {
    final attendance = _attendance;
    return attendance != null &&
        attendance.isCheckedIn &&
        attendance.isCheckedOut;
  }

  String get _primaryActionLabel {
    if (_saving) return 'Saving...';
    if (_canCheckIn) return 'CHECK IN';
    if (_activeBreak != null) return 'END BREAK TO CHECK OUT';
    if (_canCheckOut) return 'CHECK OUT';
    return 'ATTENDANCE COMPLETED';
  }

  String get _photoTitle {
    if (_canCheckIn) return 'Check-in photo';
    if (_canCheckOut) return 'Check-out photo';
    return 'Attendance photo';
  }

  String get _photoSubtitle {
    if (_canCheckIn) {
      return 'Take a live photo before checking in.';
    }

    if (_canCheckOut) {
      return 'Take a live photo before checking out.';
    }

    return 'Your attendance photos are saved with today\'s record.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: _primary,
              ),
            )
          : RefreshIndicator(
              color: _primary,
              onRefresh: _loadToday,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildLocationCard(),
                      const SizedBox(height: 16),
                      _buildBreaksCard(),
                      const SizedBox(height: 16),
                      if (!_completed) ...[
                        _buildPhotoCard(),
                        const SizedBox(height: 18),
                      ],
                      _buildTimelineCard(),
                      if (_completed) ...[
                        const SizedBox(height: 16),
                        _buildCompletedCard(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _background,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance',
            style: TextStyle(
              color: _text,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          SizedBox(height: 1),
          Text(
            'Office check-in & check-out',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Attendance history',
          onPressed: _loading || _saving ? null : _openHistory,
          icon: const Icon(
            Icons.history_rounded,
            color: _text,
            size: 21,
          ),
        ),
        IconButton(
          tooltip: 'Refresh location',
          onPressed: _loading || _gettingLocation || _saving
              ? null
              : () => _refreshLocation(),
          icon: const Icon(
            Icons.my_location_rounded,
            color: _text,
            size: 21,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(now),
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Your attendance',
          style: TextStyle(
            color: _text,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -.9,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final attendance = _attendance;

    Color color;
    IconData icon;
    String title;
    String subtitle;

    if (_completed) {
      color = _green;
      icon = Icons.verified_rounded;
      title = 'Attendance completed';
      subtitle = 'You have checked in and checked out today.';
    } else if (_activeBreak != null) {
      color = _orange;
      icon = Icons.free_breakfast_rounded;
      title = '${_activeBreak!.displayLabel} is active';
      subtitle = 'End your break before checking out.';
    } else if (_canCheckOut) {
      color = _green;
      icon = Icons.login_rounded;
      title = 'You are checked in';
      subtitle = 'You can check out when you are ready.';
    } else if (_insideOffice == false) {
      color = _red;
      icon = Icons.location_off_rounded;
      title = 'Outside office radius';
      subtitle = 'Move inside the allowed office area to check in.';
    } else if (_gettingLocation) {
      color = _orange;
      icon = Icons.gps_fixed_rounded;
      title = 'Checking your location';
      subtitle = 'Please wait while we verify your office distance.';
    } else {
      color = _primary;
      icon = Icons.access_time_filled_rounded;
      title = 'Ready to check in';
      subtitle = 'You must be within the configured office radius.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, _primaryDark, .35) ?? color,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.82),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final inside = _insideOffice == true;
    final outside = _insideOffice == false;

    final color = inside
        ? _green
        : outside
            ? _red
            : _muted;

    final icon = inside
        ? Icons.location_on_rounded
        : outside
            ? Icons.location_off_rounded
            : Icons.location_searching_rounded;

    final title = inside
        ? 'You are inside the office area'
        : outside
            ? 'Outside the office area'
            : 'Location not checked';

    final subtitle = inside
        ? '${_formatDistance(_distanceMeters)} from ${_officeName ?? 'office'}'
        : outside
            ? 'Move within ${(_officeRadiusMeters ?? 100).toStringAsFixed(0)}m to continue.'
            : 'Location is required for attendance.';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                icon,
                color,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Office location',
                      style: TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _officeName ?? 'Syteos Labs Office',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildLocationBadge(
                inside: inside,
                outside: outside,
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(.055),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(.12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_gettingLocation)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  ),
              ],
            ),
          ),
          if (_accuracyMeters != null) ...[
            const SizedBox(height: 11),
            Row(
              children: [
                const Icon(
                  Icons.gps_fixed_rounded,
                  size: 15,
                  color: _muted,
                ),
                const SizedBox(width: 6),
                Text(
                  'GPS accuracy ${_formatDistance(_accuracyMeters)}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _gettingLocation || _saving
                      ? null
                      : () => _refreshLocation(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Refresh',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationBadge({
    required bool inside,
    required bool outside,
  }) {
    final color = inside
        ? _green
        : outside
            ? _red
            : _muted;

    final label = inside
        ? 'ALLOWED'
        : outside
            ? 'BLOCKED'
            : 'CHECKING';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    final hasPhoto = _selectedPhoto != null;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.camera_alt_rounded,
                _primary,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _photoTitle,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _photoSubtitle,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPhoto)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(.08),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'READY',
                    style: TextStyle(
                      color: _green,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasPhoto)
            _buildPhotoPreview()
          else
            _buildCameraPlaceholder(),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 15,
                color: _muted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Attendance proof is saved with the recorded time and verified office location.',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return InkWell(
      onTap: _insideOffice == true
          ? _capturePhotoForAttendance
          : () => _refreshLocation(),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _primary.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: _primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _insideOffice == true
                  ? 'Take attendance photo'
                  : 'Check your office location first',
              style: const TextStyle(
                color: _text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _insideOffice == true
                  ? 'Use the camera to capture a live photo'
                  : 'You must be within 100m of the office',
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 230,
                child: Image.file(
                  _selectedPhoto!,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.black.withOpacity(.55),
                  borderRadius: BorderRadius.circular(100),
                  child: InkWell(
                    onTap: _saving ? null : _takePhoto,
                    borderRadius: BorderRadius.circular(100),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
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
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _takePhoto,
                icon: const Icon(
                  Icons.camera_alt_rounded,
                  size: 18,
                ),
                label: const Text('Retake'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _chooseGalleryPhoto,
                icon: const Icon(
                  Icons.photo_library_rounded,
                  size: 18,
                ),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final enabled = _insideOffice == true &&
        _selectedPhoto != null &&
        !_saving &&
        !_completed;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: enabled ? _submitAttendance : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          disabledBackgroundColor: _border,
          disabledForegroundColor: _muted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                _primaryActionLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    final attendance = _attendance;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today',
            style: TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
          _timelineRow(
            icon: Icons.login_rounded,
            color: _green,
            title: 'Check in',
            time: attendance?.checkInAt,
            distance: attendance?.checkInDistanceMeters,
            photoAvailable: attendance?.checkInPhotoUrl != null,
            isLast: false,
          ),
          _timelineRow(
            icon: Icons.logout_rounded,
            color: _orange,
            title: 'Check out',
            time: attendance?.checkOutAt,
            distance: attendance?.checkOutDistanceMeters,
            photoAvailable: attendance?.checkOutPhotoUrl != null,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _timelineRow({
    required IconData icon,
    required Color color,
    required String title,
    required DateTime? time,
    required double? distance,
    required bool photoAvailable,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 15,
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 43,
                  color: _border,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 18,
              top: 1,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        time == null
                            ? 'Not recorded yet'
                            : DateFormat('hh:mm a').format(time),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (time != null) ...[
                  if (photoAvailable)
                    const Padding(
                      padding: EdgeInsets.only(right: 9),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 15,
                        color: _green,
                      ),
                    ),
                  if (distance != null)
                    Text(
                      _formatDistance(distance),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedCard() {
    final attendance = _attendance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _green.withOpacity(.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _green.withOpacity(.13),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _green.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.done_all_rounded,
              color: _green,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workday completed',
                  style: TextStyle(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  attendance == null
                      ? ''
                      : 'Net working time: ${attendance.totalHoursLabel}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (attendance != null && attendance.totalBreakMinutes > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Break time: ${attendance.totalBreakLabel} • ${attendance.breakCount} break${attendance.breakCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'View history',
            onPressed: _openHistory,
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: _green,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconBox(
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '--';

    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }

    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst(
          'Bad state: ',
          '',
        );

    if (message.contains('permission')) {
      return message;
    }

    if (message.contains('permanently denied')) {
      return 'Location permission is permanently denied. '
          'Please enable location access from your phone settings.';
    }

    if (message.contains('Location services are disabled')) {
      return 'Please turn on GPS/location services and try again.';
    }

    if (message.contains('Office location is not configured')) {
      return 'Office location is not configured yet.';
    }

    if (message.contains('outside') ||
        message.contains('must be within')) {
      return message;
    }

    if (message.contains('already checked in')) {
      return 'You are already checked in for today.';
    }

    if (message.contains('already checked out')) {
      return 'You have already checked out for today.';
    }

    if (message.contains('must check in')) {
      return 'You must check in before checking out.';
    }

    return message.isEmpty
        ? 'Something went wrong. Please try again.'
        : message;
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _green,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
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
          backgroundColor: _red,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
