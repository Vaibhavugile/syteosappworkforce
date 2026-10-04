import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';



import '../../../models/app_user.dart';

import '../../../models/project.dart';

import '../../../models/task.dart';

import '../../../models/task_activity.dart';
import '../../../models/task_attachment.dart';
import '../../../models/task_daily_update.dart';

import '../../../services/project_service.dart';

import '../../../services/task_service.dart';

import '../../../services/team_service.dart';
import '../../../services/task_attachment_service.dart';
import '../../../services/task_daily_update_service.dart';
import '../../../team/daily_work/screens/daily_work_screen.dart';



class TaskDetailsScreen extends StatefulWidget {

  final String taskId;



  const TaskDetailsScreen({

    super.key,

    required this.taskId,

  });



  @override

  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();

}



class _TaskDetailsScreenState extends State<TaskDetailsScreen> {

  final TaskService _taskService = TaskService.instance;

  final ProjectService _projectService = ProjectService.instance;

  final TeamService _teamService = TeamService.instance;
  final TaskDailyUpdateService _dailyUpdateService =
      TaskDailyUpdateService.instance;
  final TaskAttachmentService _attachmentService =
      TaskAttachmentService.instance;



  bool _actionLoading = false;



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(

        backgroundColor: const Color(0xFFF7F8FC),

        surfaceTintColor: Colors.transparent,

        elevation: 0,

        title: Text(

          'Task Details',

          style: GoogleFonts.inter(

            fontSize: 19,

            fontWeight: FontWeight.w800,

            color: const Color(0xFF171923),

          ),

        ),

        actions: [

          StreamBuilder<Task?>(

            stream: _taskService.watchTask(widget.taskId),

            builder: (context, snapshot) {

              final task = snapshot.data;

              if (task == null) return const SizedBox.shrink();

              return IconButton(

                onPressed: _actionLoading ? null : () => _showActions(task),

                icon: const Icon(

                  Icons.more_horiz_rounded,

                  color: Color(0xFF171923),

                ),

              );

            },

          ),

        ],

      ),

      body: StreamBuilder<Task?>(

        stream: _taskService.watchTask(widget.taskId),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting &&

              snapshot.data == null) {

            return const Center(

              child: CircularProgressIndicator(

                color: Color(0xFF6366F1),

              ),

            );

          }



          final task = snapshot.data;



          if (task == null) {

            return _emptyState();

          }



          return RefreshIndicator(

            color: const Color(0xFF6366F1),

            onRefresh: () async {

              await _taskService.getTask(widget.taskId);

            },

            child: ListView(

              physics: const AlwaysScrollableScrollPhysics(

                parent: BouncingScrollPhysics(),

              ),

              padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),

              children: [

                _buildHero(task),

                const SizedBox(height: 16),

                _buildProgress(task),

                const SizedBox(height: 16),
                _buildDailyWorkSection(task),
                const SizedBox(height: 16),
                _buildAttachmentsSection(task),
                const SizedBox(height: 16),

                _buildPrimaryActions(task),

                const SizedBox(height: 16),

                _buildTaskInformation(task),

                const SizedBox(height: 16),

                _buildAssignment(task),

                const SizedBox(height: 16),

                _buildActivity(task),

              ],

            ),

          );

        },

      ),

    );

  }



  Widget _buildHero(Task task) {

    final color = _statusColor(task.status);



    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        gradient: const LinearGradient(

          colors: [

            Color(0xFF4F46E5),

            Color(0xFF6366F1),

            Color(0xFF8B5CF6),

          ],

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

        ),

        borderRadius: BorderRadius.circular(26),

        boxShadow: [

          BoxShadow(

            color: const Color(0xFF6366F1).withOpacity(.20),

            blurRadius: 28,

            offset: const Offset(0, 12),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              _pill(

                _statusLabel(task.status),

                Colors.white.withOpacity(.15),

                Colors.white,

              ),

              const Spacer(),

              _priorityPill(task.priority),

            ],

          ),

          const SizedBox(height: 17),

          Text(

            task.title,

            style: GoogleFonts.inter(

              fontSize: 23,

              height: 1.15,

              fontWeight: FontWeight.w900,

              color: Colors.white,

            ),

          ),

          const SizedBox(height: 8),

          if (task.description.trim().isNotEmpty)

            Text(

              task.description.trim(),

              maxLines: 4,

              overflow: TextOverflow.ellipsis,

              style: GoogleFonts.inter(

                fontSize: 12,

                height: 1.5,

                color: Colors.white.withOpacity(.82),

                fontWeight: FontWeight.w500,

              ),

            ),

          const SizedBox(height: 18),

          Row(

            children: [

              _heroMeta(

                Icons.calendar_today_outlined,

                task.dueDate == null

                    ? 'No due date'

                    : 'Due ${DateFormat('dd MMM').format(task.dueDate!)}',

              ),

              const SizedBox(width: 16),

              _heroMeta(

                Icons.percent_rounded,

                '${task.completionPercentage.toStringAsFixed(0)}% complete',

              ),

            ],

          ),

        ],

      ),

    );

  }



  Widget _buildProgress(Task task) {

    final progress = (task.completionPercentage / 100).clamp(0.0, 1.0);



    return _card(

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          _sectionHeader(

            'Progress',

            Icons.insights_rounded,

          ),

          const SizedBox(height: 17),

          Row(

            crossAxisAlignment: CrossAxisAlignment.end,

            children: [

              Text(

                '${task.completionPercentage.toStringAsFixed(0)}%',

                style: GoogleFonts.inter(

                  fontSize: 30,

                  fontWeight: FontWeight.w900,

                  color: const Color(0xFF171923),

                ),

              ),

              const Spacer(),

              Text(

                _progressMessage(task),

                style: GoogleFonts.inter(

                  fontSize: 11,

                  fontWeight: FontWeight.w700,

                  color: _statusColor(task.status),

                ),

              ),

            ],

          ),

          const SizedBox(height: 12),

          ClipRRect(

            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(

              minHeight: 10,

              value: progress,

              backgroundColor: const Color(0xFFEDEDF5),

              valueColor: const AlwaysStoppedAnimation<Color>(

                Color(0xFF6366F1),

              ),

            ),

          ),

          const SizedBox(height: 16),

          Row(

            children: [

              Expanded(

                child: _miniMetric(

                  'Estimated',

                  task.estimatedHours == null

                      ? 'Not set'

                      : '${task.estimatedHours!.toStringAsFixed(1)} h',

                  Icons.schedule_outlined,

                ),

              ),

              const SizedBox(width: 10),

              Expanded(

                child: _miniMetric(

                  'Actual',

                  task.actualHours == null

                      ? 'Not recorded'

                      : '${task.actualHours!.toStringAsFixed(1)} h',

                  Icons.timer_outlined,

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }



  // ===========================================================================
  // DAILY WORK
  // ===========================================================================

  Future<void> _openDailyWork(Task task) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DailyWorkScreen(taskId: task.taskId),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {});
    }
  }

  Widget _buildDailyWorkSection(Task task) {
    return StreamBuilder<List<TaskDailyUpdate>>(
      stream: _dailyUpdateService.watchTaskDailyWork(task.taskId),
      builder: (context, snapshot) {
        final updates = snapshot.data ?? <TaskDailyUpdate>[];

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _sectionHeader(
                      'Daily Work',
                      Icons.work_history_outlined,
                    ),
                  ),
                  _smallSectionButton(
                    icon: Icons.add_rounded,
                    label: 'Add Work',
                    onTap: _actionLoading
                        ? null
                        : () => _openDailyWork(task),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Record what was completed on this task each day.',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: const Color(0xFF858598),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              if (updates.isEmpty)
                _emptyInline(
                  Icons.history_toggle_off_rounded,
                  'No daily work yet',
                  'Add today\'s work, progress and proof.',
                )
              else ...[
                ...updates.take(5).map(_dailyWorkRow),
                if (updates.length > 5) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${updates.length - 5} more daily update${updates.length - 5 == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _dailyWorkRow(TaskDailyUpdate update) {
    final statusColor = _dailyStatusColor(update.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE7E9F2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 19,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM yyyy').format(update.date),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF24243A),
                        ),
                      ),
                    ),
                    _pill(
                      _dailyStatusLabel(update.status),
                      statusColor.withOpacity(.10),
                      statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  update.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    height: 1.4,
                    color: const Color(0xFF73778A),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 5,
                  children: [
                    _dailyMeta(
                      Icons.trending_up_rounded,
                      '${update.completionPercentage.toStringAsFixed(0)}%',
                    ),
                    if (update.hoursSpent != null)
                      _dailyMeta(
                        Icons.schedule_outlined,
                        '${update.hoursSpent!.toStringAsFixed(1)} h',
                      ),
                    if (update.attachmentIds.isNotEmpty)
                      _dailyMeta(
                        Icons.attach_file_rounded,
                        '${update.attachmentIds.length} file${update.attachmentIds.length == 1 ? '' : 's'}',
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

  Widget _dailyMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9A9AAC)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            color: const Color(0xFF73778A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Color _dailyStatusColor(TaskDailyUpdateStatus status) {
    switch (status) {
      case TaskDailyUpdateStatus.draft:
        return const Color(0xFF64748B);
      case TaskDailyUpdateStatus.submitted:
        return const Color(0xFF6366F1);
      case TaskDailyUpdateStatus.underReview:
        return const Color(0xFFF59E0B);
      case TaskDailyUpdateStatus.approved:
        return const Color(0xFF10B981);
      case TaskDailyUpdateStatus.changesRequested:
        return const Color(0xFFEF4444);
    }
  }

  String _dailyStatusLabel(TaskDailyUpdateStatus status) {
    switch (status) {
      case TaskDailyUpdateStatus.draft:
        return 'Draft';
      case TaskDailyUpdateStatus.submitted:
        return 'Submitted';
      case TaskDailyUpdateStatus.underReview:
        return 'Review';
      case TaskDailyUpdateStatus.approved:
        return 'Approved';
      case TaskDailyUpdateStatus.changesRequested:
        return 'Changes';
    }
  }

  // ===========================================================================
  // TASK ATTACHMENTS
  // ===========================================================================

  Widget _buildAttachmentsSection(Task task) {
    return StreamBuilder<List<TaskAttachment>>(
      stream: _attachmentService.watchTaskAttachments(task.taskId),
      builder: (context, snapshot) {
        final attachments = snapshot.data ?? <TaskAttachment>[];

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _sectionHeader(
                      'Attachments',
                      Icons.attach_file_rounded,
                    ),
                  ),
                  if (attachments.isNotEmpty)
                    _pill(
                      '${attachments.length}',
                      const Color(0xFFEDE9FE),
                      const Color(0xFF6366F1),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Files attached directly to this task.',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: const Color(0xFF858598),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              if (attachments.isEmpty)
                _emptyInline(
                  Icons.attach_file_rounded,
                  'No task attachments',
                  'Task files will appear here when uploaded.',
                )
              else
                ...attachments.map(_taskAttachmentRow),
            ],
          ),
        );
      },
    );
  }

  Widget _taskAttachmentRow(TaskAttachment attachment) {
    final color = _attachmentColor(attachment.type);

    return InkWell(
      onTap: () => _openAttachment(attachment),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE7E9F2)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _attachmentIcon(attachment.type),
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF24243A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${attachment.displayType} • ${attachment.formattedFileSize}',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      color: const Color(0xFF9A9AAC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              size: 17,
              color: Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(TaskAttachment attachment) async {
    final url = attachment.downloadUrl.trim();

    if (url.isEmpty) {
      _message('Attachment link is not available.');
      return;
    }

    _message('Attachment selected: ${attachment.fileName}');
  }

  Widget _smallSectionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF6366F1)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _attachmentIcon(TaskAttachmentType type) {
    switch (type) {
      case TaskAttachmentType.image:
        return Icons.image_outlined;
      case TaskAttachmentType.video:
        return Icons.videocam_outlined;
      case TaskAttachmentType.screenRecording:
        return Icons.screen_share_outlined;
      case TaskAttachmentType.pdf:
        return Icons.picture_as_pdf_outlined;
      case TaskAttachmentType.document:
        return Icons.description_outlined;
      case TaskAttachmentType.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _attachmentColor(TaskAttachmentType type) {
    switch (type) {
      case TaskAttachmentType.image:
        return const Color(0xFF0284C7);
      case TaskAttachmentType.video:
        return const Color(0xFF7C3AED);
      case TaskAttachmentType.screenRecording:
        return const Color(0xFFDB2777);
      case TaskAttachmentType.pdf:
        return const Color(0xFFDC2626);
      case TaskAttachmentType.document:
        return const Color(0xFF2563EB);
      case TaskAttachmentType.other:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildPrimaryActions(Task task) {

    final actions = <Widget>[];



    if (task.status == TaskStatus.todo ||

        task.status == TaskStatus.backlog ||

        task.status == TaskStatus.changesRequested) {

      actions.add(

        _actionButton(

          'Start Task',

          Icons.play_arrow_rounded,

          const Color(0xFF10B981),

          () => _run('start task', () => _taskService.startTask(task.taskId)),

        ),

      );

    }



    if (task.status == TaskStatus.inProgress) {

      actions.add(

        _actionButton(

          'Update Progress',

          Icons.tune_rounded,

          const Color(0xFF6366F1),

          () => _showProgressEditor(task),

        ),

      );

      actions.add(

        _actionButton(

          'Submit Review',

          Icons.rate_review_outlined,

          const Color(0xFF8B5CF6),

          () => _run(

            'submit task for review',

            () => _taskService.submitForReview(task.taskId),

          ),

        ),

      );

      actions.add(

        _actionButton(

          'Block',

          Icons.block_rounded,

          const Color(0xFFEF4444),

          () => _run(

            'block task',

            () => _taskService.blockTask(task.taskId, note: 'Task blocked from task actions.'),

          ),

        ),

      );

    }



    if (task.status == TaskStatus.inReview) {

      actions.add(

        _actionButton(

          'Approve',

          Icons.verified_rounded,

          const Color(0xFF10B981),

          () => _run(

            'approve task',

            () => _taskService.approveTask(task.taskId),

          ),

        ),

      );

      actions.add(

        _actionButton(

          'Request Changes',

          Icons.edit_note_rounded,

          const Color(0xFFF59E0B),

          () => _showChangesDialog(task),

        ),

      );

    }



    if (task.status == TaskStatus.completed ||

        task.status == TaskStatus.cancelled) {

      actions.add(

        _actionButton(

          'Reopen',

          Icons.refresh_rounded,

          const Color(0xFF6366F1),

          () => _run(

            'reopen task',

            () => _taskService.reopenTask(task.taskId),

          ),

        ),

      );

    }



    if (actions.isEmpty) return const SizedBox.shrink();



    return _card(

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          _sectionHeader('Actions', Icons.bolt_rounded),

          const SizedBox(height: 13),

          Wrap(

            spacing: 9,

            runSpacing: 9,

            children: actions,

          ),

        ],

      ),

    );

  }



  Widget _buildTaskInformation(Task task) {

    return _card(

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          _sectionHeader('Task Information', Icons.info_outline_rounded),

          const SizedBox(height: 14),

          _detail('Start Date', _date(task.startDate), Icons.play_circle_outline),

          _detail('Due Date', _date(task.dueDate), Icons.event_outlined),

          _detail(

            'Milestone',

            task.milestoneId?.isNotEmpty == true

                ? task.milestoneId!

                : 'Not assigned',

            Icons.flag_outlined,

          ),

          _detail(

            'Parent Task',

            task.parentTaskId?.isNotEmpty == true

                ? task.parentTaskId!

                : 'No parent task',

            Icons.account_tree_outlined,

          ),

          _detail(

            'Created',

            _dateTime(task.createdAt),

            Icons.add_circle_outline,

          ),

          _detail(

            'Last Updated',

            _dateTime(task.updatedAt),

            Icons.update_rounded,

          ),

        ],

      ),

    );

  }



  Widget _buildAssignment(Task task) {

    return FutureBuilder<List<AppUser>>(

      future: _teamService.getActiveEmployees(),

      builder: (context, snapshot) {

        final employees = snapshot.data ?? [];

        final assigned = employees

            .where((employee) => employee.id == task.assignedTo)

            .cast<AppUser?>()

            .firstWhere(

              (employee) => employee != null,

              orElse: () => null,

            );



        return FutureBuilder<Project?>(

          future: _projectService.getProject(task.projectId),

          builder: (context, projectSnapshot) {

            final project = projectSnapshot.data;



            return _card(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  _sectionHeader(

                    'Ownership',

                    Icons.groups_rounded,

                  ),

                  const SizedBox(height: 14),

                  if (project != null)

                    _detail(

                      'Project',

                      project.name,

                      Icons.folder_outlined,

                    ),

                  _detail(

                    'Assigned To',

                    assigned?.name ?? 'Unassigned',

                    Icons.person_outline_rounded,

                  ),

                  _detail(

                    'Created By',

                    task.createdBy,

                    Icons.person_add_alt_outlined,

                  ),

                ],

              ),

            );

          },

        );

      },

    );

  }



  Widget _buildActivity(Task task) {

    return FutureBuilder<List<TaskActivity>>(

      future: _taskService.getTaskActivities(task.taskId),

      builder: (context, snapshot) {

        final activities = [...(snapshot.data ?? [])]

          ..sort(

            (a, b) => (b.createdAt ?? DateTime(2000))

                .compareTo(a.createdAt ?? DateTime(2000)),

          );



        return _card(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              _sectionHeader(

                'Activity',

                Icons.history_rounded,

              ),

              const SizedBox(height: 14),

              if (activities.isEmpty)

                _emptyInline(

                  Icons.history_rounded,

                  'No activity yet',

                  'Task activity will appear here as work progresses.',

                )

              else

                ...activities.asMap().entries.map(

                  (entry) => _activityRow(

                    entry.value,

                    entry.key == activities.length - 1,

                  ),

                ),

            ],

          ),

        );

      },

    );

  }



  Future<void> _showProgressEditor(Task task) async {

    double value = task.completionPercentage;



    await showModalBottomSheet<void>(

      context: context,

      backgroundColor: Colors.transparent,

      isScrollControlled: true,

      builder: (sheetContext) {

        return StatefulBuilder(

          builder: (context, setSheetState) {

            return _sheet(

              title: 'Update Progress',

              subtitle: 'Set the current completion percentage.',

              child: Column(

                children: [

                  Text(

                    '${value.toStringAsFixed(0)}%',

                    style: GoogleFonts.inter(

                      fontSize: 42,

                      fontWeight: FontWeight.w900,

                      color: const Color(0xFF6366F1),

                    ),

                  ),

                  Slider(

                    value: value,

                    min: 0,

                    max: 100,

                    divisions: 20,

                    activeColor: const Color(0xFF6366F1),

                    onChanged: (next) {

                      setSheetState(() => value = next);

                    },

                  ),

                  const SizedBox(height: 12),

                  SizedBox(

                    width: double.infinity,

                    height: 50,

                    child: ElevatedButton(

                      onPressed: () async {

                        Navigator.pop(sheetContext);

                        await _run(

                          'update progress',

                          () => _taskService.updateCompletionPercentage(

                            taskId: task.taskId,

                            percentage: value,

                          ),

                        );

                      },

                      style: _buttonStyle(const Color(0xFF6366F1)),

                      child: const Text(

                        'Save Progress',

                        style: TextStyle(fontWeight: FontWeight.w800),

                      ),

                    ),

                  ),

                ],

              ),

            );

          },

        );

      },

    );

  }



  Future<void> _showChangesDialog(Task task) async {

    final controller = TextEditingController();



    final submit = await showDialog<bool>(

      context: context,

      builder: (dialogContext) {

        return AlertDialog(

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(22),

          ),

          title: Text(

            'Request Changes',

            style: GoogleFonts.inter(fontWeight: FontWeight.w800),

          ),

          content: TextField(

            controller: controller,

            maxLines: 5,

            decoration: InputDecoration(

              hintText: 'Explain what needs to be changed...',

              filled: true,

              fillColor: const Color(0xFFF7F7FB),

              border: OutlineInputBorder(

                borderRadius: BorderRadius.circular(14),

                borderSide: BorderSide.none,

              ),

            ),

          ),

          actions: [

            TextButton(

              onPressed: () => Navigator.pop(dialogContext, false),

              child: const Text('Cancel'),

            ),

            ElevatedButton(

              onPressed: () => Navigator.pop(dialogContext, true),

              style: _buttonStyle(const Color(0xFFF59E0B)),

              child: const Text(

                'Request Changes',

                style: TextStyle(fontWeight: FontWeight.w800),

              ),

            ),

          ],

        );

      },

    );



    if (submit != true) return;



    final note = controller.text.trim();



    if (note.isEmpty) {

      _message('Please enter what needs to be changed.');

      return;

    }



    await _run(

      'request changes',

      () => _taskService.requestChanges(

        task.taskId,

        note: note,

      ),

    );



    controller.dispose();

  }



  Future<void> _showActions(Task task) async {

    await showModalBottomSheet<void>(

      context: context,

      backgroundColor: Colors.transparent,

      builder: (sheetContext) {

        return _sheet(

          title: 'Task Actions',

          subtitle: 'Manage this task.',

          child: Column(

            children: [

              _sheetAction(

                Icons.play_arrow_rounded,

                'Start Task',

                'Move the task into progress',

                const Color(0xFF10B981),

                () {

                  Navigator.pop(sheetContext);

                  _run(

                    'start task',

                    () => _taskService.startTask(task.taskId),

                  );

                },

              ),

              _sheetAction(

                Icons.block_rounded,

                'Block Task',

                'Mark the task as blocked',

                const Color(0xFFEF4444),

                () {

                  Navigator.pop(sheetContext);

                  _run(

                    'block task',

                    () => _taskService.blockTask(task.taskId, note: 'Task blocked from task actions.'),

                  );

                },

              ),

              _sheetAction(

                Icons.refresh_rounded,

                'Reopen Task',

                'Return the task to active work',

                const Color(0xFF6366F1),

                () {

                  Navigator.pop(sheetContext);

                  _run(

                    'reopen task',

                    () => _taskService.reopenTask(task.taskId),

                  );

                },

              ),

            ],

          ),

        );

      },

    );

  }



  Future<void> _run(

    String action,

    Future<void> Function() callback,

  ) async {

    if (_actionLoading) return;



    setState(() => _actionLoading = true);



    try {

      await callback();

      if (!mounted) return;

      _message('${_capitalize(action)} successfully.');

    } catch (_) {

      if (!mounted) return;

      _message('Unable to $action. Please try again.');

    } finally {

      if (mounted) {

        setState(() => _actionLoading = false);

      }

    }

  }



  Widget _actionButton(

    String label,

    IconData icon,

    Color color,

    VoidCallback onPressed,

  ) {

    return ElevatedButton.icon(

      onPressed: _actionLoading ? null : onPressed,

      icon: Icon(icon, size: 17),

      label: Text(label),

      style: ElevatedButton.styleFrom(

        elevation: 0,

        backgroundColor: color.withOpacity(.10),

        foregroundColor: color,

        disabledBackgroundColor: const Color(0xFFF1F1F5),

        disabledForegroundColor: const Color(0xFFAAAAB8),

        padding: const EdgeInsets.symmetric(

          horizontal: 13,

          vertical: 11,

        ),

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(13),

        ),

      ),

    );

  }



  Widget _activityRow(TaskActivity activity, bool last) {

    final color = _activityColor(activity.type);



    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        SizedBox(

          width: 28,

          child: Column(

            children: [

              Container(

                width: 26,

                height: 26,

                decoration: BoxDecoration(

                  color: color.withOpacity(.10),

                  shape: BoxShape.circle,

                ),

                child: Icon(

                  _activityIcon(activity.type),

                  size: 14,

                  color: color,

                ),

              ),

              if (!last)

                Container(

                  width: 1.5,

                  height: 38,

                  color: const Color(0xFFE7E9F2),

                ),

            ],

          ),

        ),

        const SizedBox(width: 11),

        Expanded(

          child: Padding(

            padding: const EdgeInsets.only(bottom: 14, top: 3),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  _activityLabel(activity.type),

                  style: GoogleFonts.inter(

                    fontSize: 12.5,

                    fontWeight: FontWeight.w800,

                    color: const Color(0xFF24243A),

                  ),

                ),

                if (activity.message.trim().isNotEmpty) ...[

                  const SizedBox(height: 4),

                  Text(

                    activity.message,

                    style: GoogleFonts.inter(

                      fontSize: 11,

                      height: 1.4,

                      color: const Color(0xFF73778A),

                    ),

                  ),

                ],

                const SizedBox(height: 4),

                Text(

                  _dateTime(activity.createdAt),

                  style: GoogleFonts.inter(

                    fontSize: 9.5,

                    color: const Color(0xFF9A9AAC),

                    fontWeight: FontWeight.w600,

                  ),

                ),

              ],

            ),

          ),

        ),

      ],

    );

  }



  Widget _detail(String label, String value, IconData icon) {

    return Container(

      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(

        color: const Color(0xFFF9FAFC),

        borderRadius: BorderRadius.circular(13),

        border: Border.all(color: const Color(0xFFEAEAF1)),

      ),

      child: Row(

        children: [

          Icon(icon, size: 17, color: const Color(0xFF6366F1)),

          const SizedBox(width: 10),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  label,

                  style: GoogleFonts.inter(

                    fontSize: 9.5,

                    color: const Color(0xFF9A9AAC),

                    fontWeight: FontWeight.w600,

                  ),

                ),

                const SizedBox(height: 3),

                Text(

                  value,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: GoogleFonts.inter(

                    fontSize: 11.5,

                    color: const Color(0xFF303047),

                    fontWeight: FontWeight.w700,

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Widget _miniMetric(String label, String value, IconData icon) {

    return Container(

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(

        color: const Color(0xFFF8F8FC),

        borderRadius: BorderRadius.circular(14),

      ),

      child: Row(

        children: [

          Icon(icon, size: 17, color: const Color(0xFF6366F1)),

          const SizedBox(width: 8),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  label,

                  style: const TextStyle(

                    fontSize: 9,

                    color: Color(0xFF9696A8),

                    fontWeight: FontWeight.w600,

                  ),

                ),

                const SizedBox(height: 2),

                Text(

                  value,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(

                    fontSize: 11,

                    color: Color(0xFF303047),

                    fontWeight: FontWeight.w800,

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Widget _heroMeta(IconData icon, String text) {

    return Row(

      mainAxisSize: MainAxisSize.min,

      children: [

        Icon(

          icon,

          size: 14,

          color: Colors.white.withOpacity(.78),

        ),

        const SizedBox(width: 6),

        Text(

          text,

          style: GoogleFonts.inter(

            fontSize: 10.5,

            color: Colors.white.withOpacity(.86),

            fontWeight: FontWeight.w700,

          ),

        ),

      ],

    );

  }



  Widget _priorityPill(TaskPriority priority) {

    return _pill(

      _priorityLabel(priority),

      Colors.white.withOpacity(.15),

      Colors.white,

    );

  }



  Widget _pill(String text, Color background, Color foreground) {

    return Container(

      padding: const EdgeInsets.symmetric(

        horizontal: 10,

        vertical: 6,

      ),

      decoration: BoxDecoration(

        color: background,

        borderRadius: BorderRadius.circular(30),

      ),

      child: Text(

        text,

        style: GoogleFonts.inter(

          fontSize: 9.5,

          fontWeight: FontWeight.w800,

          color: foreground,

        ),

      ),

    );

  }



  Widget _sectionHeader(String title, IconData icon) {

    return Row(

      children: [

        Container(

          width: 34,

          height: 34,

          decoration: BoxDecoration(

            color: const Color(0xFF6366F1).withOpacity(.09),

            borderRadius: BorderRadius.circular(11),

          ),

          child: Icon(

            icon,

            size: 18,

            color: const Color(0xFF6366F1),

          ),

        ),

        const SizedBox(width: 10),

        Text(

          title,

          style: GoogleFonts.inter(

            fontSize: 14,

            fontWeight: FontWeight.w900,

            color: const Color(0xFF222238),

          ),

        ),

      ],

    );

  }



  Widget _card({required Widget child}) {

    return Container(

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: const Color(0xFFE7E9F2)),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(.035),

            blurRadius: 18,

            offset: const Offset(0, 7),

          ),

        ],

      ),

      child: child,

    );

  }



  Widget _sheet({

    required String title,

    required String subtitle,

    required Widget child,

  }) {

    return SafeArea(

      top: false,

      child: Container(

        padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),

        decoration: const BoxDecoration(

          color: Colors.white,

          borderRadius: BorderRadius.vertical(

            top: Radius.circular(28),

          ),

        ),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Center(

              child: Container(

                width: 42,

                height: 4,

                decoration: BoxDecoration(

                  color: const Color(0xFFD8DAE5),

                  borderRadius: BorderRadius.circular(10),

                ),

              ),

            ),

            const SizedBox(height: 20),

            Text(

              title,

              style: GoogleFonts.inter(

                fontSize: 20,

                fontWeight: FontWeight.w900,

                color: const Color(0xFF171923),

              ),

            ),

            const SizedBox(height: 5),

            Text(

              subtitle,

              style: GoogleFonts.inter(

                fontSize: 11,

                color: const Color(0xFF858598),

              ),

            ),

            const SizedBox(height: 20),

            child,

          ],

        ),

      ),

    );

  }



  Widget _sheetAction(

    IconData icon,

    String title,

    String subtitle,

    Color color,

    VoidCallback onTap,

  ) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(15),

      child: Container(

        margin: const EdgeInsets.only(bottom: 9),

        padding: const EdgeInsets.all(13),

        decoration: BoxDecoration(

          color: const Color(0xFFF9FAFC),

          borderRadius: BorderRadius.circular(15),

          border: Border.all(color: const Color(0xFFE7E9F2)),

        ),

        child: Row(

          children: [

            Container(

              width: 40,

              height: 40,

              decoration: BoxDecoration(

                color: color.withOpacity(.10),

                borderRadius: BorderRadius.circular(12),

              ),

              child: Icon(icon, color: color, size: 20),

            ),

            const SizedBox(width: 11),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    title,

                    style: GoogleFonts.inter(

                      fontSize: 12.5,

                      fontWeight: FontWeight.w800,

                    ),

                  ),

                  const SizedBox(height: 3),

                  Text(

                    subtitle,

                    style: GoogleFonts.inter(

                      fontSize: 10,

                      color: const Color(0xFF88889A),

                    ),

                  ),

                ],

              ),

            ),

            const Icon(

              Icons.chevron_right_rounded,

              color: Color(0xFFAAAAB8),

            ),

          ],

        ),

      ),

    );

  }



  ButtonStyle _buttonStyle(Color color) {

    return ElevatedButton.styleFrom(

      elevation: 0,

      backgroundColor: color,

      foregroundColor: Colors.white,

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(14),

      ),

    );

  }



  Widget _emptyState() {

    return Center(

      child: Padding(

        padding: const EdgeInsets.all(30),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            const Icon(

              Icons.task_outlined,

              size: 50,

              color: Color(0xFF9A9AAC),

            ),

            const SizedBox(height: 12),

            Text(

              'Task not found',

              style: GoogleFonts.inter(

                fontSize: 17,

                fontWeight: FontWeight.w800,

              ),

            ),

            const SizedBox(height: 5),

            Text(

              'This task may have been deleted or is no longer available.',

              textAlign: TextAlign.center,

              style: GoogleFonts.inter(

                fontSize: 11,

                color: const Color(0xFF858598),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _emptyInline(

    IconData icon,

    String title,

    String subtitle,

  ) {

    return Container(

      padding: const EdgeInsets.symmetric(

        horizontal: 14,

        vertical: 18,

      ),

      decoration: BoxDecoration(

        color: const Color(0xFFF9FAFC),

        borderRadius: BorderRadius.circular(15),

      ),

      child: Row(

        children: [

          Icon(icon, color: const Color(0xFF9A9AAC)),

          const SizedBox(width: 11),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  title,

                  style: GoogleFonts.inter(

                    fontSize: 11.5,

                    fontWeight: FontWeight.w800,

                  ),

                ),

                const SizedBox(height: 3),

                Text(

                  subtitle,

                  style: GoogleFonts.inter(

                    fontSize: 10,

                    color: const Color(0xFF8B8B9D),

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Color _statusColor(TaskStatus status) {

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



  Color _activityColor(TaskActivityType type) {

    switch (type) {

      case TaskActivityType.created:

        return const Color(0xFF6366F1);

      case TaskActivityType.assigned:

      case TaskActivityType.reassigned:

        return const Color(0xFF2563EB);

      case TaskActivityType.statusChanged:

      case TaskActivityType.reopened:

        return const Color(0xFF8B5CF6);

      case TaskActivityType.priorityChanged:

      case TaskActivityType.dueDateChanged:

        return const Color(0xFFF59E0B);

      case TaskActivityType.submittedForReview:

      case TaskActivityType.approved:

        return const Color(0xFF10B981);

      case TaskActivityType.changesRequested:

        return const Color(0xFFF59E0B);

      case TaskActivityType.completed:

        return const Color(0xFF10B981);

      case TaskActivityType.blocked:

        return const Color(0xFFEF4444);

      case TaskActivityType.unblocked:

        return const Color(0xFF10B981);

      case TaskActivityType.descriptionUpdated:

      case TaskActivityType.commentAdded:

      case TaskActivityType.attachmentAdded:

        return const Color(0xFF64748B);

    }

  }



  IconData _activityIcon(TaskActivityType type) {

    switch (type) {

      case TaskActivityType.created:

        return Icons.add_rounded;

      case TaskActivityType.assigned:

      case TaskActivityType.reassigned:

        return Icons.person_add_alt_1_rounded;

      case TaskActivityType.statusChanged:

      case TaskActivityType.reopened:

        return Icons.sync_rounded;

      case TaskActivityType.priorityChanged:

        return Icons.flag_outlined;

      case TaskActivityType.dueDateChanged:

        return Icons.event_outlined;

      case TaskActivityType.descriptionUpdated:

        return Icons.edit_note_rounded;

      case TaskActivityType.commentAdded:

        return Icons.chat_bubble_outline_rounded;

      case TaskActivityType.attachmentAdded:

        return Icons.attach_file_rounded;

      case TaskActivityType.submittedForReview:

        return Icons.rate_review_outlined;

      case TaskActivityType.changesRequested:

        return Icons.edit_rounded;

      case TaskActivityType.approved:

        return Icons.verified_rounded;

      case TaskActivityType.completed:

        return Icons.check_rounded;

      case TaskActivityType.blocked:

        return Icons.block_rounded;

      case TaskActivityType.unblocked:

        return Icons.lock_open_rounded;

    }

  }



  String _activityLabel(TaskActivityType type) {

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



  String _statusLabel(TaskStatus status) {

    switch (status) {

      case TaskStatus.backlog:

        return 'Backlog';

      case TaskStatus.todo:

        return 'To Do';

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



  String _progressMessage(Task task) {

    switch (task.status) {

      case TaskStatus.inReview:

        return 'Awaiting review';

      case TaskStatus.changesRequested:

        return 'Changes required';

      case TaskStatus.completed:

        return 'Approved';

      case TaskStatus.blocked:

        return 'Blocked';

      default:

        return 'In progress';

    }

  }



  String _date(DateTime? date) {

    return date == null ? 'Not set' : DateFormat('dd MMM yyyy').format(date);

  }



  String _dateTime(DateTime? date) {

    return date == null

        ? 'Not available'

        : DateFormat('dd MMM yyyy, hh:mm a').format(date);

  }



  String _capitalize(String value) {

    if (value.isEmpty) return value;

    return value[0].toUpperCase() + value.substring(1);

  }



  void _message(String message) {

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        behavior: SnackBarBehavior.floating,

        backgroundColor: const Color(0xFF171923),

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(14),

        ),

        content: Text(

          message,

          style: const TextStyle(

            color: Colors.white,

            fontWeight: FontWeight.w700,

          ),

        ),

      ),

    );

  }

}
