import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../models/app_user.dart';
import '../../../models/milestone.dart';
import '../../../models/project.dart';
import '../../../models/task.dart';
import '../../../services/milestone_service.dart';
import '../../../services/project_service.dart';
import '../../../services/task_service.dart';
import '../../../services/team_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final String? projectId;

  const CreateTaskScreen({
    super.key,
    this.projectId,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedHoursController = TextEditingController();

  final TaskService _taskService = TaskService.instance;
  final ProjectService _projectService = ProjectService.instance;
  final TeamService _teamService = TeamService.instance;
  final MilestoneService _milestoneService = MilestoneService.instance;

  Project? _selectedProject;
  AppUser? _selectedEmployee;
  Milestone? _selectedMilestone;
  Task? _selectedParentTask;

  TaskPriority _priority = TaskPriority.medium;

  DateTime? _startDate;
  DateTime? _dueDate;

  List<Project> _projects = [];
  List<AppUser> _employees = [];
  List<Milestone> _milestones = [];
  List<Task> _parentTasks = [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedHoursController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final loadedProjects = await _projectService.getAllProjects();
      final employees = await _teamService.getActiveEmployees();

      // De-duplicate projects by ID. DropdownButton requires the selected
      // value to be the exact object represented in its items list.
      final projectById = <String, Project>{};
      for (final project in loadedProjects) {
        if (project.projectId.trim().isNotEmpty) {
          projectById[project.projectId] = project;
        }
      }
      final projects = projectById.values.toList();

      Project? selectedProject;

      final requestedProjectId = widget.projectId?.trim();
      if (requestedProjectId != null && requestedProjectId.isNotEmpty) {
        for (final project in projects) {
          if (project.projectId == requestedProjectId) {
            selectedProject = project;
            break;
          }
        }
      }

      selectedProject ??= projects.isNotEmpty ? projects.first : null;

      if (!mounted) return;

      setState(() {
        _projects = projects;
        _employees = employees;
        _selectedProject = selectedProject;
        _loading = false;
      });

      if (selectedProject != null) {
        await _loadProjectDependencies(selectedProject.projectId);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError('Unable to load task creation data.');
    }
  }

  Future<void> _loadProjectDependencies(String projectId) async {
    try {
      final milestones =
          await _milestoneService.getProjectMilestones(projectId);
      final tasks = await _taskService.getProjectTasks(projectId);

      if (!mounted) return;

      setState(() {
        _milestones = milestones;
        _parentTasks = tasks
            .where((task) => task.status != TaskStatus.cancelled)
            .toList();

        if (_selectedMilestone != null &&
            !_milestones.any(
              (item) => item.milestoneId == _selectedMilestone!.milestoneId,
            )) {
          _selectedMilestone = null;
        }

        if (_selectedParentTask != null &&
            !_parentTasks.any(
              (item) => item.taskId == _selectedParentTask!.taskId,
            )) {
          _selectedParentTask = null;
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _milestones = [];
        _parentTasks = [];
        _selectedMilestone = null;
        _selectedParentTask = null;
      });
    }
  }

  Future<void> _selectProject(Project? project) async {
    if (project == null) return;

    // Normalize the selected value to the exact instance contained in
    // _projects, preventing DropdownButton identity assertions.
    final normalizedProject = _projectById(project.projectId);

    if (normalizedProject == null) return;

    setState(() {
      _selectedProject = normalizedProject;
      _selectedMilestone = null;
      _selectedParentTask = null;
      _milestones = [];
      _parentTasks = [];
    });

    await _loadProjectDependencies(project.projectId);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: _datePickerBuilder,
    );

    if (picked == null) return;

    setState(() {
      _startDate = picked;

      if (_dueDate != null && _dueDate!.isBefore(picked)) {
        _dueDate = picked;
      }
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final firstDate = _startDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      builder: _datePickerBuilder,
    );

    if (picked == null) return;

    setState(() {
      _dueDate = picked;
    });
  }

  Widget Function(BuildContext, Widget?) get _datePickerBuilder {
    return (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF5B5CE2),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF17172B),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
          ),
        ),
        child: child!,
      );
    };
  }

  Future<void> _createTask() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedProject == null) {
      _showError('Please select a project.');
      return;
    }

    if (_startDate != null &&
        _dueDate != null &&
        _dueDate!.isBefore(_startDate!)) {
      _showError('Due date cannot be before the start date.');
      return;
    }

    double? estimatedHours;
    final hoursText = _estimatedHoursController.text.trim();

    if (hoursText.isNotEmpty) {
      estimatedHours = double.tryParse(hoursText);

      if (estimatedHours == null || estimatedHours < 0) {
        _showError('Please enter a valid estimated hours value.');
        return;
      }
    }

    setState(() {
      _saving = true;
    });

    try {
      final task = Task(
        taskId: '',
        projectId: _selectedProject!.projectId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: _taskService.currentUserUid,
        assignedTo: _selectedEmployee?.id,
        status: TaskStatus.todo,
        priority: _priority,
        startDate: _startDate,
        dueDate: _dueDate,
        completionPercentage: 0,
        estimatedHours: estimatedHours,
        milestoneId: _selectedMilestone?.milestoneId,
        parentTaskId: _selectedParentTask?.taskId,
        watcherIds: const [],
        attachmentIds: const [],
      );

      await _taskService.createTask(
        projectId: task.projectId,
        title: task.title,
        description: task.description,
        assignedTo: task.assignedTo,
        status: task.status,
        priority: task.priority,
        startDate: task.startDate,
        dueDate: task.dueDate,
        completionPercentage: task.completionPercentage,
        estimatedHours: task.estimatedHours,
        milestoneId: task.milestoneId,
        parentTaskId: task.parentTaskId,
        watcherIds: task.watcherIds,
      );

      if (!mounted) return;

      _showSuccess();

      await Future.delayed(const Duration(milliseconds: 450));

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showError('Unable to create task. Please try again.');
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        backgroundColor: const Color(0xFF17172B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF4ADE80),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Task created successfully',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        backgroundColor: const Color(0xFF17172B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFF87171),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F7FB),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF17172B),
          ),
        ),
        title: Text(
          'Create Task',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF17172B),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5B5CE2),
              ),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          120,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildBasicSection(),
                            const SizedBox(height: 18),
                            _buildAssignmentSection(),
                            const SizedBox(height: 18),
                            _buildScheduleSection(),
                            const SizedBox(height: 18),
                            _buildAdvancedSection(),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomBar(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5B5CE2),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B5CE2).withOpacity(.18),
            blurRadius: 28,
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
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(.16),
              ),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
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
                  'Create a new task',
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Assign work, set priorities and define deadlines.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Colors.white.withOpacity(.82),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSection() {
    return _sectionCard(
      title: 'Task Details',
      subtitle: 'Define what needs to be completed.',
      icon: Icons.description_outlined,
      children: [
        _buildLabel('Task Title', required: true),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _titleController,
          hint: 'e.g. Build login screen',
          prefixIcon: Icons.title_rounded,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Task title is required';
            }

            if (value.trim().length < 3) {
              return 'Enter at least 3 characters';
            }

            return null;
          },
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 18),
        _buildLabel('Description'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _descriptionController,
          hint: 'Describe the task, requirements or expected outcome...',
          prefixIcon: Icons.notes_rounded,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 18),
        _buildLabel('Priority'),
        const SizedBox(height: 10),
        _buildPrioritySelector(),
      ],
    );
  }

  Widget _buildAssignmentSection() {
    return _sectionCard(
      title: 'Assignment',
      subtitle: 'Choose the project and responsible employee.',
      icon: Icons.group_work_outlined,
      children: [
        _buildLabel('Project', required: true),
        const SizedBox(height: 8),
        _buildProjectDropdown(),
        const SizedBox(height: 18),
        _buildLabel('Assign To'),
        const SizedBox(height: 8),
        _buildEmployeeDropdown(),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return _sectionCard(
      title: 'Schedule',
      subtitle: 'Set the expected execution timeline.',
      icon: Icons.calendar_month_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Start Date',
                date: _startDate,
                icon: Icons.play_circle_outline_rounded,
                onTap: _pickStartDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                label: 'Due Date',
                date: _dueDate,
                icon: Icons.event_available_outlined,
                onTap: _pickDueDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildLabel('Estimated Hours'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _estimatedHoursController,
          hint: 'e.g. 8',
          prefixIcon: Icons.schedule_rounded,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'^\d*\.?\d{0,2}'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return _sectionCard(
      title: 'Advanced',
      subtitle: 'Optional project structure and dependencies.',
      icon: Icons.tune_rounded,
      children: [
        _buildLabel('Milestone'),
        const SizedBox(height: 8),
        _buildMilestoneDropdown(),
        const SizedBox(height: 18),
        _buildLabel('Parent Task'),
        const SizedBox(height: 8),
        _buildParentTaskDropdown(),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TaskPriority.values.map((priority) {
        final selected = _priority == priority;
        final color = _priorityColor(priority);

        return GestureDetector(
          onTap: _saving
              ? null
              : () {
                  setState(() {
                    _priority = priority;
                  });
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? color.withOpacity(.11)
                  : const Color(0xFFF7F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? color
                    : const Color(0xFFE8E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _priorityLabel(priority),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? color
                        : const Color(0xFF55556B),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Project? _projectById(String projectId) {
    for (final project in _projects) {
      if (project.projectId == projectId) return project;
    }
    return null;
  }

  Widget _buildProjectDropdown() {
    // Always derive the value from the same list used by the dropdown items.
    final dropdownValue = _selectedProject == null
        ? null
        : _projectById(_selectedProject!.projectId);

    return _dropdownContainer(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Project>(
          value: dropdownValue,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF77778A),
          ),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          hint: Text(
            _projects.isEmpty ? 'No projects available' : 'Select a project',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9292A4),
              fontWeight: FontWeight.w500,
            ),
          ),
          items: _projects.map((project) {
            return DropdownMenuItem<Project>(
              value: project,
              child: Row(
                children: [
                  _projectIcon(project),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      project.name,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF24243A),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: _saving ? null : _selectProject,
        ),
      ),
    );
  }

  Widget _buildEmployeeDropdown() {
    return _dropdownContainer(
      child: DropdownButton<AppUser?>(
        value: _selectedEmployee,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF77778A),
        ),
        hint: Text(
          'Select an employee',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF9292A4),
            fontWeight: FontWeight.w500,
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        dropdownColor: Colors.white,
        items: [
          DropdownMenuItem<AppUser?>(
            value: null,
            child: Text(
              'Unassigned',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF77778A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._employees.map(
            (employee) => DropdownMenuItem<AppUser?>(
              value: employee,
              child: Row(
                children: [
                  _employeeAvatar(employee),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          employee.name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF24243A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          employee.roleLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF9292A4),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        onChanged: _saving
            ? null
            : (employee) {
                setState(() {
                  _selectedEmployee = employee;
                });
              },
      ),
    );
  }

  Widget _buildMilestoneDropdown() {
    if (_selectedProject == null) {
      return _disabledField(
        'Select a project first',
        Icons.flag_outlined,
      );
    }

    if (_milestones.isEmpty) {
      return _disabledField(
        'No milestones available',
        Icons.flag_outlined,
      );
    }

    return _dropdownContainer(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Milestone?>(
          value: _selectedMilestone == null
              ? null
              : _milestones.cast<Milestone?>().firstWhere(
                    (item) => item?.milestoneId == _selectedMilestone!.milestoneId,
                    orElse: () => null,
                  ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF77778A),
          ),
          hint: Text(
            'Select a milestone',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9292A4),
              fontWeight: FontWeight.w500,
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem<Milestone?>(
              value: null,
              child: Text(
                'No milestone',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF77778A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ..._milestones.map(
              (milestone) => DropdownMenuItem<Milestone?>(
                value: milestone,
                child: Row(
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 18,
                      color: Color(0xFF5B5CE2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        milestone.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF24243A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: _saving
              ? null
              : (milestone) {
                  setState(() {
                    _selectedMilestone = milestone;
                  });
                },
        ),
      ),
    );
  }

  Widget _buildParentTaskDropdown() {
    if (_selectedProject == null) {
      return _disabledField(
        'Select a project first',
        Icons.account_tree_outlined,
      );
    }

    if (_parentTasks.isEmpty) {
      return _disabledField(
        'No parent tasks available',
        Icons.account_tree_outlined,
      );
    }

    return _dropdownContainer(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Task?>(
          value: _selectedParentTask == null
              ? null
              : _parentTasks.cast<Task?>().firstWhere(
                    (item) => item?.taskId == _selectedParentTask!.taskId,
                    orElse: () => null,
                  ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF77778A),
          ),
          hint: Text(
            'Select a parent task',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9292A4),
              fontWeight: FontWeight.w500,
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem<Task?>(
              value: null,
              child: Text(
                'No parent task',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF77778A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ..._parentTasks.map(
              (task) => DropdownMenuItem<Task?>(
                value: task,
                child: Row(
                  children: [
                    const Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 18,
                      color: Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task.title,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF24243A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: _saving
              ? null
              : (task) {
                  setState(() {
                    _selectedParentTask = task;
                  });
                },
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _saving ? null : onTap,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE8E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: const Color(0xFF68687A),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    date == null
                        ? 'Select'
                        : DateFormat('dd MMM yyyy').format(date),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: date == null
                          ? const Color(0xFF9A9AAC)
                          : const Color(0xFF28283D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: const Color(0xFF24243A),
        fontWeight: FontWeight.w600,
      ),
      cursorColor: const Color(0xFF5B5CE2),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 12.5,
          color: const Color(0xFF9A9AAC),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: 14,
            right: 8,
          ),
          child: Icon(
            prefixIcon,
            size: 19,
            color: const Color(0xFF77778A),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 45,
        ),
        filled: true,
        fillColor: const Color(0xFFF9F9FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE8E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE8E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF5B5CE2),
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(
    String text, {
    bool required = false,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF38384D),
            ),
          ),
          if (required)
            TextSpan(
              text: ' *',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFEF4444),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEAEAF1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B5CE2).withOpacity(.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF5B5CE2),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF222238),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF9292A4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _dropdownContainer({
    required Widget child,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8E8F0),
        ),
      ),
      child: child,
    );
  }

  Widget _disabledField(
    String text,
    IconData icon,
  ) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: const Color(0xFFAAAAB8),
          ),
          const SizedBox(width: 9),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF9A9AAC),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectIcon(Project project) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF5B5CE2).withOpacity(.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        _projectIconData(project.icon),
        size: 17,
        color: const Color(0xFF5B5CE2),
      ),
    );
  }

  IconData _projectIconData(String? icon) {
    switch (icon) {
      case 'code':
        return Icons.code_rounded;
      case 'web':
        return Icons.language_rounded;
      case 'mobile':
        return Icons.phone_android_rounded;
      case 'design':
        return Icons.palette_outlined;
      case 'marketing':
        return Icons.campaign_outlined;
      case 'sales':
        return Icons.trending_up_rounded;
      case 'support':
        return Icons.support_agent_rounded;
      case 'finance':
        return Icons.account_balance_outlined;
      default:
        return Icons.folder_rounded;
    }
  }

  Widget _employeeAvatar(AppUser employee) {
    final initials = _initials(employee.name);

    if ((employee.profileImage ?? '').trim().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          employee.profileImage!,
          width: 34,
          height: 34,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _avatarFallback(initials);
          },
        ),
      );
    }

    return _avatarFallback(initials);
  }

  Widget _avatarFallback(String initials) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5B5CE2),
            Color(0xFF8B5CF6),
          ],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _saving ? null : _createTask,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF5B5CE2),
            disabledBackgroundColor: const Color(0xFFB8B8D0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_task_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'Create Task',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return const Color(0xFF64748B);
      case TaskPriority.medium:
        return const Color(0xFF2563EB);
      case TaskPriority.high:
        return const Color(0xFFF59E0B);
      case TaskPriority.urgent:
        return const Color(0xFFEF4444);
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(
        0,
        value.length >= 2 ? 2 : 1,
      ).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
