import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_user.dart';
import '../../../services/team_service.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final TeamService _teamService = TeamService.instance;
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  UserRole? _selectedRole;
  bool? _activeFilter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery =
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: _buildAppBar(),
      body: StreamBuilder<List<AppUser>>(
        stream: _teamService.watchAllEmployees(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildError(
              snapshot.error.toString(),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            );
          }

          final employees = snapshot.data ?? [];

          final filteredEmployees =
              _filterEmployees(employees);

          return RefreshIndicator(
            color: const Color(0xFF6366F1),
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                40,
              ),
              children: [
                _buildHeader(employees),
                const SizedBox(height: 20),
                _buildSummaryCards(employees),
                const SizedBox(height: 24),
                _buildSearchAndFilters(),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  filteredEmployees.length,
                ),
                const SizedBox(height: 12),
                if (filteredEmployees.isEmpty)
                  _buildEmptyState()
                else
                  ...filteredEmployees.map(
                    _buildEmployeeCard,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: true,
      titleSpacing: 20,
      title: Text(
        'Team',
        style: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF111827),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(
            Icons.refresh_rounded,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(List<AppUser> employees) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF7C3AED),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Management',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Manage employees, roles and access.',
                  style: GoogleFonts.manrope(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${employees.length} members',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCards(
    List<AppUser> employees,
  ) {
    final active =
        employees.where((e) => e.isActive).length;

    final inactive =
        employees.where((e) => !e.isActive).length;

    final management = employees
        .where(
          (e) =>
              e.role == UserRole.ceo ||
              e.role == UserRole.cto ||
              e.role == UserRole.admin,
        )
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total',
            value: employees.length.toString(),
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            title: 'Active',
            value: active.toString(),
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            title: 'Inactive',
            value: inactive.toString(),
            icon: Icons.pause_circle_rounded,
            iconColor: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            title: 'Management',
            value: management.toString(),
            icon: Icons.admin_panel_settings_rounded,
            iconColor: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH + FILTERS
  // ============================================================

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
            decoration: InputDecoration(
              hintText:
                  'Search by name, email or phone...',
              hintStyle: GoogleFonts.manrope(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF6B7280),
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 19,
                      ),
                    ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip(
                label: 'All roles',
                selected: _selectedRole == null,
                onTap: () {
                  setState(() {
                    _selectedRole = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              ...UserRole.values.map(
                (role) => Padding(
                  padding:
                      const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: _teamService.roleLabel(role),
                    selected:
                        _selectedRole == role,
                    onTap: () {
                      setState(() {
                        _selectedRole = role;
                      });
                    },
                  ),
                ),
              ),
              _buildFilterChip(
                label: 'Active',
                selected: _activeFilter == true,
                onTap: () {
                  setState(() {
                    _activeFilter =
                        _activeFilter == true
                            ? null
                            : true;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Inactive',
                selected: _activeFilter == false,
                onTap: () {
                  setState(() {
                    _activeFilter =
                        _activeFilter == false
                            ? null
                            : false;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? const Color(0xFFEEF2FF)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFFC7D2FE)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        Text(
          'Employees',
          style: GoogleFonts.manrope(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4F46E5),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPLOYEE CARD
  // ============================================================

  Widget _buildEmployeeCard(AppUser employee) {
    final roleColor =
        _roleColor(employee.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () =>
            _showEmployeeDetails(employee),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(employee),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            employee.name.isEmpty
                                ? 'Unnamed Employee'
                                : employee.name,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w800,
                              color:
                                  const Color(0xFF111827),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusDot(
                          employee.isActive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      employee.email,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            const Color(0xFF6B7280),
                      ),
                    ),
                    if (employee.phone != null &&
                        employee.phone!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        employee.phone!,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w500,
                          color:
                              const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor
                            .withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(
                        _teamService.roleLabel(
                          employee.role,
                        ),
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                          color: roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AppUser employee) {
    if (employee.profileImage != null &&
        employee.profileImage!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.network(
          employee.profileImage!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) {
            return _buildInitialAvatar(employee);
          },
        ),
      );
    }

    return _buildInitialAvatar(employee);
  }

  Widget _buildInitialAvatar(AppUser employee) {
    final name = employee.name.trim();

    final initial = name.isEmpty
        ? '?'
        : name.substring(0, 1).toUpperCase();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusDot(bool active) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF10B981)
            : const Color(0xFF9CA3AF),
        shape: BoxShape.circle,
      ),
    );
  }

  // ============================================================
  // FILTERING
  // ============================================================

  List<AppUser> _filterEmployees(
    List<AppUser> employees,
  ) {
    return employees.where((employee) {
      if (_selectedRole != null &&
          employee.role != _selectedRole) {
        return false;
      }

      if (_activeFilter != null &&
          employee.isActive != _activeFilter) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final name =
            employee.name.toLowerCase();
        final email =
            employee.email.toLowerCase();
        final phone =
            (employee.phone ?? '').toLowerCase();

        if (!name.contains(_searchQuery) &&
            !email.contains(_searchQuery) &&
            !phone.contains(_searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ============================================================
  // EMPLOYEE DETAILS
  // ============================================================

  void _showEmployeeDetails(
    AppUser employee,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _EmployeeDetailsSheet(
          employee: employee,
          teamService: _teamService,
          onChanged: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  // ============================================================
  // EMPTY / ERROR
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
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
              Icons.person_search_rounded,
              color: Color(0xFF6366F1),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No employees found',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try changing your search or filters.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load team',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _teamService.getAllEmployees();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // ROLE COLOR
  // ============================================================

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.ceo:
        return const Color(0xFF7C3AED);

      case UserRole.cto:
        return const Color(0xFF2563EB);

      case UserRole.admin:
        return const Color(0xFF4F46E5);

      case UserRole.callingExecutive:
        return const Color(0xFF0891B2);

      case UserRole.salesExecutive:
        return const Color(0xFF059669);

      case UserRole.teamMember:
        return const Color(0xFFD97706);
    }
  }
}

// ==================================================================
// EMPLOYEE DETAILS SHEET
// ==================================================================

class _EmployeeDetailsSheet extends StatefulWidget {
  final AppUser employee;
  final TeamService teamService;
  final VoidCallback onChanged;

  const _EmployeeDetailsSheet({
    required this.employee,
    required this.teamService,
    required this.onChanged,
  });

  @override
  State<_EmployeeDetailsSheet> createState() =>
      _EmployeeDetailsSheetState();
}

class _EmployeeDetailsSheetState
    extends State<_EmployeeDetailsSheet> {
  late UserRole _selectedRole;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _selectedRole = widget.employee.role;
    _isActive = widget.employee.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 720,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
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
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildAvatar(employee),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name.isEmpty
                              ? 'Unnamed Employee'
                              : employee.name,
                          style: GoogleFonts.manrope(
                            fontSize: 19,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          employee.email,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w500,
                            color:
                                const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _buildInfoCard(
                title: 'Employee Information',
                children: [
                  _buildInfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Employee ID',
                    value: employee.id,
                  ),
                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: employee.email,
                  ),
                  if (employee.phone != null &&
                      employee.phone!.isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: employee.phone!,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRoleSection(),
              const SizedBox(height: 16),
              _buildStatusSection(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _saving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AppUser employee) {
    if (employee.profileImage != null &&
        employee.profileImage!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          employee.profileImage!,
          width: 62,
          height: 62,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) {
            return _buildInitialAvatar(employee);
          },
        ),
      );
    }

    return _buildInitialAvatar(employee);
  }

  Widget _buildInitialAvatar(AppUser employee) {
    final name = employee.name.trim();

    final initial = name.isEmpty
        ? '?'
        : name.substring(0, 1).toUpperCase();

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(width: 2),
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Role',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Controls what this employee can access.',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<UserRole>(
            value: _selectedRole,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
            ),
            items: UserRole.values.map((role) {
              return DropdownMenuItem<UserRole>(
                value: role,
                child: Text(
                  widget.teamService
                      .roleLabel(role),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedRole = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
              color: _isActive
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isActive
                  ? Icons.check_circle_rounded
                  : Icons.pause_circle_rounded,
              color: _isActive
                  ? const Color(0xFF10B981)
                  : const Color(0xFF6B7280),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Status',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isActive
                      ? 'Employee can access the system.'
                      : 'Employee access is disabled.',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isActive,
            activeColor: const Color(0xFF4F46E5),
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      _saving = true;
    });

    try {
      if (_selectedRole != widget.employee.role) {
       await widget.teamService.updateEmployeeRole(
  userId: widget.employee.id,
  role: _selectedRole,
);
      }

      if (_isActive != widget.employee.isActive) {
        if (_isActive) {
          await widget.teamService.activateEmployee(
            widget.employee.id,
          );
        } else {
          await widget.teamService.deactivateEmployee(
            widget.employee.id,
          );
        }
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            'Employee updated successfully.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}