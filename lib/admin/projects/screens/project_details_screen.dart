import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/app_user.dart';
import '../../../models/milestone.dart';
import '../../../models/project.dart';
import '../../../models/task.dart';
import '../../../models/task_activity.dart';
import '../../../services/milestone_service.dart';
import '../../../services/project_service.dart';
import '../../../services/task_service.dart';
import '../../../services/team_service.dart';
import 'create_task_screen.dart';
import 'task_details_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  final ProjectService _projectService = ProjectService.instance;
  final TaskService _taskService = TaskService.instance;
  final MilestoneService _milestoneService = MilestoneService.instance;
  final TeamService _teamService = TeamService.instance;

  late final TabController _tabController;

  Project? _project;
  bool _isActionLoading = false;

  final Color _primary = const Color(0xFF6366F1);
  final Color _primaryDark = const Color(0xFF4F46E5);
  final Color _background = const Color(0xFFF7F8FC);
  final Color _text = const Color(0xFF171923);
  final Color _muted = const Color(0xFF73778A);
  final Color _border = const Color(0xFFE7E9F2);

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 5,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Not available';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.draft:
        return const Color(0xFF64748B);
      case ProjectStatus.planning:
        return const Color(0xFF8B5CF6);
      case ProjectStatus.active:
        return const Color(0xFF10B981);
      case ProjectStatus.onHold:
        return const Color(0xFFF59E0B);
      case ProjectStatus.completed:
        return const Color(0xFF2563EB);
      case ProjectStatus.archived:
        return const Color(0xFF94A3B8);
    }
  }

  Color _priorityColor(ProjectPriority priority) {
    switch (priority) {
      case ProjectPriority.low:
        return const Color(0xFF64748B);
      case ProjectPriority.medium:
        return const Color(0xFF2563EB);
      case ProjectPriority.high:
        return const Color(0xFFF59E0B);
      case ProjectPriority.critical:
        return const Color(0xFFEF4444);
    }
  }

  String _statusLabel(ProjectStatus status) {
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

  String _priorityLabel(ProjectPriority priority) {
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

  String _taskStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return 'Backlog';
      case TaskStatus.todo:
        return 'Todo';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.inReview:
        return 'In Review';
      case TaskStatus.changesRequested:
        return 'Changes Requested';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.blocked:
        return 'Blocked';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _taskStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return const Color(0xFF64748B);
      case TaskStatus.todo:
        return const Color(0xFF6366F1);
      case TaskStatus.inProgress:
        return const Color(0xFF2563EB);
      case TaskStatus.inReview:
        return const Color(0xFF8B5CF6);
      case TaskStatus.changesRequested:
        return const Color(0xFFF59E0B);
      case TaskStatus.completed:
        return const Color(0xFF10B981);
      case TaskStatus.blocked:
        return const Color(0xFFEF4444);
      case TaskStatus.cancelled:
        return const Color(0xFF94A3B8);
    }
  }

  String _milestoneStatusLabel(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.upcoming:
        return 'Upcoming';
      case MilestoneStatus.inProgress:
        return 'In Progress';
      case MilestoneStatus.completed:
        return 'Completed';
      case MilestoneStatus.delayed:
        return 'Delayed';
      case MilestoneStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _milestoneStatusColor(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.upcoming:
        return const Color(0xFF64748B);
      case MilestoneStatus.inProgress:
        return const Color(0xFF6366F1);
      case MilestoneStatus.completed:
        return const Color(0xFF10B981);
      case MilestoneStatus.delayed:
        return const Color(0xFFF59E0B);
      case MilestoneStatus.cancelled:
        return const Color(0xFF94A3B8);
    }
  }

  String _activityTypeLabel(TaskActivityType type) {
    switch (type) {
      case TaskActivityType.created:
        return 'Task created';
      case TaskActivityType.assigned:
        return 'Task assigned';
      case TaskActivityType.reassigned:
        return 'Task reassigned';
      case TaskActivityType.statusChanged:
        return 'Status changed';
      case TaskActivityType.priorityChanged:
        return 'Priority changed';
      case TaskActivityType.dueDateChanged:
        return 'Due date changed';
      case TaskActivityType.descriptionUpdated:
        return 'Description updated';
      case TaskActivityType.commentAdded:
        return 'Comment added';
      case TaskActivityType.attachmentAdded:
        return 'Attachment added';
      case TaskActivityType.submittedForReview:
        return 'Submitted for review';
      case TaskActivityType.changesRequested:
        return 'Changes requested';
      case TaskActivityType.approved:
        return 'Approved';
      case TaskActivityType.completed:
        return 'Task completed';
      case TaskActivityType.blocked:
        return 'Task blocked';
      case TaskActivityType.unblocked:
        return 'Task unblocked';
      case TaskActivityType.reopened:
        return 'Task reopened';
    }
  }

  Future<void> _runProjectAction(
    String action,
    Future<void> Function() callback,
  ) async {
    if (_isActionLoading) return;

    setState(() {
      _isActionLoading = true;
    });

    try {
      await callback();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF171923),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text('$action successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            'Unable to $action. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  void _showProjectActions(Project project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DAE5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Project Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (project.status != ProjectStatus.active)
                  _actionTile(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Start Project',
                    subtitle: 'Move project to active',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      _runProjectAction(
                        'start project',
                        () => _projectService.startProject(
                          project.projectId,
                        ),
                      );
                    },
                  ),
                if (project.status == ProjectStatus.active)
                  _actionTile(
                    icon: Icons.pause_circle_outline_rounded,
                    title: 'Put On Hold',
                    subtitle: 'Temporarily pause this project',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      _runProjectAction(
                        'put project on hold',
                        () => _projectService.holdProject(
                          project.projectId,
                        ),
                      );
                    },
                  ),
                if (project.status != ProjectStatus.completed)
                  _actionTile(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Complete Project',
                    subtitle: 'Mark this project as completed',
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.pop(context);
                      _runProjectAction(
                        'complete project',
                        () => _projectService.completeProject(
                          project.projectId,
                        ),
                      );
                    },
                  ),
                if (project.status != ProjectStatus.archived)
                  _actionTile(
                    icon: Icons.archive_outlined,
                    title: 'Archive Project',
                    subtitle: 'Remove it from active project lists',
                    color: const Color(0xFF64748B),
                    onTap: () {
                      Navigator.pop(context);
                      _runProjectAction(
                        'archive project',
                        () => _projectService.archiveProject(
                          project.projectId,
                        ),
                      );
                    },
                  ),
                if (project.status == ProjectStatus.archived)
                  _actionTile(
                    icon: Icons.restore_rounded,
                    title: 'Reopen Project',
                    subtitle: 'Move project back to planning',
                    color: _primary,
                    onTap: () {
                      Navigator.pop(context);
                      _runProjectAction(
                        'reopen project',
                        () => _projectService.reopenProject(
                          project.projectId,
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

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF7A7E91),
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF9A9EAD),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: StreamBuilder<Project?>(
        stream: _projectService.watchProject(widget.projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _errorState();
          }

          final project = snapshot.data;

          if (project == null) {
            return _notFoundState();
          }

          _project = project;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: innerBoxIsScrolled ? 1 : 0,
                  pinned: true,
                  titleSpacing: 18,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  title: Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Project actions',
                      onPressed: _isActionLoading
                          ? null
                          : () => _showProjectActions(project),
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(58),
                    child: Container(
                      height: 58,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: _border,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        indicatorColor: _primary,
                        indicatorWeight: 3,
                        labelColor: _primary,
                        unselectedLabelColor: _muted,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Tasks'),
                          Tab(text: 'Milestones'),
                          Tab(text: 'Team'),
                          Tab(text: 'Activity'),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOverview(project),
                _buildTasks(project),
                _buildMilestones(project),
                _buildTeam(project),
                _buildActivity(project),
              ],
            ),
          );
        },
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          if (_tabController.index != 1) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: _isActionLoading ? null : _openCreateTask,
            icon: const Icon(
              Icons.add_task_rounded,
            ),
            label: const Text(
              'New Task',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateTask() async {
    final project = _project;

    if (project == null) {
      return;
    }

    final created = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(
          projectId: project.projectId,
        ),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      _tabController.animateTo(1);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF171923),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Text(
            'Task created successfully',
          ),
        ),
      );
    }
  }

  Widget _buildOverview(Project project) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      children: [
        _buildProjectHero(project),
        const SizedBox(height: 18),
        _buildProgressCard(project),
        const SizedBox(height: 18),
        _buildStatsGrid(project),
        const SizedBox(height: 18),
        _buildProjectInformation(project),
        const SizedBox(height: 18),
        _buildTimelineCard(project),
        const SizedBox(height: 18),
        _buildOverviewTasks(project),
      ],
    );
  }

  Widget _buildProjectHero(Project project) {
    final statusColor = _statusColor(project.status);
    final priorityColor = _priorityColor(project.priority);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryDark,
            _primary,
            const Color(0xFF818CF8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(.20),
            blurRadius: 30,
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.16),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  _projectIcon(project.icon),
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const Spacer(),
              _heroBadge(
                _statusLabel(project.status),
                statusColor,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            project.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          if ((project.clientName ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.business_outlined,
                  size: 15,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  project.clientName!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              _heroInfo(
                Icons.flag_outlined,
                _priorityLabel(project.priority),
              ),
              const SizedBox(width: 18),
              _heroInfo(
                Icons.people_outline_rounded,
                '${project.memberIds.length} members',
              ),
              const SizedBox(width: 18),
              _heroInfo(
                Icons.event_outlined,
                _formatDate(project.targetDate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroInfo(IconData icon, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: Colors.white70,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Project project) {
    final progress = project.progress.clamp(0.0, 100.0);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Project Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFE9EAF3),
              valueColor: AlwaysStoppedAnimation<Color>(
                _primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            progress >= 100
                ? 'Project completed'
                : '${progress.toStringAsFixed(0)}% of planned work completed',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Project project) {
    return StreamBuilder<List<Task>>(
      stream: _taskService.watchProjectTasks(project.projectId),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];

        final completed = tasks
            .where((task) => task.status == TaskStatus.completed)
            .length;

        final inProgress = tasks
            .where((task) => task.status == TaskStatus.inProgress)
            .length;

        final overdue = tasks.where((task) {
          if (task.dueDate == null) return false;
          if (task.status == TaskStatus.completed) return false;
          return task.dueDate!.isBefore(DateTime.now());
        }).length;

        return Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.task_alt_rounded,
                value: '${tasks.length}',
                label: 'Total Tasks',
                color: _primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                icon: Icons.check_circle_outline_rounded,
                value: '$completed',
                label: 'Completed',
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                icon: Icons.timelapse_rounded,
                value: '$inProgress',
                label: 'In Progress',
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                icon: Icons.warning_amber_rounded,
                value: '$overdue',
                label: 'Overdue',
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInformation(Project project) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Project Information',
            Icons.info_outline_rounded,
          ),
          const SizedBox(height: 16),
          if ((project.description ?? '').trim().isNotEmpty)
            _infoBlock(
              'Description',
              project.description!.trim(),
            ),
          if ((project.clientName ?? '').trim().isNotEmpty)
            _infoRow(
              Icons.business_outlined,
              'Client',
              project.clientName!,
            ),
          _infoRow(
            Icons.flag_outlined,
            'Priority',
            _priorityLabel(project.priority),
            valueColor: _priorityColor(project.priority),
          ),
          _infoRow(
            Icons.circle_outlined,
            'Status',
            _statusLabel(project.status),
            valueColor: _statusColor(project.status),
          ),
          _infoRow(
            Icons.calendar_today_outlined,
            'Start Date',
            _formatDate(project.startDate),
          ),
          _infoRow(
            Icons.event_available_outlined,
            'Target Date',
            _formatDate(project.targetDate),
          ),
          _infoRow(
            Icons.people_outline_rounded,
            'Team Size',
            '${project.memberIds.length} members',
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: _text,
              height: 1.45,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F8),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 17,
              color: _muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? _text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(Project project) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Project Timeline',
            Icons.timeline_rounded,
          ),
          const SizedBox(height: 18),
          _timelineRow(
            icon: Icons.flag_outlined,
            title: 'Project Created',
            date: project.createdAt,
            color: _primary,
            isLast: project.startDate == null &&
                project.targetDate == null &&
                project.completedAt == null,
          ),
          if (project.startDate != null)
            _timelineRow(
              icon: Icons.play_circle_outline_rounded,
              title: 'Project Start',
              date: project.startDate,
              color: const Color(0xFF10B981),
              isLast: project.targetDate == null &&
                  project.completedAt == null,
            ),
          if (project.targetDate != null)
            _timelineRow(
              icon: Icons.event_outlined,
              title: 'Target Date',
              date: project.targetDate,
              color: const Color(0xFFF59E0B),
              isLast: project.completedAt == null,
            ),
          if (project.completedAt != null)
            _timelineRow(
              icon: Icons.check_circle_outline_rounded,
              title: 'Completed',
              date: project.completedAt,
              color: const Color(0xFF2563EB),
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _timelineRow({
    required IconData icon,
    required String title,
    required DateTime? date,
    required Color color,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: color,
                ),
              ),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 36,
                  color: _border,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTasks(Project project) {
    return StreamBuilder<List<Task>>(
      stream: _taskService.watchProjectTasks(project.projectId),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];

        final recentTasks = [...tasks]
          ..sort(
            (a, b) => (b.updatedAt ?? DateTime(2000))
                .compareTo(a.updatedAt ?? DateTime(2000)),
          );

        final displayTasks = recentTasks.take(5).toList();

        return _card(
          child: Column(
            children: [
              _sectionHeader(
                'Recent Tasks',
                Icons.task_alt_rounded,
                actionLabel: 'View All',
                onAction: () {
                  _tabController.animateTo(1);
                },
              ),
              const SizedBox(height: 14),
              if (displayTasks.isEmpty)
                _emptyInline(
                  Icons.task_outlined,
                  'No tasks created yet',
                  'Create tasks to start tracking this project.',
                )
              else
                ...displayTasks.map(
                  (task) => _taskListTile(task),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTasks(Project project) {
    return StreamBuilder<List<Task>>(
      stream: _taskService.watchProjectTasks(project.projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final tasks = snapshot.data ?? [];

        final backlog = tasks
            .where((task) => task.status == TaskStatus.backlog)
            .length;

        final todo =
            tasks.where((task) => task.status == TaskStatus.todo).length;

        final inProgress = tasks
            .where((task) => task.status == TaskStatus.inProgress)
            .length;

        final review = tasks
            .where((task) => task.status == TaskStatus.inReview)
            .length;

        final completed = tasks
            .where((task) => task.status == TaskStatus.completed)
            .length;

        final blocked = tasks
            .where((task) => task.status == TaskStatus.blocked)
            .length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: _compactStat(
                    'Backlog',
                    backlog,
                    const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _compactStat(
                    'Todo',
                    todo,
                    _primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _compactStat(
                    'Progress',
                    inProgress,
                    const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _compactStat(
                    'Review',
                    review,
                    const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _compactStat(
                    'Completed',
                    completed,
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _compactStat(
                    'Blocked',
                    blocked,
                    const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _card(
              child: Column(
                children: [
                  _sectionHeader(
                    'All Tasks',
                    Icons.view_list_rounded,
                  ),
                  const SizedBox(height: 12),
                  if (tasks.isEmpty)
                    _emptyInline(
                      Icons.task_outlined,
                      'No tasks yet',
                      'Your project does not have any tasks.',
                    )
                  else
                    ...tasks.map(
                      (task) => _taskListTile(
                        task,
                        detailed: true,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _compactStat(
    String label,
    int value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskListTile(
    Task task, {
    bool detailed = false,
  }) {
    final statusColor = _taskStatusColor(task.status);
    final progress =
        task.completionPercentage.clamp(0.0, 100.0);

    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != TaskStatus.completed;

    return InkWell(
      onTap: () => _showTaskDetails(task),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                task.status == TaskStatus.completed
                    ? Icons.check_rounded
                    : Icons.task_alt_rounded,
                color: statusColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: detailed ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _smallPill(
                        _taskStatusLabel(task.status),
                        statusColor,
                      ),
                      const SizedBox(width: 6),
                      _smallPill(
                        task.priority.name.toUpperCase(),
                        _priorityColor(
                          _mapTaskPriorityToProjectPriority(
                            task.priority,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (detailed) ...[
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE5E7EF),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          statusColor,
                        ),
                      ),
                    ),
                  ],
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          isOverdue
                              ? Icons.warning_amber_rounded
                              : Icons.event_outlined,
                          size: 13,
                          color: isOverdue
                              ? const Color(0xFFEF4444)
                              : _muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isOverdue
                              ? 'Overdue • ${_formatDate(task.dueDate)}'
                              : 'Due ${_formatDate(task.dueDate)}',
                          style: TextStyle(
                            color: isOverdue
                                ? const Color(0xFFEF4444)
                                : _muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFFB1B4C0),
            ),
          ],
        ),
      ),
    );
  }

  ProjectPriority _mapTaskPriorityToProjectPriority(
    TaskPriority priority,
  ) {
    switch (priority) {
      case TaskPriority.low:
        return ProjectPriority.low;
      case TaskPriority.medium:
        return ProjectPriority.medium;
      case TaskPriority.high:
        return ProjectPriority.high;
      case TaskPriority.urgent:
        return ProjectPriority.critical;
    }
  }

  Widget _smallPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMilestones(Project project) {
    return StreamBuilder<List<Milestone>>(
      stream: _milestoneService.watchProjectMilestones(
        project.projectId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final milestones = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          children: [
            _milestoneSummary(milestones),
            const SizedBox(height: 18),
            _card(
              child: Column(
                children: [
                  _sectionHeader(
                    'Project Milestones',
                    Icons.flag_outlined,
                  ),
                  const SizedBox(height: 14),
                  if (milestones.isEmpty)
                    _emptyInline(
                      Icons.flag_outlined,
                      'No milestones yet',
                      'Milestones will help divide this project into major phases.',
                    )
                  else
                    ...milestones.map(
                      (milestone) =>
                          _milestoneTile(milestone),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _milestoneSummary(List<Milestone> milestones) {
    final completed = milestones
        .where(
          (milestone) =>
              milestone.status == MilestoneStatus.completed,
        )
        .length;

    final active = milestones
        .where(
          (milestone) =>
              milestone.status == MilestoneStatus.inProgress,
        )
        .length;

    final delayed = milestones
        .where(
          (milestone) =>
              milestone.status == MilestoneStatus.delayed,
        )
        .length;

    return Row(
      children: [
        Expanded(
          child: _metricCard(
            icon: Icons.flag_outlined,
            value: '${milestones.length}',
            label: 'Total',
            color: _primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            icon: Icons.timelapse_rounded,
            value: '$active',
            label: 'Active',
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            icon: Icons.check_circle_outline_rounded,
            value: '$completed',
            label: 'Done',
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            icon: Icons.warning_amber_rounded,
            value: '$delayed',
            label: 'Delayed',
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _milestoneTile(Milestone milestone) {
    final color =
        _milestoneStatusColor(milestone.status);

    final progress =
        milestone.progress.clamp(0.0, 100.0);

    return InkWell(
      onTap: () {
        _showMilestoneDetails(milestone);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _border,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _smallPill(
                            _milestoneStatusLabel(
                              milestone.status,
                            ),
                            color,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${milestone.completedTaskCount}/${milestone.taskCount} tasks',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6,
                backgroundColor: const Color(0xFFE5E7EF),
                valueColor:
                    AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            if (milestone.dueDate != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Due ${_formatDate(milestone.dueDate)}',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeam(Project project) {
    return StreamBuilder<List<AppUser>>(
      stream: _teamService.watchAllEmployees(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final allEmployees = snapshot.data ?? [];

        final members = allEmployees
            .where(
              (employee) =>
                  project.memberIds.contains(employee.id),
            )
            .toList();

        AppUser? manager;

        if (project.projectManagerId != null) {
          for (final employee in allEmployees) {
            if (employee.id == project.projectManagerId) {
              manager = employee;
              break;
            }
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          children: [
            _teamSummary(project, members),
            const SizedBox(height: 18),
            if (manager != null) ...[
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      'Project Manager',
                      Icons.manage_accounts_outlined,
                    ),
                    const SizedBox(height: 14),
                    _employeeTile(
                      manager,
                      highlighted: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            _card(
              child: Column(
                children: [
                  _sectionHeader(
                    'Project Team',
                    Icons.groups_2_outlined,
                  ),
                  const SizedBox(height: 14),
                  if (members.isEmpty)
                    _emptyInline(
                      Icons.groups_outlined,
                      'No project members',
                      'Add team members from the project setup.',
                    )
                  else
                    ...members.map(
                      (employee) =>
                          _employeeTile(employee),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _teamSummary(
    Project project,
    List<AppUser> members,
  ) {
    final active = members
        .where((employee) => employee.isActive)
        .length;

    final management = members
        .where((employee) => employee.isManagement)
        .length;

    return Row(
      children: [
        Expanded(
          child: _metricCard(
            icon: Icons.groups_outlined,
            value: '${members.length}',
            label: 'Members',
            color: _primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            icon: Icons.person_outline_rounded,
            value: '$active',
            label: 'Active',
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            icon: Icons.workspace_premium_outlined,
            value: '$management',
            label: 'Management',
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _employeeTile(
    AppUser employee, {
    bool highlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? _primary.withOpacity(.05)
            : const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? _primary.withOpacity(.18)
              : _border,
        ),
      ),
      child: Row(
        children: [
          _avatar(employee),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name.isEmpty
                      ? 'Unnamed Employee'
                      : employee.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  employee.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _smallPill(
                      employee.roleLabel,
                      _primary,
                    ),
                    const SizedBox(width: 6),
                    if (employee.isActive)
                      _smallPill(
                        'ACTIVE',
                        const Color(0xFF10B981),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(AppUser employee) {
    final image = employee.profileImage;

    if (image != null && image.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          image,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _avatarFallback(employee);
          },
        ),
      );
    }

    return _avatarFallback(employee);
  }

  Widget _avatarFallback(AppUser employee) {
    final name = employee.name.trim();

    final initials = name.isEmpty
        ? '?'
        : name
            .split(' ')
            .where((part) => part.trim().isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary,
            const Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildActivity(Project project) {
    return StreamBuilder<List<Task>>(
      stream: _taskService.watchProjectTasks(project.projectId),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];

        final sortedTasks = [...tasks]
          ..sort(
            (a, b) => (b.updatedAt ?? DateTime(2000))
                .compareTo(a.updatedAt ?? DateTime(2000)),
          );

        final activityTasks = sortedTasks.take(8).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          children: [
            _activityIntro(),
            const SizedBox(height: 18),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    'Recent Project Activity',
                    Icons.history_rounded,
                  ),
                  const SizedBox(height: 14),
                  if (activityTasks.isEmpty)
                    _emptyInline(
                      Icons.history_rounded,
                      'No activity yet',
                      'Task activity will appear here as the project progresses.',
                    )
                  else
                    ...activityTasks.map(
                      (task) => _activityTaskPreview(
                        task,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _activityIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEEF2FF),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _primary.withOpacity(.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.history_rounded,
              color: _primary,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Project Activity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track recent task movement and project progress.',
                  style: TextStyle(
                    color: Color(0xFF73778A),
                    fontSize: 11,
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

  Widget _activityTaskPreview(Task task) {
    final color = _taskStatusColor(task.status);

    return InkWell(
      onTap: () => _showTaskDetails(task),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: color,
                size: 17,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _taskStatusLabel(task.status),
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (task.updatedAt != null)
              Text(
                _formatDateTime(task.updatedAt),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: _muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTaskDetails(Task task) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(
          taskId: task.taskId,
        ),
      ),
    );

    if (!mounted) return;

    // Firestore streams refresh the project automatically, but keeping the
    // selected Tasks tab active makes the flow feel continuous after returning.
    if (result == true && _tabController.index != 1) {
      _tabController.animateTo(1);
    }
  }

  Widget _detailMiniCard(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(TaskActivity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: _primary.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt_rounded,
              size: 15,
              color: _primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  activity.message.isNotEmpty
                      ? activity.message
                      : _activityTypeLabel(
                          activity.type,
                        ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDateTime(activity.createdAt),
                  style: TextStyle(
                    color: _muted,
                    fontSize: 9,
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

  void _showMilestoneDetails(Milestone milestone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final color =
            _milestoneStatusColor(milestone.status);

        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            28,
          ),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8DAE5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(.10),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.flag_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        milestone.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if ((milestone.description ?? '')
                    .trim()
                    .isNotEmpty)
                  _infoBlock(
                    'Description',
                    milestone.description!.trim(),
                  ),
                _infoRow(
                  Icons.circle_outlined,
                  'Status',
                  _milestoneStatusLabel(
                    milestone.status,
                  ),
                  valueColor: color,
                ),
                _infoRow(
                  Icons.percent_rounded,
                  'Progress',
                  '${milestone.progress.toStringAsFixed(0)}%',
                  valueColor: color,
                ),
                _infoRow(
                  Icons.task_alt_rounded,
                  'Tasks',
                  '${milestone.completedTaskCount}/${milestone.taskCount}',
                ),
                _infoRow(
                  Icons.event_outlined,
                  'Due Date',
                  _formatDate(milestone.dueDate),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(
    String title,
    IconData icon, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: _primary.withOpacity(.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 17,
            color: _primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: _primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _card({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _emptyInline(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 26,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 30,
            color: const Color(0xFFA4A8B8),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  IconData _projectIcon(String? icon) {
    switch (icon) {
      case 'code':
        return Icons.code_rounded;
      case 'mobile':
        return Icons.phone_android_rounded;
      case 'web':
        return Icons.language_rounded;
      case 'design':
        return Icons.design_services_outlined;
      case 'marketing':
        return Icons.campaign_outlined;
      case 'sales':
        return Icons.trending_up_rounded;
      case 'finance':
        return Icons.account_balance_wallet_outlined;
      case 'operations':
        return Icons.settings_outlined;
      default:
        return Icons.folder_special_outlined;
    }
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load project',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notFoundState() {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Project',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.folder_off_outlined,
                  color: _primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Project not found',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'This project may have been deleted or is no longer available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}