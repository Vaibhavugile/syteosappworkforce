import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../models/app_user.dart';
import '../../../models/task.dart';
import '../../../models/task_daily_update.dart';
import '../../../services/task_daily_update_service.dart';
import '../../../services/task_service.dart';
import '../../../services/team_service.dart';

class TeamDailyWorkScreen extends StatefulWidget {
  const TeamDailyWorkScreen({super.key});

  @override
  State<TeamDailyWorkScreen> createState() => _TeamDailyWorkScreenState();
}

class _TeamDailyWorkScreenState extends State<TeamDailyWorkScreen> {
  static const _primary = Color(0xFF6366F1);
  static const _purple = Color(0xFF7C3AED);
  static const _background = Color(0xFFF6F7FB);
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  final TeamService _teamService = TeamService.instance;
  final TaskService _taskService = TaskService.instance;
  final TaskDailyUpdateService _dailyWorkService =
      TaskDailyUpdateService.instance;

  final TextEditingController _searchController = TextEditingController();

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String? _selectedEmployeeId;
  String _searchQuery = '';

  bool _checkingAccess = true;
  String? _accessError;

  @override
  void initState() {
    super.initState();
    _checkManagementAccess();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkManagementAccess() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null || uid.isEmpty) {
        throw StateError('Please sign in again.');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!snapshot.exists) {
        throw StateError('Your user profile was not found.');
      }

      final role = snapshot.data()?['role']?.toString().trim();

      if (!const {'ceo', 'cto', 'admin'}.contains(role)) {
        throw StateError(
          'Only CEO, CTO or Admin can view team daily work.',
        );
      }

      if (!mounted) return;

      setState(() {
        _checkingAccess = false;
        _accessError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _checkingAccess = false;
        _accessError = _friendlyError(e);
      });
    }
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: today,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = DateUtils.dateOnly(picked);
      _selectedEmployeeId = null;
    });
  }

  void _selectToday() {
    setState(() {
      _selectedDate = DateUtils.dateOnly(DateTime.now());
      _selectedEmployeeId = null;
    });
  }

  void _selectEmployee(String? employeeId) {
    setState(() {
      _selectedEmployeeId = employeeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Text(
          'Team Daily Work',
          style: GoogleFonts.manrope(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _text,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _checkManagementAccess,
            icon: const Icon(
              Icons.refresh_rounded,
              color: _text,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _checkingAccess
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : _accessError != null
              ? _buildAccessError()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<List<AppUser>>(
      stream: _teamService.watchAllEmployees(),
      builder: (context, employeeSnapshot) {
        if (employeeSnapshot.hasError) {
          return _buildErrorState(
            _friendlyError(employeeSnapshot.error!),
          );
        }

        if (employeeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }

        final employees = employeeSnapshot.data ?? <AppUser>[];

        return StreamBuilder<List<TaskDailyUpdate>>(
          stream: _dailyWorkService.watchAllDailyWorkForDate(_selectedDate),
          builder: (context, updateSnapshot) {
            if (updateSnapshot.hasError) {
              return _buildErrorState(
                _friendlyError(updateSnapshot.error!),
              );
            }

            if (updateSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            }

            final updates = updateSnapshot.data ?? <TaskDailyUpdate>[];

            return StreamBuilder<List<Task>>(
              stream: _taskService.watchAllTasks(),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.hasError) {
                  return _buildErrorState(
                    _friendlyError(taskSnapshot.error!),
                  );
                }

                if (taskSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }

                final tasks = taskSnapshot.data ?? <Task>[];

                return _buildDashboard(
                  employees: employees,
                  updates: updates,
                  tasks: tasks,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDashboard({
    required List<AppUser> employees,
    required List<TaskDailyUpdate> updates,
    required List<Task> tasks,
  }) {
    final activeEmployees =
        employees.where((employee) => employee.isActive).toList();

    final visibleEmployees = _filteredEmployees(employees);

    final selectedEmployee = _findEmployee(
      employees,
      _selectedEmployeeId,
    );

    final selectedUpdates = _selectedEmployeeId == null
        ? updates
        : updates
            .where((update) => update.userId == _selectedEmployeeId)
            .toList();

    final workedEmployeeIds =
        updates.map((update) => update.userId).toSet();

    final totalHours = updates.fold<double>(
      0,
      (sum, update) => sum + (update.hoursSpent ?? 0),
    );

    final completedToday = updates
        .where((update) => update.completionPercentage >= 100)
        .length;

    final totalProofFiles = updates.fold<int>(
      0,
      (sum, update) => sum + update.attachmentIds.length,
    );

    return RefreshIndicator(
      color: _primary,
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          _buildHero(
            employeeCount: activeEmployees.length,
            workedCount: workedEmployeeIds.length,
            totalHours: totalHours,
          ),
          const SizedBox(height: 16),
          _buildDateAndEmployeeSelector(
            employees: employees,
            selectedEmployee: selectedEmployee,
          ),
          const SizedBox(height: 16),
          _buildSummary(
            employees: activeEmployees,
            updates: updates,
            workedCount: workedEmployeeIds.length,
            totalHours: totalHours,
            completedToday: completedToday,
            proofFiles: totalProofFiles,
          ),
          const SizedBox(height: 18),
          if (_selectedEmployeeId != null)
            _buildSelectedEmployeePanel(
              employee: selectedEmployee,
              updates: selectedUpdates,
              tasks: tasks,
            ),
          if (_selectedEmployeeId != null)
            const SizedBox(height: 18),
          _buildEmployeeSection(
            employees: visibleEmployees,
            allEmployees: employees,
            updates: updates,
            tasks: tasks,
          ),
          if (visibleEmployees.isEmpty)
            _buildNoEmployeesFound(),
        ],
      ),
    );
  }

  Widget _buildHero({
    required int employeeCount,
    required int workedCount,
    required double totalHours,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Team work overview',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
            style: GoogleFonts.manrope(
              color: Colors.white.withOpacity(.88),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedEmployeeId == null
                ? 'Monitor daily work submitted by your team.'
                : 'Viewing work for the selected employee.',
            style: GoogleFonts.manrope(
              color: Colors.white.withOpacity(.70),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _heroMetric(
                  '$employeeCount',
                  'Active team',
                ),
              ),
              Expanded(
                child: _heroMetric(
                  '$workedCount',
                  'Worked today',
                ),
              ),
              Expanded(
                child: _heroMetric(
                  _formatHours(totalHours),
                  'Hours',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.manrope(
            color: Colors.white.withOpacity(.68),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDateAndEmployeeSelector({
    required List<AppUser> employees,
    required AppUser? selectedEmployee,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.filter_alt_outlined,
            title: 'Work filters',
            subtitle: 'Choose a date and optionally one employee.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: _primary,
                          size: 19,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DATE',
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  color: _muted,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                DateFormat('dd MMM yyyy')
                                    .format(_selectedDate),
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: _text,
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
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 53,
                child: OutlinedButton(
                  onPressed: _selectToday,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: Color(0xFFC7D2FE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Today',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _selectedEmployeeId,
            isExpanded: true,
            decoration: _inputDecoration(
              label: 'Employee',
              hint: 'All employees',
              prefixIcon: Icons.person_search_outlined,
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'All Employees',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
              ),
              ...employees.map(
                (employee) => DropdownMenuItem<String?>(
                  value: employee.id,
                  child: Row(
                    children: [
                      _smallAvatar(employee),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          employee.name.trim().isEmpty
                              ? employee.email
                              : employee.name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        employee.roleLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: _selectEmployee,
          ),
          if (selectedEmployee != null) ...[
            const SizedBox(height: 12),
            _selectedEmployeeChip(selectedEmployee),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: _inputDecoration(
              label: 'Search team',
              hint: 'Search name, email or phone',
              prefixIcon: Icons.search_rounded,
            ).copyWith(
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedEmployeeChip(AppUser employee) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: [
          _smallAvatar(employee),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name.isEmpty ? employee.email : employee.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  employee.roleLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _selectEmployee(null),
            child: Text(
              'Clear',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary({
    required List<AppUser> employees,
    required List<TaskDailyUpdate> updates,
    required int workedCount,
    required double totalHours,
    required int completedToday,
    required int proofFiles,
  }) {
    final noUpdateCount =
        (employees.length - workedCount).clamp(0, employees.length);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.65,
      children: [
        _summaryCard(
          icon: Icons.check_circle_outline_rounded,
          label: 'Worked',
          value: '$workedCount',
          detail: 'employees',
          iconColor: const Color(0xFF059669),
          iconBackground: const Color(0xFFD1FAE5),
        ),
        _summaryCard(
          icon: Icons.person_off_outlined,
          label: 'No update',
          value: '$noUpdateCount',
          detail: 'employees',
          iconColor: const Color(0xFFDC2626),
          iconBackground: const Color(0xFFFEE2E2),
        ),
        _summaryCard(
          icon: Icons.task_alt_outlined,
          label: 'Updates',
          value: '${updates.length}',
          detail: 'entries',
          iconColor: _primary,
          iconBackground: const Color(0xFFE0E7FF),
        ),
        _summaryCard(
          icon: Icons.schedule_outlined,
          label: 'Hours',
          value: _formatHours(totalHours),
          detail: '$completedToday completed',
          iconColor: const Color(0xFF7C3AED),
          iconBackground: const Color(0xFFEDE9FE),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required String detail,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    color: _text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    color: _muted,
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

  Widget _buildSelectedEmployeePanel({
    required AppUser? employee,
    required List<TaskDailyUpdate> updates,
    required List<Task> tasks,
  }) {
    if (employee == null) {
      return const SizedBox.shrink();
    }

    final hours = updates.fold<double>(
      0,
      (sum, update) => sum + (update.hoursSpent ?? 0),
    );

    final average = updates.isEmpty
        ? 0.0
        : updates.fold<double>(
              0,
              (sum, update) => sum + update.completionPercentage,
            ) /
            updates.length;

    final proofCount = updates.fold<int>(
      0,
      (sum, update) => sum + update.attachmentIds.length,
    );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _largeAvatar(employee),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name.isEmpty
                          ? employee.email
                          : employee.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      employee.roleLabel,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _statusPill(
                updates.isEmpty ? 'No update' : 'Worked',
                updates.isEmpty
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFECFDF5),
                updates.isEmpty
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF059669),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _detailMetric(
                  'Entries',
                  '${updates.length}',
                ),
              ),
              Expanded(
                child: _detailMetric(
                  'Hours',
                  _formatHours(hours),
                ),
              ),
              Expanded(
                child: _detailMetric(
                  'Avg. progress',
                  '${average.toStringAsFixed(0)}%',
                ),
              ),
              Expanded(
                child: _detailMetric(
                  'Proof',
                  '$proofCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (updates.isEmpty)
            _noUpdateMessage(employee)
          else
            Column(
              children: [
                for (final update in updates)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _dailyUpdateCard(
                      update: update,
                      tasks: tasks,
                      employee: employee,
                      compact: true,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSection({
    required List<AppUser> employees,
    required List<AppUser> allEmployees,
    required List<TaskDailyUpdate> updates,
    required List<Task> tasks,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedEmployeeId == null
                    ? 'Employees'
                    : 'Selected employee',
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
            ),
            Text(
              '${employees.length} shown',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_selectedEmployeeId != null)
          _buildSelectedEmployeeOnly(
            employees,
            updates,
            tasks,
          )
        else
          ...employees.map(
            (employee) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _employeeCard(
                employee: employee,
                updates: updates
                    .where((update) => update.userId == employee.id)
                    .toList(),
                tasks: tasks,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedEmployeeOnly(
    List<AppUser> employees,
    List<TaskDailyUpdate> updates,
    List<Task> tasks,
  ) {
    final employee = _findEmployee(employees, _selectedEmployeeId);

    if (employee == null) {
      return const SizedBox.shrink();
    }

    return _employeeCard(
      employee: employee,
      updates: updates
          .where((update) => update.userId == employee.id)
          .toList(),
      tasks: tasks,
      expanded: true,
    );
  }

  Widget _employeeCard({
    required AppUser employee,
    required List<TaskDailyUpdate> updates,
    required List<Task> tasks,
    bool expanded = false,
  }) {
    final hours = updates.fold<double>(
      0,
      (sum, update) => sum + (update.hoursSpent ?? 0),
    );

    final average = updates.isEmpty
        ? 0.0
        : updates.fold<double>(
              0,
              (sum, update) => sum + update.completionPercentage,
            ) /
            updates.length;

    final proofCount = updates.fold<int>(
      0,
      (sum, update) => sum + update.attachmentIds.length,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: employee.id == _selectedEmployeeId
              ? const Color(0xFFC7D2FE)
              : _border,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showEmployeeDetails(
              employee,
              updates,
              tasks,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                _largeAvatar(employee, size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              employee.name.isEmpty
                                  ? employee.email
                                  : employee.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: _text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _activeDot(employee.isActive),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        employee.roleLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusPill(
                  updates.isEmpty ? 'No update' : 'Worked',
                  updates.isEmpty
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFECFDF5),
                  updates.isEmpty
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF059669),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _miniMetric(
                    Icons.assignment_outlined,
                    '${updates.length}',
                    'Updates',
                  ),
                ),
                Expanded(
                  child: _miniMetric(
                    Icons.schedule_outlined,
                    _formatHours(hours),
                    'Hours',
                  ),
                ),
                Expanded(
                  child: _miniMetric(
                    Icons.trending_up_rounded,
                    '${average.toStringAsFixed(0)}%',
                    'Progress',
                  ),
                ),
                Expanded(
                  child: _miniMetric(
                    Icons.attach_file_rounded,
                    '$proofCount',
                    'Proof',
                  ),
                ),
              ],
            ),
          ),
          if (expanded && updates.isNotEmpty) ...[
            const SizedBox(height: 13),
            ...updates.map(
              (update) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _dailyUpdateCard(
                  update: update,
                  tasks: tasks,
                  employee: employee,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dailyUpdateCard({
    required TaskDailyUpdate update,
    required List<Task> tasks,
    required AppUser employee,
    bool compact = false,
  }) {
    final task = _findTask(tasks, update.taskId);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 13 : 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.task_alt_outlined,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task?.title ?? 'Task ${update.taskId}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${employee.name.isEmpty ? employee.email : employee.name} • '
                      '${DateFormat('dd MMM, hh:mm a').format(update.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _statusPill(
                update.statusLabel,
                _statusBackground(update.status),
                _statusColor(update.status),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            update.description,
            maxLines: compact ? 4 : 8,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _progressMini(
                  update.completionPercentage,
                ),
              ),
              const SizedBox(width: 10),
              if (update.hoursSpent != null)
                _smallInfo(
                  Icons.schedule_outlined,
                  _formatHours(update.hoursSpent!),
                ),
              if (update.attachmentIds.isNotEmpty) ...[
                const SizedBox(width: 8),
                _smallInfo(
                  Icons.attach_file_rounded,
                  '${update.attachmentIds.length}',
                ),
              ],
            ],
          ),
          if (update.attachmentIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildProofFiles(update.attachmentIds),
          ],
        ],
      ),
    );
  }

  Widget _progressMini(double percentage) {
    final value = percentage.clamp(0, 100).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progress',
              style: GoogleFonts.manrope(
                fontSize: 9,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: _primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 5,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation(_primary),
          ),
        ),
      ],
    );
  }

  Widget _proofInfo(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 14,
            color: _purple,
          ),
          const SizedBox(width: 5),
          Text(
            '$count proof file${count == 1 ? '' : 's'} attached',
            style: GoogleFonts.manrope(
              fontSize: 9,
              color: _purple,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetails(
    AppUser employee,
    List<TaskDailyUpdate> updates,
    List<Task> tasks,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _EmployeeDailyDetailsSheet(
          employee: employee,
          updates: updates,
          tasks: tasks,
        );
      },
    );
  }

  Widget _noUpdateMessage(AppUser employee) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFEA580C),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${employee.name.isEmpty ? 'This employee' : employee.name} has not submitted daily work for this date.',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: const Color(0xFF9A3412),
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // PROOF FILES
  // ===========================================================================

  Widget _buildProofFiles(List<String> attachmentIds) {
    return FutureBuilder<List<_ProofFile>>(
      future: _loadProofFiles(attachmentIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _purple,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  'Loading proof files...',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: _purple,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _proofError(
            'Unable to load proof files.',
          );
        }

        final files = snapshot.data ?? <_ProofFile>[];

        if (files.isEmpty) {
          return _proofError(
            'Proof record not found. The daily work entry still contains the attachment ID.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 15,
                  color: _purple,
                ),
                const SizedBox(width: 6),
                Text(
                  '${files.length} proof file${files.length == 1 ? '' : 's'}',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: _purple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...files.map(_proofFileTile),
          ],
        );
      },
    );
  }

  Future<List<_ProofFile>> _loadProofFiles(
    List<String> attachmentIds,
  ) async {
    final cleanIds = attachmentIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (cleanIds.isEmpty) {
      return const [];
    }

    final results = <_ProofFile>[];

    // Read by document ID instead of relying on a Firestore "whereIn"
    // limitation. This also works with any number of proof files.
    for (final id in cleanIds) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('taskAttachments')
            .doc(id)
            .get();

        if (!snapshot.exists) {
          continue;
        }

        final data = snapshot.data() ?? <String, dynamic>{};

        final file = _ProofFile.fromFirestore(
          snapshot.id,
          data,
        );

        if (file.hasSource) {
          results.add(file);
        }
      } catch (_) {
        // Keep the remaining proof files visible if one document fails.
      }
    }

    return results;
  }

  Widget _proofFileTile(_ProofFile file) {
    final color = _proofColor(file.type);
    final isImage = file.isImage;

    return InkWell(
      onTap: () => _openProofFile(file),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9E7F2)),
        ),
        child: Row(
          children: [
            if (isImage && file.url.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  file.url,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _proofIcon(color, file.type),
                ),
              )
            else
              _proofIcon(color, file.type),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName.isEmpty
                        ? 'Proof file'
                        : file.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: _text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${file.displayType} • Tap to open',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isImage
                  ? Icons.visibility_outlined
                  : Icons.open_in_new_rounded,
              color: _primary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _proofIcon(Color color, String type) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        _proofIconData(type),
        color: color,
        size: 21,
      ),
    );
  }

  Widget _proofError(String message) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(
                fontSize: 9,
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  Future<void> _openProofFile(_ProofFile file) async {
    try {
      var url = file.url.trim();

      // If Firestore does not contain downloadUrl, generate a fresh
      // Firebase Storage download URL from storagePath.
      if (url.isEmpty && file.storagePath.isNotEmpty) {
        url = await firebase_storage.FirebaseStorage.instance
            .ref(file.storagePath)
            .getDownloadURL();
      }

      if (url.isEmpty) {
        if (!mounted) return;
        _showMessage('Proof file link is unavailable.');
        return;
      }

      if (file.isImage) {
        if (!mounted) return;
        await _showImagePreview(file.copyWith(url: url));
        return;
      }

      final uri = Uri.tryParse(url);

      if (uri == null) {
        if (!mounted) return;
        _showMessage('Invalid proof file link.');
        return;
      }

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showMessage(
          'Unable to open ${file.fileName.isEmpty ? 'proof file' : file.fileName}.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to open proof file. Check Firebase Storage permissions.',
      );
    }
  }

  Future<void> _showImagePreview(_ProofFile file) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(.78),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  InteractiveViewer(
                    minScale: .7,
                    maxScale: 4,
                    child: Image.network(
                      file.url,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      loadingBuilder:
                          (context, child, progress) {
                        if (progress == null) return child;

                        return const SizedBox(
                          height: 420,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) {
                        return const SizedBox(
                          height: 420,
                          child: Center(
                            child: Text(
                              'Unable to display this image.',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  if (file.fileName.isNotEmpty)
                    Positioned(
                      left: 14,
                      right: 60,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.58),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          file.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
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
  }

  IconData _proofIconData(String type) {
    final value = type.toLowerCase();

    if (value.contains('image') ||
        value == 'jpg' ||
        value == 'jpeg' ||
        value == 'png' ||
        value == 'webp') {
      return Icons.image_outlined;
    }

    if (value.contains('screen')) {
      return Icons.screen_share_outlined;
    }

    if (value.contains('video') ||
        value == 'mp4' ||
        value == 'mov' ||
        value == 'mkv' ||
        value == 'webm') {
      return Icons.videocam_outlined;
    }

    if (value.contains('pdf')) {
      return Icons.picture_as_pdf_outlined;
    }

    if (value.contains('doc') ||
        value.contains('word')) {
      return Icons.description_outlined;
    }

    if (value.contains('xls') ||
        value.contains('sheet')) {
      return Icons.table_chart_outlined;
    }

    if (value.contains('ppt') ||
        value.contains('presentation')) {
      return Icons.slideshow_outlined;
    }

    return Icons.insert_drive_file_outlined;
  }

  Color _proofColor(String type) {
    final value = type.toLowerCase();

    if (value.contains('image') ||
        value == 'jpg' ||
        value == 'jpeg' ||
        value == 'png' ||
        value == 'webp') {
      return const Color(0xFF0284C7);
    }

    if (value.contains('video') ||
        value.contains('screen')) {
      return const Color(0xFF7C3AED);
    }

    if (value.contains('pdf')) {
      return const Color(0xFFDC2626);
    }

    if (value.contains('doc') ||
        value.contains('word')) {
      return const Color(0xFF2563EB);
    }

    return const Color(0xFF64748B);
  }

  Widget _buildNoEmployeesFound() {
    return Container(
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
              Icons.person_search_outlined,
              color: _primary,
              size: 31,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'No employees found',
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another employee name, email or phone number.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessError() {
    return _buildErrorState(
      _accessError ?? 'Unable to open team daily work.',
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(23),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 35,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              'Unable to load team work',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: _muted,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _checkManagementAccess,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AppUser> _filteredEmployees(List<AppUser> employees) {
    if (_searchQuery.isEmpty) {
      return employees;
    }

    return employees.where((employee) {
      final name = employee.name.toLowerCase();
      final email = employee.email.toLowerCase();
      final phone = employee.phone.toLowerCase();

      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          phone.contains(_searchQuery);
    }).toList();
  }

  AppUser? _findEmployee(
    List<AppUser> employees,
    String? id,
  ) {
    if (id == null || id.isEmpty) return null;

    for (final employee in employees) {
      if (employee.id == id) {
        return employee;
      }
    }

    return null;
  }

  Task? _findTask(
    List<Task> tasks,
    String id,
  ) {
    for (final task in tasks) {
      if (task.taskId == id) {
        return task;
      }
    }

    return null;
  }

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: _primary,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: _text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    String? label,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              color: const Color(0xFF9CA3AF),
              size: 20,
            ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
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
        borderSide: const BorderSide(
          color: _primary,
          width: 1.5,
        ),
      ),
      labelStyle: GoogleFonts.manrope(
        fontSize: 11,
        color: _muted,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: GoogleFonts.manrope(
        fontSize: 12,
        color: const Color(0xFF9CA3AF),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _largeAvatar(
    AppUser employee, {
    double size = 54,
  }) {
    final image = employee.profileImage?.trim();

    if (image != null && image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * .30),
        child: Image.network(
          image,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _initialAvatar(employee, size);
          },
        ),
      );
    }

    return _initialAvatar(employee, size);
  }

  Widget _smallAvatar(AppUser employee) {
    return _largeAvatar(employee, size: 34);
  }

  Widget _initialAvatar(
    AppUser employee,
    double size,
  ) {
    final name = employee.name.trim();
    final initial = name.isEmpty
        ? '?'
        : name.substring(0, 1).toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(size * .30),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: size * .36,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _activeDot(bool active) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF10B981)
            : const Color(0xFF9CA3AF),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _statusPill(
    String label,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.manrope(
          fontSize: 8,
          color: foreground,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _detailMetric(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 9,
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: _text,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _miniMetric(
    IconData icon,
    String value,
    String label,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: _primary,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: _text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 8,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smallInfo(
    IconData icon,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: _muted,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 9,
              color: _text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(TaskDailyUpdateStatus status) {
    switch (status) {
      case TaskDailyUpdateStatus.draft:
        return const Color(0xFF6B7280);
      case TaskDailyUpdateStatus.submitted:
        return const Color(0xFF2563EB);
      case TaskDailyUpdateStatus.underReview:
        return const Color(0xFFD97706);
      case TaskDailyUpdateStatus.approved:
        return const Color(0xFF059669);
      case TaskDailyUpdateStatus.changesRequested:
        return const Color(0xFFDC2626);
    }
  }

  Color _statusBackground(TaskDailyUpdateStatus status) {
    switch (status) {
      case TaskDailyUpdateStatus.draft:
        return const Color(0xFFF3F4F6);
      case TaskDailyUpdateStatus.submitted:
        return const Color(0xFFEFF6FF);
      case TaskDailyUpdateStatus.underReview:
        return const Color(0xFFFFFBEB);
      case TaskDailyUpdateStatus.approved:
        return const Color(0xFFECFDF5);
      case TaskDailyUpdateStatus.changesRequested:
        return const Color(0xFFFEF2F2);
    }
  }

  String _formatHours(double hours) {
    if (hours == 0) return '0h';

    if (hours == hours.roundToDouble()) {
      return '${hours.toStringAsFixed(0)}h';
    }

    return '${hours.toStringAsFixed(1)}h';
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('No authenticated user')) {
      return 'Please sign in again.';
    }

    if (message.contains('Only CEO, CTO or Admin')) {
      return 'You do not have permission to view team daily work.';
    }

    if (message.contains('permission-denied')) {
      return 'Firebase denied access to team daily work.';
    }

    if (message.startsWith('Bad state: ')) {
      return message.replaceFirst('Bad state: ', '');
    }

    return message.isEmpty
        ? 'Something went wrong while loading team daily work.'
        : message;
  }
}


class _BottomSheetProofFiles extends StatelessWidget {
  const _BottomSheetProofFiles({
    required this.attachmentIds,
  });

  final List<String> attachmentIds;

  Future<List<_ProofFile>> _load() async {
    final results = <_ProofFile>[];

    for (final rawId in attachmentIds) {
      final id = rawId.trim();
      if (id.isEmpty) continue;

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('taskAttachments')
            .doc(id)
            .get();

        if (!snapshot.exists) continue;

        final file = _ProofFile.fromFirestore(
          snapshot.id,
          snapshot.data() ?? <String, dynamic>{},
        );

        if (file.hasSource) {
          results.add(file);
        }
      } catch (_) {}
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ProofFile>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(
              minHeight: 3,
              color: Color(0xFF6366F1),
            ),
          );
        }

        final files = snapshot.data ?? const <_ProofFile>[];

        if (files.isEmpty) {
          return Text(
            'Proof files could not be loaded.',
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: const Color(0xFFB45309),
              fontWeight: FontWeight.w700,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proof files',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: const Color(0xFF6366F1),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            ...files.map(
              (file) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _BottomSheetProofTile(file: file),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BottomSheetProofTile extends StatelessWidget {
  const _BottomSheetProofTile({
    required this.file,
  });

  final _ProofFile file;

  Future<void> _open(BuildContext context) async {
    try {
      var url = file.url.trim();

      if (url.isEmpty && file.storagePath.isNotEmpty) {
        url = await firebase_storage.FirebaseStorage.instance
            .ref(file.storagePath)
            .getDownloadURL();
      }

      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proof file link is unavailable.'),
          ),
        );
        return;
      }

      if (file.isImage) {
        await showDialog<void>(
          context: context,
          barrierColor: Colors.black87,
          builder: (_) => Dialog(
            backgroundColor: Colors.black,
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'Unable to display image.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        );
        return;
      }

      final uri = Uri.tryParse(url);

      if (uri != null) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open proof. Check Firebase Storage permissions.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              file.isImage
                  ? Icons.image_outlined
                  : Icons.attach_file_rounded,
              size: 15,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                file.fileName.isEmpty
                    ? 'Proof file'
                    : file.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              size: 14,
              color: Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofFile {
  const _ProofFile({
    required this.id,
    required this.fileName,
    required this.type,
    required this.url,
    required this.storagePath,
    required this.mimeType,
  });

  final String id;
  final String fileName;
  final String type;
  final String url;
  final String storagePath;
  final String mimeType;

  bool get hasSource =>
      url.trim().isNotEmpty || storagePath.trim().isNotEmpty;

  bool get isImage {
    final value = '${type.toLowerCase()} ${mimeType.toLowerCase()} '
        '${fileName.toLowerCase()}';

    return value.contains('image') ||
        value.contains('jpg') ||
        value.contains('jpeg') ||
        value.contains('png') ||
        value.contains('webp');
  }

  String get displayType {
    final value = type.trim();

    if (value.isEmpty) {
      final name = fileName.toLowerCase();

      if (name.endsWith('.pdf')) return 'PDF';
      if (name.endsWith('.doc') || name.endsWith('.docx')) {
        return 'Document';
      }
      if (name.endsWith('.mp4') ||
          name.endsWith('.mov') ||
          name.endsWith('.webm')) {
        return 'Video';
      }
      if (isImage) return 'Image';

      return 'File';
    }

    return value;
  }

  factory _ProofFile.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final fileName = _stringValue(
      data['fileName'] ??
          data['name'] ??
          data['originalFileName'] ??
          data['file'],
    );

    final url = _stringValue(
      data['downloadUrl'] ??
          data['url'] ??
          data['downloadURL'],
    );

    final storagePath = _stringValue(
      data['storagePath'] ??
          data['path'] ??
          data['storageReference'],
    );

    final type = _stringValue(
      data['type'] ??
          data['attachmentType'] ??
          data['fileType'],
    );

    final mimeType = _stringValue(
      data['mimeType'] ??
          data['contentType'],
    );

    return _ProofFile(
      id: id,
      fileName: fileName,
      type: type,
      url: url,
      storagePath: storagePath,
      mimeType: mimeType,
    );
  }

  _ProofFile copyWith({
    String? url,
  }) {
    return _ProofFile(
      id: id,
      fileName: fileName,
      type: type,
      url: url ?? this.url,
      storagePath: storagePath,
      mimeType: mimeType,
    );
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}

class _EmployeeDailyDetailsSheet extends StatelessWidget {
  const _EmployeeDailyDetailsSheet({
    required this.employee,
    required this.updates,
    required this.tasks,
  });

  final AppUser employee;
  final List<TaskDailyUpdate> updates;
  final List<Task> tasks;

  static const _primary = Color(0xFF6366F1);
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final hours = updates.fold<double>(
      0,
      (sum, update) => sum + (update.hoursSpent ?? 0),
    );

    final proof = updates.fold<int>(
      0,
      (sum, update) => sum + update.attachmentIds.length,
    );

    final average = updates.isEmpty
        ? 0.0
        : updates.fold<double>(
              0,
              (sum, update) => sum + update.completionPercentage,
            ) /
            updates.length;

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 760,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7FB),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                15,
              ),
              child: Row(
                children: [
                  _avatar(employee),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name.isEmpty
                              ? employee.email
                              : employee.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 17,
                            color: _text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          employee.roleLabel,
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            color: _muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _text,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _metric('Updates', '${updates.length}')),
                  Expanded(child: _metric('Hours', _formatHours(hours))),
                  Expanded(
                    child: _metric(
                      'Progress',
                      '${average.toStringAsFixed(0)}%',
                    ),
                  ),
                  Expanded(child: _metric('Proof', '$proof')),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: updates.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text(
                          'No daily work submitted for this employee on this date.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: _muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        28,
                      ),
                      itemCount: updates.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final update = updates[index];
                        final task = _findTask(
                          tasks,
                          update.taskId,
                        );

                        return _updateCard(
                          update,
                          task?.title ?? 'Task ${update.taskId}',
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _updateCard(
    TaskDailyUpdate update,
    String taskTitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  taskTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: _text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _statusPill(update),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(update.createdAt),
            style: GoogleFonts.manrope(
              fontSize: 9,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            update.description,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _progress(update.completionPercentage),
              ),
              if (update.hoursSpent != null) ...[
                const SizedBox(width: 10),
                _info(
                  Icons.schedule_outlined,
                  _formatHours(update.hoursSpent!),
                ),
              ],
            ],
          ),
          if (update.attachmentIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _BottomSheetProofFiles(
              attachmentIds: update.attachmentIds,
            ),
          ],
        ],
      ),
    );
  }

  Widget _progress(double percentage) {
    final value = percentage.clamp(0, 100).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Completion',
              style: GoogleFonts.manrope(
                fontSize: 9,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: _primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 5,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation(_primary),
          ),
        ),
      ],
    );
  }

  Widget _info(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _muted),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 9,
              color: _text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(TaskDailyUpdate update) {
    Color color;
    Color background;

    switch (update.status) {
      case TaskDailyUpdateStatus.draft:
        color = const Color(0xFF6B7280);
        background = const Color(0xFFF3F4F6);
        break;
      case TaskDailyUpdateStatus.submitted:
        color = const Color(0xFF2563EB);
        background = const Color(0xFFEFF6FF);
        break;
      case TaskDailyUpdateStatus.underReview:
        color = const Color(0xFFD97706);
        background = const Color(0xFFFFFBEB);
        break;
      case TaskDailyUpdateStatus.approved:
        color = const Color(0xFF059669);
        background = const Color(0xFFECFDF5);
        break;
      case TaskDailyUpdateStatus.changesRequested:
        color = const Color(0xFFDC2626);
        background = const Color(0xFFFEF2F2);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        update.statusLabel,
        style: GoogleFonts.manrope(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 9,
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: _text,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _avatar(AppUser employee) {
    final image = employee.profileImage?.trim();

    if (image != null && image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          image,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _initialAvatar(employee),
        ),
      );
    }

    return _initialAvatar(employee);
  }

  Widget _initialAvatar(AppUser employee) {
    final name = employee.name.trim();
    final initial = name.isEmpty
        ? '?'
        : name.substring(0, 1).toUpperCase();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Task? _findTask(List<Task> tasks, String id) {
    for (final task in tasks) {
      if (task.taskId == id) return task;
    }
    return null;
  }

  String _formatHours(double hours) {
    if (hours == 0) return '0h';

    if (hours == hours.roundToDouble()) {
      return '${hours.toStringAsFixed(0)}h';
    }

    return '${hours.toStringAsFixed(1)}h';
  }
}
