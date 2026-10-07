import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../services/team_service.dart';
import '../models/attendance_record.dart';
import '../models/attendance_break.dart';
import '../services/attendance_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4F46E5);
  static const Color _background = Color(0xFFF7F8FC);
  static const Color _surface = Colors.white;
  static const Color _text = Color(0xFF171923);
  static const Color _muted = Color(0xFF73778A);
  static const Color _border = Color(0xFFE7E9F2);
  static const Color _green = Color(0xFF10B981);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);
  static const Color _blue = Color(0xFF2563EB);

  final AttendanceService _attendanceService = AttendanceService.instance;
  final TeamService _teamService = TeamService.instance;

  AppUser? _currentUser;
  List<AppUser> _employees = [];
  List<AttendanceRecord> _records = [];

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedEmployeeId;
  String _search = '';

  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  bool get _isManagement {
    final role = _currentUser?.role;
    return role == UserRole.ceo ||
        role == UserRole.cto ||
        role == UserRole.admin;
  }

  DateTime get _monthStart =>
      DateTime(_selectedMonth.year, _selectedMonth.month);

  DateTime get _monthEnd =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await _teamService.getCurrentUser();

      if (!mounted) return;

      _currentUser = user;

      if (_isManagement) {
        _employees = await _teamService.watchAllEmployees().first;
      }

      await _loadHistory();

      if (!mounted) return;

      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _loadHistory({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    }

    try {
      final records = _isManagement
          ? await _attendanceService.getAttendanceHistoryForManagement(
              startDate: _monthStart,
              endDate: _monthEnd,
            )
          : await _attendanceService.getMyAttendanceHistory(
              startDate: _monthStart,
              endDate: _monthEnd,
            );

      if (!mounted) return;

      setState(() {
        _records = records;
        _refreshing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _refreshing = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _changeMonth(int delta) async {
    final next = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + delta,
    );

    setState(() => _selectedMonth = next);
    await _loadHistory();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select attendance month',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });

    await _loadHistory();
  }

  AppUser? _employeeById(String id) {
    for (final employee in _employees) {
      if (employee.id == id) return employee;
    }
    return null;
  }

  List<AttendanceRecord> get _visibleRecords {
    var records = List<AttendanceRecord>.from(_records);

    if (_isManagement && _selectedEmployeeId != null) {
      records = records
          .where((record) => record.userId == _selectedEmployeeId)
          .toList();
    }

    final query = _search.trim().toLowerCase();

    if (_isManagement && query.isNotEmpty) {
      records = records.where((record) {
        final employee = _employeeById(record.userId);
        final name = employee?.name.toLowerCase() ?? '';
        final email = employee?.email.toLowerCase() ?? '';
        return name.contains(query) ||
            email.contains(query) ||
            record.date.contains(query);
      }).toList();
    }

    records.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return (b.checkInAt ?? DateTime(2000))
          .compareTo(a.checkInAt ?? DateTime(2000));
    });

    return records;
  }

  List<DateTime> get _daysInMonth {
    final days = <DateTime>[];
    for (var day = 1; day <= _monthEnd.day; day++) {
      days.add(DateTime(_selectedMonth.year, _selectedMonth.month, day));
    }
    return days;
  }

  AttendanceRecord? _recordFor(String userId, DateTime date) {
    final key = _attendanceService.dateKey(date);

    for (final record in _records) {
      if (record.userId == userId && record.date == key) {
        return record;
      }
    }

    return null;
  }

  int get _presentCount {
    if (_isManagement && _selectedEmployeeId == null) {
      return _records.where((r) => r.checkInAt != null).length;
    }

    final userId = _selectedEmployeeId ?? _currentUser?.id;
    if (userId == null) return 0;

    return _daysInMonth
        .map((day) => _recordFor(userId, day))
        .where((record) => record?.checkInAt != null)
        .length;
  }

  int get _checkedOutCount =>
      _visibleRecords.where((r) => r.checkOutAt != null).length;

  int get _totalMinutes =>
      _visibleRecords.fold(0, (sum, record) => sum + record.totalMinutes);

  int get _totalBreakMinutes =>
      _visibleRecords.fold(0, (sum, record) => sum + record.totalBreakMinutes);

  int get _workingDays =>
      _visibleRecords.where((r) => r.checkInAt != null).length;

  String get _averageHours {
    if (_workingDays == 0) return '0h 00m';

    final minutes = (_totalMinutes / _workingDays).round();
    return _durationLabel(minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : RefreshIndicator(
              color: _primary,
              onRefresh: () => _loadHistory(),
              child: _error != null && _records.isEmpty
                  ? _buildErrorState()
                  : _buildContent(),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: _text),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance History',
            style: TextStyle(
              color: _text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            _isManagement ? 'Team attendance overview' : 'Your attendance',
            style: const TextStyle(
              color: _muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        if (_refreshing)
          const Padding(
            padding: EdgeInsets.only(right: 18),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primary,
                ),
              ),
            ),
          )
        else
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _loadHistory(),
            icon: const Icon(
              Icons.refresh_rounded,
              color: _text,
              size: 21,
            ),
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildContent() {
    final records = _visibleRecords;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        _buildMonthSelector(),
        const SizedBox(height: 14),
        _buildSummary(),
        if (_isManagement) ...[
          const SizedBox(height: 14),
          _buildEmployeeFilter(),
        ],
        if (_isManagement) ...[
          const SizedBox(height: 12),
          _buildSearch(),
        ],
        const SizedBox(height: 18),
        _buildSectionHeader(records),
        const SizedBox(height: 10),
        if (records.isEmpty)
          _buildEmptyState()
        else
          ...records.map(_buildAttendanceCard),
      ],
    );
  }

  Widget _buildMonthSelector() {
    final label = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _monthButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => _changeMonth(-1),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: _pickMonth,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    const Text(
                      'ATTENDANCE PERIOD',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: _primary,
                          size: 17,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          label,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          _monthButton(
            icon: Icons.chevron_right_rounded,
            onTap: _canGoForward ? () => _changeMonth(1) : null,
          ),
        ],
      ),
    );
  }

  bool get _canGoForward {
    final now = DateTime.now();
    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);
  }

  Widget _monthButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: const Color(0xFFF4F5FB),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 42,
          height: 46,
          child: Icon(
            icon,
            color: onTap == null ? const Color(0xFFD1D5DB) : _text,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.event_available_rounded,
            label: 'Present',
            value: '$_presentCount',
            color: _green,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _summaryCard(
            icon: Icons.schedule_rounded,
            label: 'Checked Out',
            value: '$_checkedOutCount',
            color: _blue,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _summaryCard(
            icon: Icons.free_breakfast_rounded,
            label: 'Breaks',
            value: _durationLabel(_totalBreakMinutes),
            color: _orange,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _summaryCard(
            icon: Icons.timer_outlined,
            label: 'Avg. Day',
            value: _averageHours,
            color: _primary,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeFilter() {
    final selectedName = _selectedEmployeeId == null
        ? 'All employees'
        : (_employeeById(_selectedEmployeeId!)?.name ?? 'Employee');

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showEmployeePicker,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.groups_2_rounded,
                color: _primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EMPLOYEE',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .9,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selectedName,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _muted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEmployeePicker() async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _EmployeePickerSheet(
          employees: _employees,
          selectedEmployeeId: _selectedEmployeeId,
        );
      },
    );

    if (!mounted) return;

    if (selected == '__ALL__') {
      setState(() => _selectedEmployeeId = null);
    } else if (selected != null) {
      setState(() => _selectedEmployeeId = selected);
    }
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (value) => setState(() => _search = value),
      decoration: InputDecoration(
        hintText: 'Search employee or date...',
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 12,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _muted,
          size: 20,
        ),
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  setState(() => _search = '');
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: _muted,
                  size: 18,
                ),
              ),
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(List<AttendanceRecord> records) {
    final monthText = DateFormat('MMMM').format(_selectedMonth);

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Attendance records',
            style: TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '${records.length} ${records.length == 1 ? 'record' : 'records'}',
          style: const TextStyle(
            color: _muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    final employee = _employeeById(record.userId);
    final date = _parseDateKey(record.date);
    final isToday = _isSameDay(date, DateTime.now());

    final statusColor = record.checkOutAt != null ? _blue : _green;
    final statusLabel =
        record.checkOutAt != null ? 'Checked Out' : 'Present';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAttendanceDetails(record, employee),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 13),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildAvatar(employee),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isManagement)
                            Text(
                              employee?.name ?? 'Employee',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _text,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          if (_isManagement) const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                DateFormat('EEE, d MMM').format(date),
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 6),
                                _pill('Today', _primary),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    _statusPill(statusLabel, statusColor),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FC),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _timelineMetric(
                          icon: Icons.login_rounded,
                          label: 'Check in',
                          value: _timeOrDash(record.checkInAt),
                          color: _green,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: _border,
                      ),
                      Expanded(
                        child: _timelineMetric(
                          icon: Icons.logout_rounded,
                          label: 'Check out',
                          value: _timeOrDash(record.checkOutAt),
                          color: _blue,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: _border,
                      ),
                      Expanded(
                        child: _timelineMetric(
                          icon: Icons.timer_outlined,
                          label: 'Duration',
                          value: record.totalMinutes > 0
                              ? record.totalHoursLabel
                              : '—',
                          color: _primary,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: _border,
                      ),
                      Expanded(
                        child: _timelineMetric(
                          icon: Icons.free_breakfast_rounded,
                          label: 'Break',
                          value: record.totalBreakMinutes > 0
                              ? _durationLabel(record.totalBreakMinutes)
                              : '—',
                          color: _orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: _muted,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _locationSummary(record),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFB5BAC7),
                      size: 19,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AppUser? employee) {
    final name = employee?.name.trim() ?? '';
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _timelineMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _text,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              color: _primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isManagement && _selectedEmployeeId == null
                ? 'No attendance records'
                : 'No attendance for this period',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Attendance records will appear here after employees check in.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 10.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        const Icon(
          Icons.cloud_off_rounded,
          color: _red,
          size: 44,
        ),
        const SizedBox(height: 14),
        const Text(
          'Unable to load attendance',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _error ?? 'Something went wrong.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: ElevatedButton.icon(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAttendanceDetails(
    AttendanceRecord record,
    AppUser? employee,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AttendanceDetailsSheet(
          record: record,
          employee: employee,
          isManagement: _isManagement,
        );
      },
    );
  }

  String _locationSummary(AttendanceRecord record) {
    final parts = <String>[];

    if (record.checkInDistanceMeters != null) {
      parts.add(
        'Check-in ${record.checkInDistanceMeters!.toStringAsFixed(0)}m from office',
      );
    }

    if (record.checkOutDistanceMeters != null) {
      parts.add(
        'Check-out ${record.checkOutDistanceMeters!.toStringAsFixed(0)}m',
      );
    }

    if (parts.isEmpty) {
      return 'Location proof available in attendance details';
    }

    return parts.join(' • ');
  }

  DateTime _parseDateKey(String value) {
    final parts = value.split('-');
    if (parts.length == 3) {
      return DateTime(
        int.tryParse(parts[0]) ?? _selectedMonth.year,
        int.tryParse(parts[1]) ?? _selectedMonth.month,
        int.tryParse(parts[2]) ?? 1,
      );
    }

    return _selectedMonth;
  }

  String _timeOrDash(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('hh:mm a').format(date);
  }

  String _durationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.isEmpty) return 'Unable to load attendance.';
    if (message.contains('permission-denied')) {
      return 'You do not have permission to view this attendance.';
    }

    return message;
  }
}

class _EmployeePickerSheet extends StatelessWidget {
  final List<AppUser> employees;
  final String? selectedEmployeeId;

  const _EmployeePickerSheet({
    required this.employees,
    required this.selectedEmployeeId,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 620),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select employee',
                  style: TextStyle(
                    color: Color(0xFF171923),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                children: [
                  _option(
                    context,
                    id: '__ALL__',
                    name: 'All employees',
                    subtitle: 'Show the complete team',
                    icon: Icons.groups_2_rounded,
                    selected: selectedEmployeeId == null,
                  ),
                  ...employees.map(
                    (employee) => _option(
                      context,
                      id: employee.id,
                      name: employee.name,
                      subtitle: employee.email,
                      icon: Icons.person_outline_rounded,
                      selected: selectedEmployeeId == employee.id,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required String id,
    required String name,
    required String subtitle,
    required IconData icon,
    required bool selected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFEEF2FF)
            : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected
              ? const Color(0xFFC7D2FE)
              : const Color(0xFFE7E9F2),
        ),
      ),
      child: ListTile(
        onTap: () => Navigator.pop(context, id),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFDDE3FF)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: selected
                ? const Color(0xFF4F46E5)
                : const Color(0xFF73778A),
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Color(0xFF171923),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF73778A),
            fontSize: 9.5,
          ),
        ),
        trailing: selected
            ? const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF6366F1),
                size: 21,
              )
            : const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB5BAC7),
              ),
      ),
    );
  }
}

class _AttendanceDetailsSheet extends StatefulWidget {
  final AttendanceRecord record;
  final AppUser? employee;
  final bool isManagement;

  const _AttendanceDetailsSheet({
    required this.record,
    required this.employee,
    required this.isManagement,
  });

  @override
  State<_AttendanceDetailsSheet> createState() =>
      _AttendanceDetailsSheetState();
}

class _AttendanceDetailsSheetState extends State<_AttendanceDetailsSheet> {
  final AttendanceService _attendanceService = AttendanceService.instance;
  late Future<List<AttendanceBreak>> _breaksFuture;

  @override
  void initState() {
    super.initState();
    _breaksFuture = _loadBreaks();
  }

  Future<List<AttendanceBreak>> _loadBreaks() async {
    final parts = widget.record.date.split('-');
    final date = parts.length == 3
        ? DateTime(
            int.tryParse(parts[0]) ?? DateTime.now().year,
            int.tryParse(parts[1]) ?? DateTime.now().month,
            int.tryParse(parts[2]) ?? DateTime.now().day,
          )
        : DateTime.now();

    return _attendanceService.getBreaksForAttendance(
      widget.record.attendanceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final date = _parseDate(widget.record.date);
    final hasCheckout = widget.record.checkOutAt != null;

    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF4F46E5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (widget.employee?.name.trim().isNotEmpty ?? false)
                          ? widget.employee!.name.trim()[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isManagement
                              ? (widget.employee?.name ?? 'Employee')
                              : 'My Attendance',
                          style: const TextStyle(
                            color: Color(0xFF171923),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy').format(date),
                          style: const TextStyle(
                            color: Color(0xFF73778A),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _status(
                    hasCheckout ? 'Checked Out' : 'Present',
                    hasCheckout
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF10B981),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFFE7E9F2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _bigMetric(
                        icon: Icons.login_rounded,
                        label: 'CHECK IN',
                        value: _time(widget.record.checkInAt),
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 45,
                      color: const Color(0xFFE7E9F2),
                    ),
                    Expanded(
                      child: _bigMetric(
                        icon: Icons.logout_rounded,
                        label: 'CHECK OUT',
                        value: _time(widget.record.checkOutAt),
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 45,
                      color: const Color(0xFFE7E9F2),
                    ),
                    Expanded(
                      child: _bigMetric(
                        icon: Icons.timer_outlined,
                        label: 'TOTAL',
                        value: widget.record.totalMinutes > 0
                            ? widget.record.totalHoursLabel
                            : '—',
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildBreaksSection(),
              const SizedBox(height: 18),
              _sectionTitle('Location verification'),
              const SizedBox(height: 9),
              _locationCard(
                title: 'Check-in location',
                address: widget.record.checkInAddress,
                distance: widget.record.checkInDistanceMeters,
                accuracy: widget.record.checkInAccuracy,
                latitude: widget.record.checkInLatitude,
                longitude: widget.record.checkInLongitude,
                color: const Color(0xFF10B981),
                photoUrl: widget.record.checkInPhotoUrl,
                onPhoto: widget.record.checkInPhotoUrl == null
                    ? null
                    : () => _showPhoto(
                          context,
                          widget.record.checkInPhotoUrl!,
                          'Check-in photo',
                        ),
              ),
              if (widget.record.checkOutAt != null) ...[
                const SizedBox(height: 9),
                _locationCard(
                  title: 'Check-out location',
                  address: widget.record.checkOutAddress,
                  distance: widget.record.checkOutDistanceMeters,
                  accuracy: widget.record.checkOutAccuracy,
                  latitude: widget.record.checkOutLatitude,
                  longitude: widget.record.checkOutLongitude,
                  color: const Color(0xFF2563EB),
                  photoUrl: widget.record.checkOutPhotoUrl,
                  onPhoto: widget.record.checkOutPhotoUrl == null
                      ? null
                      : () => _showPhoto(
                            context,
                            widget.record.checkOutPhotoUrl!,
                            'Check-out photo',
                          ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreaksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Break history'),
        const SizedBox(height: 9),
        FutureBuilder<List<AttendanceBreak>>(
          future: _breaksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7E9F2)),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return _breakInfoCard(
                icon: Icons.error_outline_rounded,
                title: 'Break history unavailable',
                subtitle: 'Unable to load break details for this attendance.',
                color: const Color(0xFFEF4444),
              );
            }

            final breaks = snapshot.data ?? const <AttendanceBreak>[];

            if (breaks.isEmpty) {
              return _breakInfoCard(
                icon: Icons.free_breakfast_outlined,
                title: 'No breaks recorded',
                subtitle: 'No lunch, tea, personal or other breaks were recorded.',
                color: const Color(0xFF9CA3AF),
              );
            }

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7E9F2)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 13, 9),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pause_circle_outline_rounded,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                        const SizedBox(width: 7),
                        const Expanded(
                          child: Text(
                            'Breaks taken',
                            style: TextStyle(
                              color: Color(0xFF171923),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${breaks.length} ${breaks.length == 1 ? 'break' : 'breaks'} • ${_durationLabel(breaks.fold<int>(0, (sum, item) => sum + item.durationMinutes))}',
                          style: const TextStyle(
                            color: Color(0xFF73778A),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...List.generate(breaks.length, (index) {
                    final item = breaks[index];
                    return Column(
                      children: [
                        if (index > 0)
                          const Divider(
                            height: 1,
                            color: Color(0xFFE7E9F2),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7E8),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  _breakIcon(item.type),
                                  color: const Color(0xFFF59E0B),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.displayLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF171923),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${_time(item.startedAt)} - ${_time(item.endedAt)}'
                                      '${item.note?.trim().isNotEmpty == true ? ' • ${item.note!.trim()}' : ''}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF73778A),
                                        fontSize: 9,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.durationLabel,
                                style: const TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _breakInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E9F2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF171923),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF73778A),
                    fontSize: 9,
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

  IconData _breakIcon(AttendanceBreakType type) {
    switch (type) {
      case AttendanceBreakType.lunch:
        return Icons.restaurant_rounded;
      case AttendanceBreakType.tea:
        return Icons.local_cafe_rounded;
      case AttendanceBreakType.coffee:
        return Icons.coffee_rounded;
      case AttendanceBreakType.shortBreak:
        return Icons.coffee_outlined;
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

  String _durationLabel(int minutes) {
    if (minutes <= 0) return '0m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
    return '${mins}m';
  }

  Widget _locationCard({
    required String title,
    required String? address,
    required double? distance,
    required double? accuracy,
    required double? latitude,
    required double? longitude,
    required Color color,
    required String? photoUrl,
    required VoidCallback? onPhoto,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E9F2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF171923),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address?.trim().isNotEmpty == true
                          ? address!
                          : 'GPS coordinates captured',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF73778A),
                        fontSize: 9.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              _smallFact(
                icon: Icons.social_distance_rounded,
                label: 'Distance',
                value: distance == null
                    ? '—'
                    : '${distance.toStringAsFixed(0)} m',
              ),
              const SizedBox(width: 8),
              _smallFact(
                icon: Icons.gps_fixed_rounded,
                label: 'Accuracy',
                value: accuracy == null
                    ? '—'
                    : '${accuracy.toStringAsFixed(0)} m',
              ),
              const SizedBox(width: 8),
              _smallFact(
                icon: Icons.my_location_rounded,
                label: 'GPS',
                value: latitude != null && longitude != null
                    ? 'Captured'
                    : '—',
              ),
            ],
          ),
          if (onPhoto != null) ...[
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPhoto,
                icon: const Icon(
                  Icons.photo_camera_back_rounded,
                  size: 17,
                ),
                label: Text(
                  'View ${title.toLowerCase()} photo',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(
                    color: Color(0xFFC7D2FE),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _smallFact({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF73778A),
              size: 14,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF171923),
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF171923),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF171923),
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _status(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static DateTime _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return DateTime.now();

    return DateTime(
      int.tryParse(parts[0]) ?? DateTime.now().year,
      int.tryParse(parts[1]) ?? DateTime.now().month,
      int.tryParse(parts[2]) ?? DateTime.now().day,
    );
  }

  static String _time(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('hh:mm a').format(value);
  }

  static void _showPhoto(
    BuildContext context,
    String url,
    String title,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: InteractiveViewer(
                  minScale: .8,
                  maxScale: 4,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(30),
                      color: Colors.white,
                      child: const Text(
                        'Unable to load photo.',
                        style: TextStyle(
                          color: Color(0xFF171923),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(30),
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
