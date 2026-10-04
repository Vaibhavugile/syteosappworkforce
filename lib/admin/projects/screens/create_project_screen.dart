import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_user.dart';
import '../../../models/project.dart';
import '../../../services/project_service.dart';
import '../../../services/team_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState
    extends State<CreateProjectScreen> {
  final ProjectService _projectService =
      ProjectService.instance;

  final TeamService _teamService =
      TeamService.instance;

  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _clientController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  ProjectPriority _priority =
      ProjectPriority.medium;

  ProjectStatus _status =
      ProjectStatus.planning;

  DateTime? _startDate;
  DateTime? _targetDate;

  String? _projectManagerId;

  final Set<String> _selectedMemberIds =
      <String>{};

  String _selectedColor = '#6366F1';
  String _selectedIcon = 'business';

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _descriptionController.dispose();
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
      body: SafeArea(
        child: StreamBuilder<List<AppUser>>(
          stream: _teamService.watchActiveEmployees(),
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

            final employees =
                snapshot.data ?? [];

            return Form(
              key: _formKey,
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  110,
                ),
                children: [
                  _buildHero(),
                  const SizedBox(height: 20),
                  _buildBasicInformation(),
                  const SizedBox(height: 16),
                  _buildProjectSettings(),
                  const SizedBox(height: 16),
                  _buildTimeline(),
                  const SizedBox(height: 16),
                  _buildManager(employees),
                  const SizedBox(height: 16),
                  _buildTeamMembers(employees),
                  const SizedBox(height: 16),
                  _buildAppearance(),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar:
          _buildBottomBar(),
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
      titleSpacing: 20,
      title: Text(
        'Create Project',
        style: GoogleFonts.manrope(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _colorFromHex(_selectedColor),
            const Color(0xFF7C3AED),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                _colorFromHex(_selectedColor)
                    .withOpacity(0.20),
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
              color: Colors.white.withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Icon(
              _iconFromName(_selectedIcon),
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.trim().isEmpty
                      ? 'New Project'
                      : _nameController.text.trim(),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _clientController.text
                          .trim()
                          .isEmpty
                      ? 'Project workspace'
                      : _clientController.text.trim(),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color:
                        Colors.white.withOpacity(0.80),
                    fontSize: 12,
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

  // ============================================================
  // BASIC INFORMATION
  // ============================================================

  Widget _buildBasicInformation() {
    return _sectionCard(
      title: 'Basic Information',
      subtitle:
          'Define the project and its purpose.',
      children: [
        _label('Project Name', required: true),
        const SizedBox(height: 7),
        _textField(
          controller: _nameController,
          hint: 'e.g. Syteos CRM',
          icon: Icons.folder_outlined,
          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return 'Project name is required';
            }

            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _label('Client'),
        const SizedBox(height: 7),
        _textField(
          controller: _clientController,
          hint: 'Client or company name',
          icon: Icons.business_outlined,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _label('Description'),
        const SizedBox(height: 7),
        _textField(
          controller: _descriptionController,
          hint: 'What is this project about?',
          icon: Icons.notes_rounded,
          maxLines: 5,
        ),
      ],
    );
  }

  // ============================================================
  // PROJECT SETTINGS
  // ============================================================

  Widget _buildProjectSettings() {
    return _sectionCard(
      title: 'Project Settings',
      subtitle:
          'Set the initial project state and priority.',
      children: [
        _label('Status'),
        const SizedBox(height: 7),
        _dropdown<ProjectStatus>(
          value: _status,
          items: ProjectStatus.values,
          labelBuilder: _statusLabel,
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _status = value;
            });
          },
        ),
        const SizedBox(height: 16),
        _label('Priority'),
        const SizedBox(height: 7),
        _dropdown<ProjectPriority>(
          value: _priority,
          items: ProjectPriority.values,
          labelBuilder: _priorityLabel,
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _priority = value;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // TIMELINE
  // ============================================================

  Widget _buildTimeline() {
    return _sectionCard(
      title: 'Timeline',
      subtitle:
          'Set the expected project duration.',
      children: [
        Row(
          children: [
            Expanded(
              child: _dateSelector(
                title: 'Start Date',
                value: _startDate,
                icon: Icons.play_arrow_rounded,
                onTap: () =>
                    _selectDate(isStart: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dateSelector(
                title: 'Target Date',
                value: _targetDate,
                icon: Icons.flag_outlined,
                onTap: () =>
                    _selectDate(isStart: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateSelector({
    required String title,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius:
              BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 19,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color:
                    const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value == null
                  ? 'Select date'
                  : _formatDate(value),
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: value == null
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({
    required bool isStart,
  }) async {
    final initialDate =
        isStart
            ? (_startDate ?? DateTime.now())
            : (_targetDate ??
                _startDate ??
                DateTime.now());

    final firstDate = isStart
        ? DateTime(2020)
        : (_startDate ?? DateTime(2020));

    final picked =
        await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.light(
              primary: Color(0xFF4F46E5),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = picked;

        if (_targetDate != null &&
            _targetDate!.isBefore(picked)) {
          _targetDate = picked;
        }
      } else {
        _targetDate = picked;
      }
    });
  }

  // ============================================================
  // MANAGER
  // ============================================================

  Widget _buildManager(
    List<AppUser> employees,
  ) {
    final managers = employees.where(
      (employee) =>
          employee.role == UserRole.ceo ||
          employee.role == UserRole.cto ||
          employee.role == UserRole.admin ||
          employee.role == UserRole.teamMember,
    ).toList();

    return _sectionCard(
      title: 'Project Manager',
      subtitle:
          'Choose who will be responsible for this project.',
      children: [
        DropdownButtonFormField<String?>(
          value: _projectManagerId,
          isExpanded: true,
          decoration: _inputDecoration(
            icon: Icons.manage_accounts_outlined,
            hint: 'Select project manager',
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'No manager assigned',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      const Color(0xFF9CA3AF),
                ),
              ),
            ),
            ...managers.map(
              (employee) {
                return DropdownMenuItem<String?>(
                  value: employee.id,
                  child: Text(
                    employee.name.isEmpty
                        ? employee.email
                        : employee.name,
                    overflow:
                        TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color:
                          const Color(0xFF374151),
                    ),
                  ),
                );
              },
            ),
          ],
          onChanged: (value) {
            setState(() {
              _projectManagerId = value;

              if (value != null) {
                _selectedMemberIds.add(value);
              }
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // TEAM MEMBERS
  // ============================================================

  Widget _buildTeamMembers(
    List<AppUser> employees,
  ) {
    return _sectionCard(
      title: 'Project Team',
      subtitle:
          'Select employees who will work on this project.',
      children: [
        if (_selectedMemberIds.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children:
                  _selectedMemberIds.map(
                (uid) {
                  final employee =
                      _findEmployee(
                    employees,
                    uid,
                  );

                  return _memberChip(
                    employee?.name ??
                        'Selected member',
                    uid,
                  );
                },
              ).toList(),
            ),
          ),
        Container(
          constraints: const BoxConstraints(
            maxHeight: 300,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: employees.isEmpty
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
                    child: Text(
                      'No active employees available.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color:
                            const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.all(8),
                  itemCount: employees.length,
                  separatorBuilder:
                      (_, __) =>
                          const Divider(
                    height: 1,
                    color:
                        Color(0xFFE5E7EB),
                  ),
                  itemBuilder:
                      (context, index) {
                    final employee =
                        employees[index];

                    final selected =
                        _selectedMemberIds
                            .contains(
                      employee.id,
                    );

                    return _employeeSelector(
                      employee,
                      selected,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _employeeSelector(
    AppUser employee,
    bool selected,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(12),
      onTap: () {
        setState(() {
          if (selected) {
            // Keep manager in the team.
            if (employee.id ==
                _projectManagerId) {
              return;
            }

            _selectedMemberIds
                .remove(employee.id);
          } else {
            _selectedMemberIds
                .add(employee.id);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        child: Row(
          children: [
            _employeeAvatar(employee),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name.isEmpty
                        ? employee.email
                        : employee.name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color:
                          const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _roleLabel(employee.role),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color:
                          const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF4F46E5)
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberChip(
    String name,
    String uid,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color:
                  const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 5),
          InkWell(
            onTap: () {
              if (uid == _projectManagerId) {
                return;
              }

              setState(() {
                _selectedMemberIds
                    .remove(uid);
              });
            },
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APPEARANCE
  // ============================================================

  Widget _buildAppearance() {
    return _sectionCard(
      title: 'Project Appearance',
      subtitle:
          'Choose a color and icon for quick identification.',
      children: [
        _label('Color'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            '#6366F1',
            '#7C3AED',
            '#2563EB',
            '#0891B2',
            '#059669',
            '#D97706',
            '#DC2626',
            '#DB2777',
          ].map(
            (color) {
              return _colorOption(color);
            },
          ).toList(),
        ),
        const SizedBox(height: 18),
        _label('Icon'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            'business',
            'code',
            'mobile',
            'web',
            'design',
            'marketing',
            'cloud',
          ].map(
            (icon) {
              return _iconOption(icon);
            },
          ).toList(),
        ),
      ],
    );
  }

  Widget _colorOption(String color) {
    final selected =
        _selectedColor == color;

    final parsed = _colorFromHex(color);

    return InkWell(
      borderRadius:
          BorderRadius.circular(13),
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: parsed,
          borderRadius:
              BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: parsed.withOpacity(0.35),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: selected
            ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 21,
              )
            : null,
      ),
    );
  }

  Widget _iconOption(String icon) {
    final selected =
        _selectedIcon == icon;

    return InkWell(
      borderRadius:
          BorderRadius.circular(13),
      onTap: () {
        setState(() {
          _selectedIcon = icon;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEEF2FF)
              : const Color(0xFFF9FAFB),
          borderRadius:
              BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? const Color(0xFFC7D2FE)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(
          _iconFromName(icon),
          size: 20,
          color: selected
              ? const Color(0xFF4F46E5)
              : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed:
                _saving ? null : _createProject,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  const Color(0xFFA5B4FC),
              elevation: 0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Create Project',
                        style:
                            GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w800,
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
  // CREATE
  // ============================================================

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate != null &&
        _targetDate != null &&
        _targetDate!.isBefore(_startDate!)) {
      _showSnack(
        'Target date cannot be before start date.',
        error: true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final projectId =
          await _projectService.createProject(
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim(),
        clientName:
            _clientController.text.trim(),
        projectManagerId:
            _projectManagerId,
        memberIds:
            _selectedMemberIds.toList(),
        status: _status,
        priority: _priority,
        startDate: _startDate,
        targetDate: _targetDate,
        color: _selectedColor,
        icon: _selectedIcon,
      );

      if (!mounted) return;

      Navigator.of(context).pop(projectId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              const Color(0xFF111827),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          content: Text(
            'Project created successfully.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color:
                  const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color:
                  const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color:
            const Color(0xFF111827),
      ),
      decoration:
          _inputDecoration(
        icon: icon,
        hint: hint,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required IconData icon,
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color:
            const Color(0xFF9CA3AF),
      ),
      prefixIcon: Icon(
        icon,
        size: 19,
        color:
            const Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor:
          const Color(0xFFF9FAFB),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Color(0xFF6366F1),
          width: 1.4,
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Color(0xFFEF4444),
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.4,
        ),
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: _inputDecoration(
        icon: Icons.tune_rounded,
        hint: 'Select',
      ),
      items: items.map(
        (item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              labelBuilder(item),
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color:
                    const Color(0xFF374151),
              ),
            ),
          );
        },
      ).toList(),
      onChanged: onChanged,
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _label(
    String text, {
    bool required = false,
  }) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color:
                const Color(0xFF374151),
          ),
        ),
        if (required)
          Text(
            ' *',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color:
                  const Color(0xFFEF4444),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color:
                  Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load team',
              style:
                  GoogleFonts.manrope(
                fontSize: 17,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.manrope(
                fontSize: 12,
                color:
                    const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  AppUser? _findEmployee(
    List<AppUser> employees,
    String uid,
  ) {
    for (final employee in employees) {
      if (employee.id == uid) {
        return employee;
      }
    }

    return null;
  }

  Widget _employeeAvatar(
    AppUser employee,
  ) {
    if (employee.profileImage != null &&
        employee.profileImage!.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(12),
        child: Image.network(
          employee.profileImage!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) =>
                  _initialAvatar(employee),
        ),
      );
    }

    return _initialAvatar(employee);
  }

  Widget _initialAvatar(
    AppUser employee,
  ) {
    final name =
        employee.name.trim();

    final initial = name.isEmpty
        ? '?'
        : name
            .substring(0, 1)
            .toUpperCase();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      alignment:
          Alignment.center,
      child: Text(
        initial,
        style:
            GoogleFonts.manrope(
          fontSize: 14,
          fontWeight:
              FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.ceo:
        return 'CEO';
      case UserRole.cto:
        return 'CTO';
      case UserRole.admin:
        return 'Admin';
      case UserRole.callingExecutive:
        return 'Calling Executive';
      case UserRole.salesExecutive:
        return 'Sales Executive';
      case UserRole.teamMember:
        return 'Team Member';
    }
  }

  String _statusLabel(
    ProjectStatus status,
  ) {
    switch (status) {
      case ProjectStatus.draft:
        return 'Draft';
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.archived:
        return 'Archived';
    }
  }

  String _priorityLabel(
    ProjectPriority priority,
  ) {
    switch (priority) {
      case ProjectPriority.low:
        return 'Low';
      case ProjectPriority.medium:
        return 'Medium';
      case ProjectPriority.high:
        return 'High';
      case ProjectPriority.critical:
        return 'Critical';
    }
  }

  IconData _iconFromName(
    String icon,
  ) {
    switch (icon) {
      case 'code':
        return Icons.code_rounded;
      case 'mobile':
        return Icons.phone_android_rounded;
      case 'web':
        return Icons.language_rounded;
      case 'design':
        return Icons.design_services_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'business':
      default:
        return Icons.business_center_rounded;
    }
  }

  Color _colorFromHex(
    String value,
  ) {
    final hex =
        value.replaceFirst('#', '');

    if (hex.length == 6) {
      final parsed =
          int.tryParse(
        'FF$hex',
        radix: 16,
      );

      if (parsed != null) {
        return Color(parsed);
      }
    }

    return const Color(0xFF6366F1);
  }

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _showSnack(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        backgroundColor: error
            ? const Color(0xFFDC2626)
            : const Color(0xFF111827),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
        content: Text(
          message,
          style:
              GoogleFonts.manrope(
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}