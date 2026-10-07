



import 'package:flutter/material.dart';


import '../../features/invitation_builder/screens/invitation_preview_test_screen.dart';
import 'package:intl/intl.dart';


import '../../features/invitation_builder/screens/invitation_builder_screen.dart';




import '../../models/app_user.dart';



import '../../models/project.dart';



import '../../models/task.dart';



import '../../services/project_service.dart';



import '../../services/task_service.dart';



import '../../services/team_service.dart';







import '../../admin/projects/screens/projects_screen.dart';



import '../../admin/team/screens/team_screen.dart';



import '../../team/my_work/screens/my_work_screen.dart';

import '../../team/daily_work/screens/daily_work_screen.dart';
import '../../team/daily_work/screens/my_daily_work_history_screen.dart';

import '../../team/daily_work/screens/team_daily_work_screen.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../auth/login_screen.dart';
import '../../auth/services/auth_service.dart';







class DashboardScreen extends StatefulWidget {



  const DashboardScreen({super.key});







  @override



  State<DashboardScreen> createState() => _DashboardScreenState();



}







class _DashboardScreenState extends State<DashboardScreen> {



  final TeamService _teamService = TeamService.instance;



  final ProjectService _projectService = ProjectService.instance;



  final TaskService _taskService = TaskService.instance;







  static const Color _primary = Color(0xFF6366F1);



  static const Color _primaryDark = Color(0xFF4F46E5);



  static const Color _background = Color(0xFFF7F8FC);



  static const Color _text = Color(0xFF171923);



  static const Color _muted = Color(0xFF73778A);



  static const Color _border = Color(0xFFE7E9F2);



  static const Color _green = Color(0xFF10B981);



  static const Color _orange = Color(0xFFF59E0B);



  static const Color _red = Color(0xFFEF4444);



  static const Color _blue = Color(0xFF2563EB);



  static const Color _purple = Color(0xFF8B5CF6);







  AppUser? _currentUser;



  bool _loadingUser = true;







  @override



  void initState() {



    super.initState();



    _loadCurrentUser();



  }







  Future<void> _loadCurrentUser() async {



    try {



      final user = await _teamService.getCurrentUser();



      if (!mounted) return;







      setState(() {



        _currentUser = user;



        _loadingUser = false;



      });



    } catch (_) {



      if (!mounted) return;



      setState(() => _loadingUser = false);



    }



  }







  bool get _isManagement {



    final role = _currentUser?.role;



    return role == UserRole.ceo ||



        role == UserRole.cto ||



        role == UserRole.admin;



  }







  bool get _isSales {



    final role = _currentUser?.role;



    return role == UserRole.salesExecutive ||



        role == UserRole.callingExecutive;



  }







  String get _greeting {



    final hour = DateTime.now().hour;



    if (hour < 12) return 'Good morning';



    if (hour < 17) return 'Good afternoon';



    return 'Good evening';



  }







  String get _displayName {



    final name = _currentUser?.name.trim() ?? '';



    if (name.isEmpty) return 'there';



    return name.split(' ').first;



  }







  @override



  Widget build(BuildContext context) {



    return Scaffold(



      backgroundColor: _background,



      appBar: _buildAppBar(),



      body: _loadingUser



          ? const Center(



              child: CircularProgressIndicator(color: _primary),



            )



          : RefreshIndicator(



              color: _primary,



              onRefresh: _loadCurrentUser,



              child: _buildBody(),



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



      title: Column(



        crossAxisAlignment: CrossAxisAlignment.start,



        children: [



          Text(



            'Syteos Business',



            style: const TextStyle(



              color: _text,



              fontSize: 18,



              fontWeight: FontWeight.w900,



              letterSpacing: -.4,



            ),



          ),



          Text(



            'Workspace',



            style: const TextStyle(



              color: _muted,



              fontSize: 10,



              fontWeight: FontWeight.w700,



            ),



          ),



        ],



      ),



      actions: [



        IconButton(



          tooltip: 'Refresh',



          onPressed: _loadCurrentUser,



          icon: const Icon(



            Icons.refresh_rounded,



            color: _text,



            size: 22,



          ),



        ),



        IconButton(
          tooltip: 'Logout',
          onPressed: _logout,
          icon: const Icon(
            Icons.logout_rounded,
            color: _text,
            size: 21,
          ),
        ),



        Padding(



          padding: const EdgeInsets.only(right: 16),



          child: _buildAvatar(_currentUser),



        ),



      ],



    );



  }







  Widget _buildBody() {



    if (_isSales) {



      return _buildSalesDashboard();



    }

    if (_currentUser?.role == UserRole.teamMember) {

      return _buildTeamMemberDashboard();

    }









    return StreamBuilder<List<Project>>(



      stream: _isManagement



          ? _projectService.watchAllProjects()



          : _projectService.watchMyProjects(),



      builder: (context, projectSnapshot) {



        return StreamBuilder<List<Task>>(



          stream: _isManagement



              ? _taskService.watchAllTasks()



              : _taskService.watchMyTasks(),



          builder: (context, taskSnapshot) {



            if (projectSnapshot.hasError || taskSnapshot.hasError) {



              return _buildError(



                projectSnapshot.error?.toString() ??



                    taskSnapshot.error?.toString() ??



                    'Unable to load dashboard.',



              );



            }







            final projects = projectSnapshot.data ?? <Project>[];



            final tasks = taskSnapshot.data ?? <Task>[];







            return ListView(



              physics: const AlwaysScrollableScrollPhysics(),



              padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),



              children: [



                _buildWelcome(),



                const SizedBox(height: 18),



                _buildHeadlineCard(projects, tasks),



                const SizedBox(height: 18),



                _buildStats(tasks, projects),



                const SizedBox(height: 24),



                _buildSectionTitle(



                  'Quick actions',



                  'Jump into the work that matters.',



                ),



                const SizedBox(height: 12),



                _buildQuickActions(),



                const SizedBox(height: 24),



                _buildTaskSnapshot(tasks),



                const SizedBox(height: 24),



                _buildProjectSnapshot(projects),



                if (_isManagement) ...[



                  const SizedBox(height: 24),



                  _buildTeamSnapshot(),



                ],



              ],



            );



          },



        );



      },



    );



  }







  Widget _buildTeamMemberDashboard() {

    return StreamBuilder<List<Project>>(

      stream: _projectService.watchMyProjects(),

      builder: (context, projectSnapshot) {

        return StreamBuilder<List<Task>>(

          stream: _taskService.watchMyTasks(),

          builder: (context, taskSnapshot) {

            if (projectSnapshot.hasError || taskSnapshot.hasError) {

              return _buildError(

                projectSnapshot.error?.toString() ??

                    taskSnapshot.error?.toString() ??

                    'Unable to load your workspace.',

              );

            }



            final projects = projectSnapshot.data ?? <Project>[];

            final tasks = taskSnapshot.data ?? <Task>[];



            final totalTasks = tasks.length;

            final backlog = tasks.where((t) => t.status == TaskStatus.backlog).length;

            final todo = tasks.where((t) => t.status == TaskStatus.todo).length;

            final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;

            final inReview = tasks.where((t) => t.status == TaskStatus.inReview).length;

            final changes = tasks.where((t) => t.status == TaskStatus.changesRequested).length;

            final completed = tasks.where((t) => t.status == TaskStatus.completed).length;

            final blocked = tasks.where((t) => t.status == TaskStatus.blocked).length;

            final cancelled = tasks.where((t) => t.status == TaskStatus.cancelled).length;

            final overdue = tasks.where(_isOverdue).length;



            final activeProjects = projects

                .where(

                  (p) =>

                      p.status == ProjectStatus.active ||

                      p.status == ProjectStatus.planning,

                )

                .length;

            final completedProjects =

                projects.where((p) => p.status == ProjectStatus.completed).length;

            final onHoldProjects =

                projects.where((p) => p.status == ProjectStatus.onHold).length;

            final draftProjects =

                projects.where((p) => p.status == ProjectStatus.draft).length;



            return ListView(

              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),

              children: [

                _buildWelcome(),

                const SizedBox(height: 18),

                _buildTeamMemberHero(

                  totalTasks: totalTasks,

                  totalProjects: projects.length,

                  inProgress: inProgress,

                  overdue: overdue,

                ),

                const SizedBox(height: 14),

                _buildTeamMemberAttendanceAction(),

                const SizedBox(height: 12),

                _buildTeamMemberDailyWorkAction(),

                const SizedBox(height: 12),

                _buildTeamMemberDailyWorkHistoryAction(),

                const SizedBox(height: 18),

                _buildTeamMemberTaskStats(

                  total: totalTasks,

                  backlog: backlog,

                  todo: todo,

                  inProgress: inProgress,

                  inReview: inReview,

                  changes: changes,

                  completed: completed,

                  blocked: blocked,

                  overdue: overdue,

                ),

                const SizedBox(height: 24),

                _buildSectionTitle(

                  'My projects',

                  'All projects assigned to you.',

                ),

                const SizedBox(height: 12),

                _buildTeamMemberProjectStats(

                  total: projects.length,

                  active: activeProjects,

                  completed: completedProjects,

                  onHold: onHoldProjects,

                  draft: draftProjects,

                ),

                const SizedBox(height: 14),

                _buildProjectSnapshotForMember(projects),

                const SizedBox(height: 24),

                _buildSectionTitle(

                  'My tasks',

                  'Every task currently assigned to you.',

                ),

                const SizedBox(height: 12),

                _buildTaskSnapshot(tasks),

                if (cancelled > 0) ...[

                  const SizedBox(height: 18),

                  _cardSection(

                    title: 'Cancelled tasks',

                    subtitle: 'Cancelled assignments are shown separately.',

                    icon: Icons.cancel_outlined,

                    child: _miniMetricRow(

                      icon: Icons.cancel_outlined,

                      label: 'Cancelled',

                      value: '$cancelled',

                      color: _muted,

                    ),

                  ),

                ],

              ],

            );

          },

        );

      },

    );

  }



  Widget _buildTeamMemberHero({

    required int totalTasks,

    required int totalProjects,

    required int inProgress,

    required int overdue,

  }) {

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        gradient: const LinearGradient(

          colors: [_primaryDark, _primary, _purple],

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

        ),

        borderRadius: BorderRadius.circular(26),

        boxShadow: [

          BoxShadow(

            color: _primary.withOpacity(.20),

            blurRadius: 28,

            offset: const Offset(0, 14),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Container(

                width: 44,

                height: 44,

                decoration: BoxDecoration(

                  color: Colors.white.withOpacity(.14),

                  borderRadius: BorderRadius.circular(14),

                ),

                child: const Icon(

                  Icons.person_pin_circle_outlined,

                  color: Colors.white,

                  size: 25,

                ),

              ),

              const Spacer(),

              _whitePill('MY WORKSPACE'),

            ],

          ),

          const SizedBox(height: 20),

          const Text(

            'Your assigned work',

            style: TextStyle(

              color: Colors.white,

              fontSize: 22,

              fontWeight: FontWeight.w900,

              letterSpacing: -.5,

            ),

          ),

          const SizedBox(height: 7),

          Text(

            'Only your assigned tasks and projects are included in these numbers.',

            style: TextStyle(

              color: Colors.white.withOpacity(.78),

              fontSize: 12,

              height: 1.45,

              fontWeight: FontWeight.w500,

            ),

          ),

          const SizedBox(height: 20),

          Row(

            children: [

              _heroMetric('$totalTasks', 'My tasks'),

              _heroMetric('$totalProjects', 'My projects'),

              _heroMetric('$inProgress', 'In progress'),

              _heroMetric('$overdue', 'Overdue'),

            ],

          ),

        ],

      ),

    );

  }



  Widget _buildTeamMemberAttendanceAction() {

    return Material(

      color: Colors.white,

      borderRadius: BorderRadius.circular(20),

      child: InkWell(

        onTap: _openAttendance,

        borderRadius: BorderRadius.circular(20),

        child: Container(

          padding: const EdgeInsets.all(15),

          decoration: BoxDecoration(

            borderRadius: BorderRadius.circular(20),

            border: Border.all(color: _border),

            boxShadow: [

              BoxShadow(

                color: Colors.black.withOpacity(.025),

                blurRadius: 16,

                offset: const Offset(0, 5),

              ),

            ],

          ),

          child: Row(

            children: [

              Container(

                width: 44,

                height: 44,

                decoration: BoxDecoration(

                  color: _green.withOpacity(.09),

                  borderRadius: BorderRadius.circular(14),

                ),

                child: const Icon(

                  Icons.access_time_filled_rounded,

                  color: _green,

                  size: 22,

                ),

              ),

              const SizedBox(width: 12),

              const Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      'Attendance',

                      style: TextStyle(

                        color: _text,

                        fontSize: 13,

                        fontWeight: FontWeight.w900,

                      ),

                    ),

                    SizedBox(height: 3),

                    Text(

                      'Check in & check out',

                      style: TextStyle(

                        color: _muted,

                        fontSize: 10,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                  ],

                ),

              ),

              const Icon(

                Icons.arrow_forward_ios_rounded,

                color: _muted,

                size: 14,

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildTeamMemberDailyWorkAction() {

    return Material(

      color: Colors.white,

      borderRadius: BorderRadius.circular(20),

      child: InkWell(

        onTap: _openDailyWork,

        borderRadius: BorderRadius.circular(20),

        child: Container(

          padding: const EdgeInsets.all(15),

          decoration: BoxDecoration(

            borderRadius: BorderRadius.circular(20),

            border: Border.all(color: _border),

            boxShadow: [

              BoxShadow(

                color: Colors.black.withOpacity(.025),

                blurRadius: 16,

                offset: const Offset(0, 5),

              ),

            ],

          ),

          child: Row(

            children: [

              Container(

                width: 44,

                height: 44,

                decoration: BoxDecoration(

                  color: _purple.withOpacity(.09),

                  borderRadius: BorderRadius.circular(14),

                ),

                child: const Icon(

                  Icons.work_history_outlined,

                  color: _purple,

                  size: 22,

                ),

              ),

              const SizedBox(width: 12),

              const Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      'Daily Work',

                      style: TextStyle(

                        color: _text,

                        fontSize: 13,

                        fontWeight: FontWeight.w900,

                      ),

                    ),

                    SizedBox(height: 3),

                    Text(

                      'Record what you completed today with proof.',

                      style: TextStyle(

                        color: _muted,

                        fontSize: 10,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                  ],

                ),

              ),

              const Icon(

                Icons.arrow_forward_ios_rounded,

                size: 13,

                color: _muted,

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildTeamMemberDailyWorkHistoryAction() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _openMyDailyWorkHistory,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.025),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: _primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Work History',
                      style: TextStyle(
                        color: _text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'View your submitted daily work and proof.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamMemberTaskStats({

    required int total,

    required int backlog,

    required int todo,

    required int inProgress,

    required int inReview,

    required int changes,

    required int completed,

    required int blocked,

    required int overdue,

  }) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        _buildSectionTitle(

          'Task overview',

          'Complete breakdown of your assigned tasks.',

        ),

        const SizedBox(height: 12),

        GridView.count(

          crossAxisCount: 2,

          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          crossAxisSpacing: 10,

          mainAxisSpacing: 10,

          childAspectRatio: 1.7,

          children: [

            _statCard(

              icon: Icons.task_alt_rounded,

              value: '$total',

              label: 'Total tasks',

              color: _primary,

            ),

            _statCard(

              icon: Icons.inventory_2_outlined,

              value: '$backlog',

              label: 'Backlog',

              color: _muted,

            ),

            _statCard(

              icon: Icons.radio_button_unchecked_rounded,

              value: '$todo',

              label: 'To do',

              color: _blue,

            ),

            _statCard(

              icon: Icons.timelapse_rounded,

              value: '$inProgress',

              label: 'In progress',

              color: _primary,

            ),

            _statCard(

              icon: Icons.rate_review_outlined,

              value: '$inReview',

              label: 'In review',

              color: _purple,

            ),

            _statCard(

              icon: Icons.change_circle_outlined,

              value: '$changes',

              label: 'Changes requested',

              color: _orange,

            ),

            _statCard(

              icon: Icons.check_circle_outline_rounded,

              value: '$completed',

              label: 'Completed',

              color: _green,

            ),

            _statCard(

              icon: Icons.block_outlined,

              value: '$blocked',

              label: 'Blocked',

              color: _red,

            ),

            _statCard(

              icon: Icons.warning_amber_rounded,

              value: '$overdue',

              label: 'Overdue',

              color: _red,

            ),

          ],

        ),

      ],

    );

  }



  Widget _buildTeamMemberProjectStats({

    required int total,

    required int active,

    required int completed,

    required int onHold,

    required int draft,

  }) {

    return GridView.count(

      crossAxisCount: 2,

      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      crossAxisSpacing: 10,

      mainAxisSpacing: 10,

      childAspectRatio: 1.75,

      children: [

        _statCard(

          icon: Icons.folder_copy_outlined,

          value: '$total',

          label: 'Total projects',

          color: _blue,

        ),

        _statCard(

          icon: Icons.play_circle_outline_rounded,

          value: '$active',

          label: 'Active / planning',

          color: _green,

        ),

        _statCard(

          icon: Icons.check_circle_outline_rounded,

          value: '$completed',

          label: 'Completed',

          color: _purple,

        ),

        _statCard(

          icon: Icons.pause_circle_outline_rounded,

          value: '$onHold',

          label: 'On hold',

          color: _orange,

        ),

        _statCard(

          icon: Icons.edit_note_rounded,

          value: '$draft',

          label: 'Draft',

          color: _muted,

        ),

      ],

    );

  }



  Widget _buildProjectSnapshotForMember(List<Project> projects) {

    final visible = projects

        .where((project) => project.status != ProjectStatus.archived)

        .toList()

      ..sort(

        (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(

          a.updatedAt ?? DateTime(1970),

        ),

      );



    return _cardSection(

      title: 'Assigned projects',

      subtitle: 'All your current project assignments.',

      icon: Icons.folder_open_rounded,

      trailing: TextButton(

        onPressed: _openProjects,

        child: const Text(

          'View all',

          style: TextStyle(

            color: _primary,

            fontSize: 11,

            fontWeight: FontWeight.w800,

          ),

        ),

      ),

      child: visible.isEmpty

          ? _emptyInline(

              Icons.folder_off_outlined,

              'No assigned projects',

              'Projects assigned to you will appear here.',

            )

          : Column(

              children: visible.map((project) => _projectTile(project)).toList(),

            ),

    );

  }



  Widget _miniMetricRow({

    required IconData icon,

    required String label,

    required String value,

    required Color color,

  }) {

    return Container(

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(

        color: const Color(0xFFF9FAFC),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: _border),

      ),

      child: Row(

        children: [

          Container(

            width: 36,

            height: 36,

            decoration: BoxDecoration(

              color: color.withOpacity(.09),

              borderRadius: BorderRadius.circular(11),

            ),

            child: Icon(icon, color: color, size: 19),

          ),

          const SizedBox(width: 10),

          Expanded(

            child: Text(

              label,

              style: const TextStyle(

                color: _text,

                fontSize: 12,

                fontWeight: FontWeight.w800,

              ),

            ),

          ),

          Text(

            value,

            style: TextStyle(

              color: color,

              fontSize: 18,

              fontWeight: FontWeight.w900,

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildSalesDashboard() {



    return StreamBuilder<List<Task>>(



      stream: _taskService.watchMyTasks(),



      builder: (context, snapshot) {



        final tasks = snapshot.data ?? <Task>[];







        return ListView(



          physics: const AlwaysScrollableScrollPhysics(),



          padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),



          children: [



            _buildWelcome(),



            const SizedBox(height: 18),



            _buildSalesHero(tasks),



            const SizedBox(height: 18),



            _buildStats(tasks, const <Project>[]),



            const SizedBox(height: 24),



            _buildSectionTitle(



              'CRM workspace',



              'Your sales work and team tasks in one place.',



            ),



            const SizedBox(height: 12),



            _buildSalesActions(),



            const SizedBox(height: 24),



            _buildTaskSnapshot(tasks),



          ],



        );



      },



    );



  }







  Widget _buildWelcome() {



    return Row(



      children: [



        Expanded(



          child: Column(



            crossAxisAlignment: CrossAxisAlignment.start,



            children: [



              Text(



                '$_greeting, $_displayName',



                style: const TextStyle(



                  color: _text,



                  fontSize: 25,



                  fontWeight: FontWeight.w900,



                  letterSpacing: -.8,



                ),



              ),



              const SizedBox(height: 5),



              Text(



                DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),



                style: const TextStyle(



                  color: _muted,



                  fontSize: 12,



                  fontWeight: FontWeight.w600,



                ),



              ),



            ],



          ),



        ),



        _roleBadge(),



      ],



    );



  }







  Widget _roleBadge() {



    final user = _currentUser;



    if (user == null) return const SizedBox.shrink();







    return Container(



      padding: const EdgeInsets.symmetric(



        horizontal: 10,



        vertical: 7,



      ),



      decoration: BoxDecoration(



        color: _primary.withOpacity(.08),



        borderRadius: BorderRadius.circular(12),



        border: Border.all(



          color: _primary.withOpacity(.12),



        ),



      ),



      child: Text(



        user.roleLabel.toUpperCase(),



        style: const TextStyle(



          color: _primaryDark,



          fontSize: 9,



          fontWeight: FontWeight.w900,



          letterSpacing: .4,



        ),



      ),



    );



  }







  Widget _buildHeadlineCard(



    List<Project> projects,



    List<Task> tasks,



  ) {



    final activeProjects = projects



        .where((p) => p.status == ProjectStatus.active)



        .length;







    final inProgress = tasks



        .where((t) => t.status == TaskStatus.inProgress)



        .length;







    final overdue = tasks.where(_isOverdue).length;







    return Container(



      padding: const EdgeInsets.all(20),



      decoration: BoxDecoration(



        gradient: const LinearGradient(



          colors: [_primaryDark, _primary],



          begin: Alignment.topLeft,



          end: Alignment.bottomRight,



        ),



        borderRadius: BorderRadius.circular(26),



        boxShadow: [



          BoxShadow(



            color: _primary.withOpacity(.20),



            blurRadius: 28,



            offset: const Offset(0, 14),



          ),



        ],



      ),



      child: Column(



        crossAxisAlignment: CrossAxisAlignment.start,



        children: [



          Row(



            children: [



              Container(



                width: 42,



                height: 42,



                decoration: BoxDecoration(



                  color: Colors.white.withOpacity(.14),



                  borderRadius: BorderRadius.circular(14),



                ),



                child: const Icon(



                  Icons.dashboard_customize_rounded,



                  color: Colors.white,



                ),



              ),



              const Spacer(),



              _whitePill(



                _isManagement ? 'Management view' : 'My workspace',



              ),



            ],



          ),



          const SizedBox(height: 20),



          Text(



            _isManagement



                ? 'Keep the whole business moving.'



                : 'Focus on the work assigned to you.',



            style: const TextStyle(



              color: Colors.white,



              fontSize: 21,



              height: 1.15,



              fontWeight: FontWeight.w900,



              letterSpacing: -.5,



            ),



          ),



          const SizedBox(height: 8),



          Text(



            _isManagement



                ? 'Monitor projects, tasks and team workload from one place.'



                : 'See priorities, deadlines and project progress without switching screens.',



            style: TextStyle(



              color: Colors.white.withOpacity(.78),



              fontSize: 12,



              height: 1.5,



              fontWeight: FontWeight.w500,



            ),



          ),



          const SizedBox(height: 20),



          Row(



            children: [



              _heroMetric(



                '$activeProjects',



                'Active projects',



              ),



              _heroMetric(



                '$inProgress',



                'In progress',



              ),



              _heroMetric(



                '$overdue',



                'Overdue',



              ),



            ],



          ),



        ],



      ),



    );



  }







  Widget _buildSalesHero(List<Task> tasks) {



    final overdue = tasks.where(_isOverdue).length;



    final today = tasks.where(_isDueToday).length;



    final completed = tasks



        .where((t) => t.status == TaskStatus.completed)



        .length;







    return Container(



      padding: const EdgeInsets.all(20),



      decoration: BoxDecoration(



        gradient: const LinearGradient(



          colors: [_primaryDark, _primary],



        ),



        borderRadius: BorderRadius.circular(26),



      ),



      child: Column(



        crossAxisAlignment: CrossAxisAlignment.start,



        children: [



          const Text(



            'Your workday at a glance',



            style: TextStyle(



              color: Colors.white,



              fontSize: 21,



              fontWeight: FontWeight.w900,



            ),



          ),



          const SizedBox(height: 7),



          Text(



            'CRM work stays focused while project tasks remain visible.',



            style: TextStyle(



              color: Colors.white.withOpacity(.78),



              fontSize: 12,



            ),



          ),



          const SizedBox(height: 20),



          Row(



            children: [



              _heroMetric('$today', 'Due today'),



              _heroMetric('$overdue', 'Overdue'),



              _heroMetric('$completed', 'Completed'),



            ],



          ),



        ],



      ),



    );



  }







  Widget _heroMetric(String value, String label) {



    return Expanded(



      child: Column(



        crossAxisAlignment: CrossAxisAlignment.start,



        children: [



          Text(



            value,



            style: const TextStyle(



              color: Colors.white,



              fontSize: 20,



              fontWeight: FontWeight.w900,



            ),



          ),



          const SizedBox(height: 2),



          Text(



            label,



            style: TextStyle(



              color: Colors.white.withOpacity(.68),



              fontSize: 9,



              fontWeight: FontWeight.w700,



            ),



          ),



        ],



      ),



    );



  }







  Widget _whitePill(String label) {



    return Container(



      padding: const EdgeInsets.symmetric(



        horizontal: 10,



        vertical: 6,



      ),



      decoration: BoxDecoration(



        color: Colors.white.withOpacity(.13),



        borderRadius: BorderRadius.circular(30),



        border: Border.all(



          color: Colors.white.withOpacity(.14),



        ),



      ),



      child: Text(



        label,



        style: const TextStyle(



          color: Colors.white,



          fontSize: 9,



          fontWeight: FontWeight.w800,



        ),



      ),



    );



  }







  Widget _buildStats(



    List<Task> tasks,



    List<Project> projects,



  ) {



    final completed = tasks



        .where((t) => t.status == TaskStatus.completed)



        .length;



    final review = tasks



        .where((t) => t.status == TaskStatus.inReview)



        .length;



    final overdue = tasks.where(_isOverdue).length;



    final activeProjects = projects



        .where(



          (p) =>



              p.status == ProjectStatus.active ||



              p.status == ProjectStatus.planning,



        )



        .length;







    return GridView.count(



      crossAxisCount: 2,



      shrinkWrap: true,



      physics: const NeverScrollableScrollPhysics(),



      crossAxisSpacing: 10,



      mainAxisSpacing: 10,



      childAspectRatio: 1.75,



      children: [



        _statCard(



          icon: Icons.task_alt_rounded,



          value: '${tasks.length}',



          label: 'Total tasks',



          color: _primary,



        ),



        _statCard(



          icon: Icons.timelapse_rounded,



          value: '$review',



          label: 'In review',



          color: _purple,



        ),



        _statCard(



          icon: Icons.warning_amber_rounded,



          value: '$overdue',



          label: 'Overdue',



          color: _red,



        ),



        _statCard(



          icon: Icons.check_circle_outline_rounded,



          value: '$completed',



          label: 'Completed',



          color: _green,



        ),



        if (projects.isNotEmpty)



          _statCard(



            icon: Icons.folder_open_rounded,



            value: '$activeProjects',



            label: 'Active projects',



            color: _blue,



          ),



      ],



    );



  }







  Widget _statCard({



    required IconData icon,



    required String value,



    required String label,



    required Color color,



  }) {



    return Container(



      padding: const EdgeInsets.all(14),



      decoration: _cardDecoration(),



      child: Row(



        children: [



          Container(



            width: 38,



            height: 38,



            decoration: BoxDecoration(



              color: color.withOpacity(.09),



              borderRadius: BorderRadius.circular(12),



            ),



            child: Icon(icon, color: color, size: 20),



          ),



          const SizedBox(width: 10),



          Expanded(



            child: Column(



              crossAxisAlignment: CrossAxisAlignment.start,



              mainAxisAlignment: MainAxisAlignment.center,



              children: [



                Text(



                  value,



                  style: const TextStyle(



                    color: _text,



                    fontSize: 19,



                    fontWeight: FontWeight.w900,



                  ),



                ),



                const SizedBox(height: 2),



                Text(



                  label,



                  maxLines: 1,



                  overflow: TextOverflow.ellipsis,



                  style: const TextStyle(



                    color: _muted,



                    fontSize: 9,



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







  Widget _buildSectionTitle(String title, String subtitle) {



    return Column(



      crossAxisAlignment: CrossAxisAlignment.start,



      children: [



        Text(



          title,



          style: const TextStyle(



            color: _text,



            fontSize: 17,



            fontWeight: FontWeight.w900,



          ),



        ),



        const SizedBox(height: 3),



        Text(



          subtitle,



          style: const TextStyle(



            color: _muted,



            fontSize: 11,



            fontWeight: FontWeight.w500,



          ),



        ),



      ],



    );



  }







  Widget _buildQuickActions() {



    final actions = <_DashboardAction>[



      _DashboardAction(



        'My Work',



        'Tasks & deadlines',



        Icons.task_alt_rounded,



        _primary,



        _openMyWork,



      ),



      _DashboardAction(



        'Projects',



        'Project workspace',



        Icons.folder_copy_outlined,



        _blue,



        _openProjects,



      ),



      if (_isManagement)



        _DashboardAction(



          'Team',



          'Employees',



          Icons.groups_2_outlined,



          _purple,



          _openTeam,



        ),



      _DashboardAction(

        'Daily Work',

        _isManagement ? 'Employee work' : "Submit today's work",

        Icons.work_history_outlined,

        _purple,

        _isManagement ? _openTeamDailyWork : _openDailyWork,

      ),
      if (!_isManagement)
        _DashboardAction(

          'Work History',

          'View your submitted work',

          Icons.history_rounded,

          _primary,

          _openMyDailyWorkHistory,

        ),
      _DashboardAction(
  'Wedding Invitation',
  'Create & preview',
  Icons.card_giftcard_rounded,
  const Color(0xFFB8893C),
  _openWeddingInvitation,
),

      _DashboardAction(

        'Attendance',

        'Check in & check out',

        Icons.access_time_filled_rounded,

        _green,

        _openAttendance,

      ),

    ];







    return GridView.builder(



      itemCount: actions.length,



      shrinkWrap: true,



      physics: const NeverScrollableScrollPhysics(),



      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(



        crossAxisCount: 2,



        crossAxisSpacing: 10,



        mainAxisSpacing: 10,



        childAspectRatio: 2.2,



      ),



      itemBuilder: (_, index) {



        final action = actions[index];



        return _actionCard(action);



      },



    );



  }







  Widget _buildSalesActions() {



    return GridView.count(



      crossAxisCount: 2,



      shrinkWrap: true,



      physics: const NeverScrollableScrollPhysics(),



      crossAxisSpacing: 10,



      mainAxisSpacing: 10,



      childAspectRatio: 2.05,



      children: [



        _actionCard(



          _DashboardAction(



            'My Work',



            'Tasks & deadlines',



            Icons.task_alt_rounded,



            _primary,



            _openMyWork,



          ),



        ),



        _actionCard(



          _DashboardAction(



            'Projects',



            'Assigned projects',



            Icons.folder_copy_outlined,



            _blue,



            _openProjects,



          ),



        ),



      ],



    );



  }







  Widget _actionCard(_DashboardAction action) {



    return Material(



      color: Colors.white,



      borderRadius: BorderRadius.circular(18),



      child: InkWell(



        onTap: action.onTap,



        borderRadius: BorderRadius.circular(18),



        child: Container(



          padding: const EdgeInsets.all(13),



          decoration: BoxDecoration(



            borderRadius: BorderRadius.circular(18),



            border: Border.all(color: _border),



          ),



          child: Row(



            children: [



              Container(



                width: 39,



                height: 39,



                decoration: BoxDecoration(



                  color: action.color.withOpacity(.09),



                  borderRadius: BorderRadius.circular(12),



                ),



                child: Icon(



                  action.icon,



                  color: action.color,



                  size: 20,



                ),



              ),



              const SizedBox(width: 10),



              Expanded(



                child: Column(



                  mainAxisAlignment: MainAxisAlignment.center,



                  crossAxisAlignment: CrossAxisAlignment.start,



                  children: [



                    Text(



                      action.title,



                      maxLines: 1,



                      overflow: TextOverflow.ellipsis,



                      style: const TextStyle(



                        color: _text,



                        fontSize: 12,



                        fontWeight: FontWeight.w900,



                      ),



                    ),



                    const SizedBox(height: 3),



                    Text(



                      action.subtitle,



                      maxLines: 1,



                      overflow: TextOverflow.ellipsis,



                      style: const TextStyle(



                        color: _muted,



                        fontSize: 9,



                        fontWeight: FontWeight.w600,



                      ),



                    ),



                  ],



                ),



              ),



              const Icon(



                Icons.arrow_forward_ios_rounded,



                size: 12,



                color: _muted,



              ),



            ],



          ),



        ),



      ),



    );



  }







  Widget _buildTaskSnapshot(List<Task> tasks) {



    final visible = tasks



        .where(



          (task) =>



              task.status != TaskStatus.completed &&



              task.status != TaskStatus.cancelled,



        )



        .toList()



      ..sort((a, b) {



        final aOverdue = _isOverdue(a);



        final bOverdue = _isOverdue(b);







        if (aOverdue != bOverdue) {



          return aOverdue ? -1 : 1;



        }







        final ad = a.dueDate ?? DateTime(2099);



        final bd = b.dueDate ?? DateTime(2099);



        return ad.compareTo(bd);



      });







    final items = visible.take(5).toList();







    return _cardSection(



      title: 'Priority tasks',



      subtitle: 'The next work items that need attention.',



      icon: Icons.bolt_rounded,



      child: items.isEmpty



          ? _emptyInline(



              Icons.task_alt_rounded,



              'No pending tasks',



              'You are all caught up.',



            )



          : Column(



              children: items



                  .map((task) => _taskTile(task))



                  .toList(),



            ),



    );



  }







  Widget _taskTile(Task task) {



    final overdue = _isOverdue(task);



    final dueToday = _isDueToday(task);







    return InkWell(



      onTap: _openMyWork,



      borderRadius: BorderRadius.circular(14),



      child: Container(



        margin: const EdgeInsets.only(bottom: 9),



        padding: const EdgeInsets.all(12),



        decoration: BoxDecoration(



          color: const Color(0xFFF9FAFC),



          borderRadius: BorderRadius.circular(15),



          border: Border.all(



            color: overdue



                ? _red.withOpacity(.18)



                : _border,



          ),



        ),



        child: Row(



          children: [



            Container(



              width: 38,



              height: 38,



              decoration: BoxDecoration(



                color: _taskColor(task).withOpacity(.09),



                borderRadius: BorderRadius.circular(12),



              ),



              child: Icon(



                _taskIcon(task),



                color: _taskColor(task),



                size: 19,



              ),



            ),



            const SizedBox(width: 11),



            Expanded(



              child: Column(



                crossAxisAlignment: CrossAxisAlignment.start,



                children: [



                  Text(



                    task.title,



                    maxLines: 1,



                    overflow: TextOverflow.ellipsis,



                    style: const TextStyle(



                      color: _text,



                      fontSize: 12,



                      fontWeight: FontWeight.w800,



                    ),



                  ),



                  const SizedBox(height: 5),



                  Row(



                    children: [



                      _miniPill(



                        _taskStatusLabel(task.status),



                        _taskStatusColor(task.status),



                      ),



                      const SizedBox(width: 5),



                      if (task.dueDate != null)



                        _miniPill(



                          overdue



                              ? 'OVERDUE'



                              : dueToday



                                  ? 'TODAY'



                                  : DateFormat(



                                      'dd MMM',



                                    ).format(task.dueDate!),



                          overdue



                              ? _red



                              : dueToday



                                  ? _orange



                                  : _muted,



                        ),



                    ],



                  ),



                ],



              ),



            ),



            const SizedBox(width: 8),



            SizedBox(



              width: 42,



              child: Text(



                '${task.completionPercentage.round()}%',



                textAlign: TextAlign.right,



                style: const TextStyle(



                  color: _text,



                  fontSize: 11,



                  fontWeight: FontWeight.w900,



                ),



              ),



            ),



          ],



        ),



      ),



    );



  }







  Widget _buildProjectSnapshot(List<Project> projects) {



    final visible = projects



        .where(



          (project) =>



              project.status != ProjectStatus.archived,



        )



        .toList()



      ..sort(



        (a, b) => b.updatedAt



            ?.compareTo(a.updatedAt ?? DateTime(1970)) ??



            0,



      );







    final items = visible.take(4).toList();







    return _cardSection(



      title: 'Projects',



      subtitle: 'Your most relevant project work.',



      icon: Icons.folder_open_rounded,



      trailing: TextButton(



        onPressed: _openProjects,



        child: const Text(



          'View all',



          style: TextStyle(



            color: _primary,



            fontSize: 11,



            fontWeight: FontWeight.w800,



          ),



        ),



      ),



      child: items.isEmpty



          ? _emptyInline(



              Icons.folder_off_outlined,



              'No projects yet',



              _isManagement



                  ? 'Create your first project to get started.'



                  : 'Projects assigned to you will appear here.',



            )



          : Column(



              children: items



                  .map((project) => _projectTile(project))



                  .toList(),



            ),



    );



  }







  Widget _projectTile(Project project) {



    final color = _projectColor(project);







    return InkWell(



      onTap: _openProjects,



      borderRadius: BorderRadius.circular(14),



      child: Container(



        margin: const EdgeInsets.only(bottom: 9),



        padding: const EdgeInsets.all(12),



        decoration: BoxDecoration(



          color: const Color(0xFFF9FAFC),



          borderRadius: BorderRadius.circular(15),



          border: Border.all(color: _border),



        ),



        child: Row(



          children: [



            Container(



              width: 39,



              height: 39,



              decoration: BoxDecoration(



                color: color.withOpacity(.10),



                borderRadius: BorderRadius.circular(12),



              ),



              child: Icon(



                Icons.folder_rounded,



                color: color,



                size: 19,



              ),



            ),



            const SizedBox(width: 11),



            Expanded(



              child: Column(



                crossAxisAlignment: CrossAxisAlignment.start,



                children: [



                  Text(



                    project.name,



                    maxLines: 1,



                    overflow: TextOverflow.ellipsis,



                    style: const TextStyle(



                      color: _text,



                      fontSize: 12,



                      fontWeight: FontWeight.w800,



                    ),



                  ),



                  const SizedBox(height: 5),



                  Row(



                    children: [



                      _miniPill(



                        _projectStatusLabel(project.status),



                        _projectStatusColor(project.status),



                      ),



                      const SizedBox(width: 5),



                      Text(



                        '${project.progress.round()}%',



                        style: const TextStyle(



                          color: _muted,



                          fontSize: 9,



                          fontWeight: FontWeight.w800,



                        ),



                      ),



                    ],



                  ),



                ],



              ),



            ),



            SizedBox(



              width: 58,



              child: ClipRRect(



                borderRadius: BorderRadius.circular(20),



                child: LinearProgressIndicator(



                  value: (project.progress / 100)



                      .clamp(0.0, 1.0),



                  minHeight: 6,



                  backgroundColor: const Color(0xFFE5E7EF),



                  valueColor:



                      AlwaysStoppedAnimation<Color>(color),



                ),



              ),



            ),



          ],



        ),



      ),



    );



  }







  Widget _buildTeamSnapshot() {



    return StreamBuilder<List<AppUser>>(



      stream: _teamService.watchAllEmployees(),



      builder: (context, snapshot) {



        final employees = snapshot.data ?? <AppUser>[];



        final active = employees.where((e) => e.isActive).length;



        final inactive =



            employees.where((e) => !e.isActive).length;



        final management =



            employees.where((e) => e.isManagement).length;







        return _cardSection(



          title: 'Team overview',



          subtitle: 'A quick view of the organisation.',



          icon: Icons.groups_2_outlined,



          trailing: TextButton(



            onPressed: _openTeam,



            child: const Text(



              'Manage',



              style: TextStyle(



                color: _primary,



                fontSize: 11,



                fontWeight: FontWeight.w800,



              ),



            ),



          ),



          child: Row(



            children: [



              Expanded(



                child: _teamMetric(



                  '${employees.length}',



                  'Employees',



                  _primary,



                ),



              ),



              Expanded(



                child: _teamMetric(



                  '$active',



                  'Active',



                  _green,



                ),



              ),



              Expanded(



                child: _teamMetric(



                  '$inactive',



                  'Inactive',



                  _red,



                ),



              ),



              Expanded(



                child: _teamMetric(



                  '$management',



                  'Management',



                  _purple,



                ),



              ),



            ],



          ),



        );



      },



    );



  }







  Widget _teamMetric(



    String value,



    String label,



    Color color,



  ) {



    return Column(



      children: [



        Text(



          value,



          style: TextStyle(



            color: color,



            fontSize: 20,



            fontWeight: FontWeight.w900,



          ),



        ),



        const SizedBox(height: 3),



        Text(



          label,



          textAlign: TextAlign.center,



          style: const TextStyle(



            color: _muted,



            fontSize: 8,



            fontWeight: FontWeight.w700,



          ),



        ),



      ],



    );



  }







  Widget _cardSection({



    required String title,



    required String subtitle,



    required IconData icon,



    required Widget child,



    Widget? trailing,



  }) {



    return Container(



      padding: const EdgeInsets.all(15),



      decoration: _cardDecoration(),



      child: Column(



        crossAxisAlignment: CrossAxisAlignment.start,



        children: [



          Row(



            children: [



              Container(



                width: 34,



                height: 34,



                decoration: BoxDecoration(



                  color: _primary.withOpacity(.08),



                  borderRadius: BorderRadius.circular(11),



                ),



                child: Icon(



                  icon,



                  color: _primary,



                  size: 18,



                ),



              ),



              const SizedBox(width: 10),



              Expanded(



                child: Column(



                  crossAxisAlignment:



                      CrossAxisAlignment.start,



                  children: [



                    Text(



                      title,



                      style: const TextStyle(



                        color: _text,



                        fontSize: 13,



                        fontWeight: FontWeight.w900,



                      ),



                    ),



                    const SizedBox(height: 2),



                    Text(



                      subtitle,



                      style: const TextStyle(



                        color: _muted,



                        fontSize: 9,



                        fontWeight: FontWeight.w500,



                      ),



                    ),



                  ],



                ),



              ),



              if (trailing != null) trailing,



            ],



          ),



          const SizedBox(height: 14),



          child,



        ],



      ),



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



        horizontal: 16,



        vertical: 22,



      ),



      decoration: BoxDecoration(



        color: const Color(0xFFF9FAFC),



        borderRadius: BorderRadius.circular(15),



        border: Border.all(color: _border),



      ),



      child: Column(



        children: [



          Icon(icon, color: _muted, size: 28),



          const SizedBox(height: 8),



          Text(



            title,



            style: const TextStyle(



              color: _text,



              fontSize: 12,



              fontWeight: FontWeight.w800,



            ),



          ),



          const SizedBox(height: 3),



          Text(



            subtitle,



            textAlign: TextAlign.center,



            style: const TextStyle(



              color: _muted,



              fontSize: 9,



              fontWeight: FontWeight.w500,



            ),



          ),



        ],



      ),



    );



  }







  Widget _buildError(String message) {



    return ListView(



      physics: const AlwaysScrollableScrollPhysics(),



      padding: const EdgeInsets.all(24),



      children: [



        const SizedBox(height: 90),



        const Icon(



          Icons.cloud_off_rounded,



          size: 50,



          color: _red,



        ),



        const SizedBox(height: 14),



        const Text(



          'Dashboard unavailable',



          textAlign: TextAlign.center,



          style: TextStyle(



            color: _text,



            fontSize: 18,



            fontWeight: FontWeight.w900,



          ),



        ),



        const SizedBox(height: 7),



        Text(



          message,



          textAlign: TextAlign.center,



          style: const TextStyle(



            color: _muted,



            fontSize: 11,



          ),



        ),



        const SizedBox(height: 18),



        Center(



          child: ElevatedButton.icon(



            onPressed: _loadCurrentUser,



            icon: const Icon(Icons.refresh_rounded),



            label: const Text('Retry'),



            style: ElevatedButton.styleFrom(



              backgroundColor: _primary,



              foregroundColor: Colors.white,



              elevation: 0,



              padding: const EdgeInsets.symmetric(



                horizontal: 18,



                vertical: 12,



              ),



              shape: RoundedRectangleBorder(



                borderRadius: BorderRadius.circular(14),



              ),



            ),



          ),



        ),



      ],



    );



  }







  Widget _buildAvatar(AppUser? user) {



    final image = user?.profileImage;







    if (image != null && image.trim().isNotEmpty) {



      return ClipRRect(



        borderRadius: BorderRadius.circular(13),



        child: Image.network(



          image,



          width: 38,



          height: 38,



          fit: BoxFit.cover,



          errorBuilder: (_, __, ___) {



            return _avatarFallback(user);



          },



        ),



      );



    }







    return _avatarFallback(user);



  }







  Widget _avatarFallback(AppUser? user) {



    final name = user?.name.trim() ?? '';



    final initials = name.isEmpty



        ? '?'



        : name



            .split(' ')



            .where((p) => p.trim().isNotEmpty)



            .take(2)



            .map((p) => p[0].toUpperCase())



            .join();







    return Container(



      width: 38,



      height: 38,



      decoration: BoxDecoration(



        gradient: const LinearGradient(



          colors: [_primaryDark, _purple],



        ),



        borderRadius: BorderRadius.circular(13),



      ),



      alignment: Alignment.center,



      child: Text(



        initials,



        style: const TextStyle(



          color: Colors.white,



          fontSize: 12,



          fontWeight: FontWeight.w900,



        ),



      ),



    );



  }







  Widget _miniPill(String label, Color color) {



    return Container(



      padding: const EdgeInsets.symmetric(



        horizontal: 6,



        vertical: 3,



      ),



      decoration: BoxDecoration(



        color: color.withOpacity(.08),



        borderRadius: BorderRadius.circular(6),



      ),



      child: Text(



        label,



        style: TextStyle(



          color: color,



          fontSize: 7,



          fontWeight: FontWeight.w900,



          letterSpacing: .15,



        ),



      ),



    );



  }







  BoxDecoration _cardDecoration() {



    return BoxDecoration(



      color: Colors.white,



      borderRadius: BorderRadius.circular(20),



      border: Border.all(color: _border),



      boxShadow: [



        BoxShadow(



          color: Colors.black.withOpacity(.025),



          blurRadius: 18,



          offset: const Offset(0, 6),



        ),



      ],



    );



  }







  bool _isOverdue(Task task) {



    if (task.dueDate == null ||



        task.status == TaskStatus.completed ||



        task.status == TaskStatus.cancelled) {



      return false;



    }







    final now = DateTime.now();



    final due = task.dueDate!;







    return due.isBefore(



      DateTime(now.year, now.month, now.day),



    );



  }







  bool _isDueToday(Task task) {



    if (task.dueDate == null ||



        task.status == TaskStatus.completed ||



        task.status == TaskStatus.cancelled) {



      return false;



    }







    final now = DateTime.now();



    final due = task.dueDate!;







    return now.year == due.year &&



        now.month == due.month &&



        now.day == due.day;



  }







  Color _taskColor(Task task) {



    switch (task.priority) {



      case TaskPriority.low:



        return _muted;



      case TaskPriority.medium:



        return _blue;



      case TaskPriority.high:



        return _orange;



      case TaskPriority.urgent:



        return _red;



    }



  }







  IconData _taskIcon(Task task) {



    switch (task.status) {



      case TaskStatus.backlog:



        return Icons.inventory_2_outlined;



      case TaskStatus.todo:



        return Icons.radio_button_unchecked_rounded;



      case TaskStatus.inProgress:



        return Icons.timelapse_rounded;



      case TaskStatus.inReview:



        return Icons.rate_review_outlined;



      case TaskStatus.changesRequested:



        return Icons.change_circle_outlined;



      case TaskStatus.completed:



        return Icons.check_circle_outline_rounded;



      case TaskStatus.blocked:



        return Icons.block_outlined;



      case TaskStatus.cancelled:



        return Icons.cancel_outlined;



    }



  }







  String _taskStatusLabel(TaskStatus status) {



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



        return 'Changes';



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



        return _muted;



      case TaskStatus.todo:



        return _blue;



      case TaskStatus.inProgress:



        return _primary;



      case TaskStatus.inReview:



        return _purple;



      case TaskStatus.changesRequested:



        return _orange;



      case TaskStatus.completed:



        return _green;



      case TaskStatus.blocked:



        return _red;



      case TaskStatus.cancelled:



        return _muted;



    }



  }







  String _projectStatusLabel(ProjectStatus status) {



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







  Color _projectStatusColor(ProjectStatus status) {



    switch (status) {



      case ProjectStatus.draft:



        return _muted;



      case ProjectStatus.planning:



        return _blue;



      case ProjectStatus.active:



        return _green;



      case ProjectStatus.onHold:



        return _orange;



      case ProjectStatus.completed:



        return _purple;



      case ProjectStatus.archived:



        return _muted;



    }



  }







  Color _projectColor(Project project) {



    final raw = project.color?.trim() ?? '';



    if (raw.isEmpty) return _primary;







    final hex = raw.replaceFirst('#', '');



    if (hex.length != 6) return _primary;







    final value = int.tryParse(hex, radix: 16);



    if (value == null) return _primary;







    return Color(0xFF000000 | value);



  }







  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Logout?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Are you sure you want to logout from Syteos Business?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    try {
      await AuthService.instance.signOut();
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }



  void _openAttendance() {

    Navigator.of(context).push(

      MaterialPageRoute(

        builder: (_) => const AttendanceScreen(),

      ),

    );

  }



  void _openMyWork() {



    Navigator.of(context).push(



      MaterialPageRoute(



        builder: (_) => const MyWorkScreen(),



      ),



    );



  }







  void _openProjects() {



    Navigator.of(context).push(



      MaterialPageRoute(



        builder: (_) => const ProjectsScreen(),



      ),



    );



  }







  Future<void> _openDailyWork() async {

    await Navigator.of(context).push(

      MaterialPageRoute(

        builder: (_) => const DailyWorkScreen(),

      ),

    );

  }

  Future<void> _openMyDailyWorkHistory() async {

    await Navigator.of(context).push(

      MaterialPageRoute(

        builder: (_) => const MyDailyWorkHistoryScreen(),

      ),

    );

  }



  Future<void> _openTeamDailyWork() async {

    await Navigator.of(context).push(

      MaterialPageRoute(

        builder: (_) => const TeamDailyWorkScreen(),

      ),

    );

  }
void _openWeddingInvitation() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          const InvitationBuilderScreen(),
    ),
  );
}


  void _openTeam() {



    Navigator.of(context).push(



      MaterialPageRoute(



        builder: (_) => const TeamScreen(),



      ),



    );



  }



}







class _DashboardAction {



  final String title;



  final String subtitle;



  final IconData icon;



  final Color color;



  final VoidCallback onTap;







  const _DashboardAction(



    this.title,



    this.subtitle,



    this.icon,



    this.color,



    this.onTap,



  );



}
