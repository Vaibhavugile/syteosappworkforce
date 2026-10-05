import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



import '../../../models/app_user.dart';
import '../../../models/project.dart';

import '../../../services/project_service.dart';
import '../../../services/team_service.dart';
import 'create_project_screen.dart';
import 'project_details_screen.dart';



class ProjectsScreen extends StatefulWidget {

  const ProjectsScreen({super.key});



  @override

  State<ProjectsScreen> createState() => _ProjectsScreenState();

}



class _ProjectsScreenState extends State<ProjectsScreen> {

  final ProjectService _projectService = ProjectService.instance;
  final TeamService _teamService = TeamService.instance;

  AppUser? _currentUser;
  bool _loadingUser = true;

  bool get _isManagement => _currentUser?.isManagement ?? false;

  final TextEditingController _searchController =

      TextEditingController();



  String _searchQuery = '';

  ProjectStatus? _selectedStatus;

  ProjectPriority? _selectedPriority;



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



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF7F8FC),

      appBar: _buildAppBar(),

      body: StreamBuilder<List<Project>>(

        stream: _projectService.watchAllProjects(),

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



          final projects = snapshot.data ?? [];

          final filteredProjects =

              _filterProjects(projects);



          return RefreshIndicator(

            color: const Color(0xFF6366F1),

            onRefresh: _refresh,

            child: ListView(

              physics:

                  const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(

                20,

                20,

                20,

                40,

              ),

              children: [

                _buildHero(projects),

                const SizedBox(height: 20),

                _buildOverview(projects),

                const SizedBox(height: 24),

                _buildSearch(),

                const SizedBox(height: 12),

                _buildFilters(),

                const SizedBox(height: 24),

                _buildSectionHeader(

                  filteredProjects.length,

                ),

                const SizedBox(height: 12),

                if (filteredProjects.isEmpty)

                  _buildEmptyState()

                else

                  ...filteredProjects.map(

                    _buildProjectCard,

                  ),

              ],

            ),

          );

        },

      ),

      floatingActionButton:

          _buildFloatingActionButton(),

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

        _isManagement ? 'Projects' : 'My Projects',

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

  // HERO

  // ============================================================



  Widget _buildHero(List<Project> projects) {

    final active = projects.where(

      (project) =>

          project.status == ProjectStatus.active,

    ).length;



    final completed = projects.where(

      (project) =>

          project.status == ProjectStatus.completed,

    ).length;



    final averageProgress = projects.isEmpty

        ? 0.0

        : projects.fold<double>(

              0,

              (sum, project) =>

                  sum + project.progress,

            ) /

            projects.length;



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

            color:

                const Color(0xFF6366F1).withOpacity(0.18),

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

              borderRadius: BorderRadius.circular(18),

            ),

            child: const Icon(

              Icons.folder_copy_rounded,

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

                  'Project Management',

                  style: GoogleFonts.manrope(

                    color: Colors.white,

                    fontSize: 19,

                    fontWeight: FontWeight.w800,

                  ),

                ),

                const SizedBox(height: 5),

                Text(

                  '$active active • $completed completed',

                  style: GoogleFonts.manrope(

                    color:

                        Colors.white.withOpacity(0.82),

                    fontSize: 12,

                    fontWeight: FontWeight.w600,

                  ),

                ),

              ],

            ),

          ),

          Column(

            crossAxisAlignment: CrossAxisAlignment.end,

            children: [

              Text(

                '${averageProgress.toStringAsFixed(0)}%',

                style: GoogleFonts.manrope(

                  color: Colors.white,

                  fontSize: 25,

                  fontWeight: FontWeight.w900,

                ),

              ),

              Text(

                'overall progress',

                style: GoogleFonts.manrope(

                  color:

                      Colors.white.withOpacity(0.75),

                  fontSize: 9,

                  fontWeight: FontWeight.w600,

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }



  // ============================================================

  // OVERVIEW

  // ============================================================



  Widget _buildOverview(List<Project> projects) {

    final active = projects

        .where(

          (p) => p.status == ProjectStatus.active,

        )

        .length;



    final planning = projects

        .where(

          (p) => p.status == ProjectStatus.planning,

        )

        .length;



    final onHold = projects

        .where(

          (p) => p.status == ProjectStatus.onHold,

        )

        .length;



    final completed = projects

        .where(

          (p) => p.status == ProjectStatus.completed,

        )

        .length;



    return SizedBox(

      height: 105,

      child: ListView(

        scrollDirection: Axis.horizontal,

        children: [

          _buildOverviewCard(

            title: 'All',

            value: projects.length,

            icon: Icons.folder_rounded,

            color: const Color(0xFF6366F1),

          ),

          const SizedBox(width: 10),

          _buildOverviewCard(

            title: 'Active',

            value: active,

            icon: Icons.play_circle_fill_rounded,

            color: const Color(0xFF10B981),

          ),

          const SizedBox(width: 10),

          _buildOverviewCard(

            title: 'Planning',

            value: planning,

            icon: Icons.edit_calendar_rounded,

            color: const Color(0xFF3B82F6),

          ),

          const SizedBox(width: 10),

          _buildOverviewCard(

            title: 'On Hold',

            value: onHold,

            icon: Icons.pause_circle_filled_rounded,

            color: const Color(0xFFF59E0B),

          ),

          const SizedBox(width: 10),

          _buildOverviewCard(

            title: 'Completed',

            value: completed,

            icon: Icons.check_circle_rounded,

            color: const Color(0xFF8B5CF6),

          ),

        ],

      ),

    );

  }



  Widget _buildOverviewCard({

    required String title,

    required int value,

    required IconData icon,

    required Color color,

  }) {

    return Container(

      width: 125,

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

          Icon(

            icon,

            size: 19,

            color: color,

          ),

          const Spacer(),

          Text(

            value.toString(),

            style: GoogleFonts.manrope(

              fontSize: 20,

              fontWeight: FontWeight.w900,

              color: const Color(0xFF111827),

            ),

          ),

          Text(

            title,

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

  // SEARCH

  // ============================================================



  Widget _buildSearch() {

    return Container(

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

          fontSize: 13,

          fontWeight: FontWeight.w600,

          color: const Color(0xFF111827),

        ),

        decoration: InputDecoration(

          hintText: 'Search projects or clients...',

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

    );

  }



  // ============================================================

  // FILTERS

  // ============================================================



  Widget _buildFilters() {

    return SizedBox(

      height: 40,

      child: ListView(

        scrollDirection: Axis.horizontal,

        children: [

          _buildFilterChip(

            label: 'All status',

            selected: _selectedStatus == null,

            onTap: () {

              setState(() {

                _selectedStatus = null;

              });

            },

          ),

          const SizedBox(width: 8),

          ...ProjectStatus.values.map(

            (status) => Padding(

              padding:

                  const EdgeInsets.only(right: 8),

              child: _buildFilterChip(

                label: _statusLabel(status),

                selected:

                    _selectedStatus == status,

                onTap: () {

                  setState(() {

                    _selectedStatus = status;

                  });

                },

              ),

            ),

          ),

          _buildFilterChip(

            label: 'Priority',

            selected: _selectedPriority != null,

            onTap: _showPriorityFilter,

          ),

        ],

      ),

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



  Future<void> _showPriorityFilter() async {

    final result =

        await showModalBottomSheet<ProjectPriority?>(

      context: context,

      backgroundColor: Colors.transparent,

      builder: (context) {

        return Container(

          padding: const EdgeInsets.fromLTRB(

            20,

            12,

            20,

            24,

          ),

          decoration: const BoxDecoration(

            color: Colors.white,

            borderRadius: BorderRadius.vertical(

              top: Radius.circular(26),

            ),

          ),

          child: SafeArea(

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                Container(

                  width: 42,

                  height: 4,

                  decoration: BoxDecoration(

                    color: const Color(0xFFD1D5DB),

                    borderRadius:

                        BorderRadius.circular(10),

                  ),

                ),

                const SizedBox(height: 20),

                Text(

                  'Filter by Priority',

                  style: GoogleFonts.manrope(

                    fontSize: 17,

                    fontWeight: FontWeight.w800,

                  ),

                ),

                const SizedBox(height: 14),

                ...ProjectPriority.values.map(

                  (priority) {

                    return ListTile(

                      shape: RoundedRectangleBorder(

                        borderRadius:

                            BorderRadius.circular(14),

                      ),

                      title: Text(

                        _priorityLabel(priority),

                        style: GoogleFonts.manrope(

                          fontSize: 13,

                          fontWeight:

                              FontWeight.w700,

                        ),

                      ),

                      trailing:

                          _selectedPriority ==

                                  priority

                              ? const Icon(

                                  Icons.check_circle_rounded,

                                  color:

                                      Color(0xFF4F46E5),

                                )

                              : null,

                      onTap: () {

                        Navigator.of(context)

                            .pop(priority);

                      },

                    );

                  },

                ),

                ListTile(

                  title: Text(

                    'Clear filter',

                    style: GoogleFonts.manrope(

                      fontSize: 13,

                      fontWeight: FontWeight.w700,

                      color: const Color(0xFFEF4444),

                    ),

                  ),

                  onTap: () {

                    Navigator.of(context).pop(null);

                  },

                ),

              ],

            ),

          ),

        );

      },

    );



    setState(() {

      _selectedPriority = result;

    });

  }



  // ============================================================

  // SECTION

  // ============================================================



  Widget _buildSectionHeader(int count) {

    return Row(

      children: [

        Text(

          'Projects',

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

  // PROJECT CARD

  // ============================================================



  Widget _buildProjectCard(Project project) {

    final statusColor =

        _statusColor(project.status);



    final priorityColor =

        _priorityColor(project.priority);



    return Container(

      margin: const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(

          color: const Color(0xFFE5E7EB),

        ),

        boxShadow: [

          BoxShadow(

            color:

                Colors.black.withOpacity(0.025),

            blurRadius: 14,

            offset: const Offset(0, 5),

          ),

        ],

      ),

      child: InkWell(

        borderRadius: BorderRadius.circular(22),

        onTap: () =>

            _openProject(project),

        child: Padding(

          padding: const EdgeInsets.all(17),

          child: Column(

            crossAxisAlignment:

                CrossAxisAlignment.start,

            children: [

              Row(

                crossAxisAlignment:

                    CrossAxisAlignment.start,

                children: [

                  Container(

                    width: 46,

                    height: 46,

                    decoration: BoxDecoration(

                      color: _projectColor(project)

                          .withOpacity(0.10),

                      borderRadius:

                          BorderRadius.circular(14),

                    ),

                    child: Icon(

                      _projectIcon(project),

                      color: _projectColor(project),

                      size: 22,

                    ),

                  ),

                  const SizedBox(width: 12),

                  Expanded(

                    child: Column(

                      crossAxisAlignment:

                          CrossAxisAlignment.start,

                      children: [

                        Text(

                          project.name,

                          maxLines: 2,

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

                        if (project.clientName !=

                                null &&

                            project.clientName!

                                .isNotEmpty) ...[

                          const SizedBox(height: 4),

                          Text(

                            project.clientName!,

                            maxLines: 1,

                            overflow:

                                TextOverflow.ellipsis,

                            style: GoogleFonts.manrope(

                              fontSize: 11,

                              fontWeight:

                                  FontWeight.w600,

                              color:

                                  const Color(0xFF9CA3AF),

                            ),

                          ),

                        ],

                      ],

                    ),

                  ),

                  const SizedBox(width: 8),

                  PopupMenuButton<String>(

                    padding: EdgeInsets.zero,

                    icon: const Icon(

                      Icons.more_horiz_rounded,

                      color: Color(0xFF9CA3AF),

                    ),

                    onSelected: (value) {

                      _handleProjectAction(

                        value,

                        project,

                      );

                    },

                    itemBuilder: (context) => [

                      const PopupMenuItem(

                        value: 'active',

                        child: Text('Mark Active'),

                      ),

                      const PopupMenuItem(

                        value: 'hold',

                        child: Text('Put On Hold'),

                      ),

                      const PopupMenuItem(

                        value: 'complete',

                        child: Text('Complete'),

                      ),

                      const PopupMenuItem(

                        value: 'archive',

                        child: Text('Archive'),

                      ),

                    ],

                  ),

                ],

              ),

              const SizedBox(height: 15),

              Row(

                children: [

                  _buildBadge(

                    _statusLabel(project.status),

                    statusColor,

                  ),

                  const SizedBox(width: 7),

                  _buildBadge(

                    _priorityLabel(

                      project.priority,

                    ),

                    priorityColor,

                  ),

                ],

              ),

              const SizedBox(height: 17),

              Row(

                children: [

                  Text(

                    'Progress',

                    style: GoogleFonts.manrope(

                      fontSize: 11,

                      fontWeight: FontWeight.w700,

                      color:

                          const Color(0xFF6B7280),

                    ),

                  ),

                  const Spacer(),

                  Text(

                    '${project.progress.toStringAsFixed(0)}%',

                    style: GoogleFonts.manrope(

                      fontSize: 11,

                      fontWeight: FontWeight.w800,

                      color:

                          const Color(0xFF374151),

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 8),

              ClipRRect(

                borderRadius:

                    BorderRadius.circular(20),

                child: LinearProgressIndicator(

                  value:

                      (project.progress / 100)

                          .clamp(0, 1),

                  minHeight: 7,

                  backgroundColor:

                      const Color(0xFFF1F5F9),

                  valueColor:

                      AlwaysStoppedAnimation<Color>(

                    statusColor,

                  ),

                ),

              ),

              const SizedBox(height: 15),

              Row(

                children: [

                  _buildMeta(

                    icon:

                        Icons.people_alt_outlined,

                    value:

                        '${project.memberIds.length} members',

                  ),

                  const SizedBox(width: 14),

                  if (project.targetDate !=

                      null)

                    _buildMeta(

                      icon:

                          Icons.event_outlined,

                      value: _formatDate(

                        project.targetDate!,

                      ),

                    ),

                  const Spacer(),

                  const Icon(

                    Icons.chevron_right_rounded,

                    size: 20,

                    color: Color(0xFF9CA3AF),

                  ),

                ],

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildBadge(

    String text,

    Color color,

  ) {

    return Container(

      padding: const EdgeInsets.symmetric(

        horizontal: 9,

        vertical: 5,

      ),

      decoration: BoxDecoration(

        color: color.withOpacity(0.08),

        borderRadius: BorderRadius.circular(8),

      ),

      child: Text(

        text,

        style: GoogleFonts.manrope(

          fontSize: 9,

          fontWeight: FontWeight.w800,

          color: color,

        ),

      ),

    );

  }



  Widget _buildMeta({

    required IconData icon,

    required String value,

  }) {

    return Row(

      mainAxisSize: MainAxisSize.min,

      children: [

        Icon(

          icon,

          size: 15,

          color: const Color(0xFF9CA3AF),

        ),

        const SizedBox(width: 5),

        Text(

          value,

          style: GoogleFonts.manrope(

            fontSize: 10,

            fontWeight: FontWeight.w600,

            color: const Color(0xFF6B7280),

          ),

        ),

      ],

    );

  }



  // ============================================================

  // FILTER LOGIC

  // ============================================================



  List<Project> _filterProjects(

    List<Project> projects,

  ) {

    return projects.where((project) {

      if (_selectedStatus != null &&

          project.status != _selectedStatus) {

        return false;

      }



      if (_selectedPriority != null &&

          project.priority != _selectedPriority) {

        return false;

      }



      if (_searchQuery.isNotEmpty) {

        final name =

            project.name.toLowerCase();

        final description =

            (project.description ?? '')

                .toLowerCase();

        final client =

            (project.clientName ?? '')

                .toLowerCase();



        if (!name.contains(_searchQuery) &&

            !description.contains(_searchQuery) &&

            !client.contains(_searchQuery)) {

          return false;

        }

      }



      return true;

    }).toList();

  }



  // ============================================================

  // ACTIONS

  // ============================================================



  Future<void> _handleProjectAction(

    String action,

    Project project,

  ) async {

    try {

      switch (action) {

        case 'active':

          await _projectService.startProject(

            project.projectId,

          );

          break;



        case 'hold':

          await _projectService.putProjectOnHold(

            project.projectId,

          );

          break;



        case 'complete':

          await _projectService.completeProject(

            project.projectId,

          );

          break;



        case 'archive':

          await _projectService.archiveProject(

            project.projectId,

          );

          break;

      }



      if (!mounted) return;



      _showSnack(

        'Project updated successfully.',

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

    }

  }



  void _openProject(Project project) {

    // Project details screen will be connected

    // in the next step.

    _showProjectPreview(project);

  }



  // ============================================================

  // PROJECT PREVIEW

  // ============================================================



  void _showProjectPreview(Project project) {

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (context) {

        return Container(

          constraints: const BoxConstraints(

            maxHeight: 680,

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

                28,

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

                        color:

                            const Color(0xFFD1D5DB),

                        borderRadius:

                            BorderRadius.circular(10),

                      ),

                    ),

                  ),

                  const SizedBox(height: 22),

                  Row(

                    children: [

                      Container(

                        width: 52,

                        height: 52,

                        decoration: BoxDecoration(

                          color: _projectColor(

                            project,

                          ).withOpacity(0.10),

                          borderRadius:

                              BorderRadius.circular(16),

                        ),

                        child: Icon(

                          _projectIcon(project),

                          color: _projectColor(

                            project,

                          ),

                          size: 25,

                        ),

                      ),

                      const SizedBox(width: 14),

                      Expanded(

                        child: Column(

                          crossAxisAlignment:

                              CrossAxisAlignment.start,

                          children: [

                            Text(

                              project.name,

                              style:

                                  GoogleFonts.manrope(

                                fontSize: 19,

                                fontWeight:

                                    FontWeight.w800,

                                color:

                                    const Color(0xFF111827),

                              ),

                            ),

                            const SizedBox(height: 4),

                            if (project.clientName !=

                                    null &&

                                project.clientName!

                                    .isNotEmpty)

                              Text(

                                project.clientName!,

                                style:

                                    GoogleFonts.manrope(

                                  fontSize: 11,

                                  fontWeight:

                                      FontWeight.w600,

                                  color:

                                      const Color(0xFF9CA3AF),

                                ),

                              ),

                          ],

                        ),

                      ),

                    ],

                  ),

                  const SizedBox(height: 20),

                  Row(

                    children: [

                      _buildBadge(

                        _statusLabel(

                          project.status,

                        ),

                        _statusColor(

                          project.status,

                        ),

                      ),

                      const SizedBox(width: 8),

                      _buildBadge(

                        _priorityLabel(

                          project.priority,

                        ),

                        _priorityColor(

                          project.priority,

                        ),

                      ),

                    ],

                  ),

                  const SizedBox(height: 20),

                  _buildProgressCard(project),

                  const SizedBox(height: 16),

                  if (project.description !=

                          null &&

                      project.description!

                          .isNotEmpty)

                    _buildDetailCard(

                      title: 'Description',

                      child: Text(

                        project.description!,

                        style: GoogleFonts.manrope(

                          fontSize: 12,

                          height: 1.6,

                          fontWeight:

                              FontWeight.w500,

                          color:

                              const Color(0xFF4B5563),

                        ),

                      ),

                    ),

                  if (project.description !=

                          null &&

                      project.description!

                          .isNotEmpty)

                    const SizedBox(height: 16),

                  _buildProjectDates(project),

                  const SizedBox(height: 16),

                  _buildDetailCard(

                    title: 'Team',

                    child: Row(

                      children: [

                        const Icon(

                          Icons.groups_outlined,

                          size: 19,

                          color: Color(0xFF6366F1),

                        ),

                        const SizedBox(width: 9),

                        Text(

                          '${project.memberIds.length} members assigned',

                          style: GoogleFonts.manrope(

                            fontSize: 12,

                            fontWeight:

                                FontWeight.w700,

                            color:

                                const Color(0xFF374151),

                          ),

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(height: 20),

                  SizedBox(

                    width: double.infinity,

                    height: 50,

                    child: OutlinedButton.icon(

                      onPressed: () {

                        Navigator.of(context)

                            .pop();

                      },

                      icon: const Icon(

                        Icons.arrow_forward_rounded,

                      ),

                      label: Text(

                        'Open Project',

                        style: GoogleFonts.manrope(

                          fontSize: 13,

                          fontWeight:

                              FontWeight.w800,

                        ),

                      ),

                      style:

                          OutlinedButton.styleFrom(

                        foregroundColor:

                            const Color(0xFF4F46E5),

                        side: const BorderSide(

                          color: Color(0xFFC7D2FE),

                        ),

                        shape:

                            RoundedRectangleBorder(

                          borderRadius:

                              BorderRadius.circular(15),

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



  Widget _buildProgressCard(Project project) {

    final color = _statusColor(project.status);



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

          Row(

            children: [

              Text(

                'Project Progress',

                style: GoogleFonts.manrope(

                  fontSize: 12,

                  fontWeight: FontWeight.w800,

                  color: const Color(0xFF374151),

                ),

              ),

              const Spacer(),

              Text(

                '${project.progress.toStringAsFixed(0)}%',

                style: GoogleFonts.manrope(

                  fontSize: 14,

                  fontWeight: FontWeight.w900,

                  color: color,

                ),

              ),

            ],

          ),

          const SizedBox(height: 11),

          ClipRRect(

            borderRadius:

                BorderRadius.circular(20),

            child: LinearProgressIndicator(

              value:

                  (project.progress / 100)

                      .clamp(0, 1),

              minHeight: 9,

              backgroundColor:

                  const Color(0xFFE5E7EB),

              valueColor:

                  AlwaysStoppedAnimation<Color>(

                color,

              ),

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildProjectDates(Project project) {

    return _buildDetailCard(

      title: 'Timeline',

      child: Column(

        children: [

          if (project.startDate != null)

            _buildTimelineRow(

              icon: Icons.play_arrow_rounded,

              title: 'Start Date',

              value:

                  _formatDate(project.startDate!),

            ),

          if (project.targetDate != null)

            _buildTimelineRow(

              icon: Icons.flag_outlined,

              title: 'Target Date',

              value:

                  _formatDate(project.targetDate!),

            ),

          if (project.completedAt != null)

            _buildTimelineRow(

              icon: Icons.check_circle_outline,

              title: 'Completed',

              value:

                  _formatDate(project.completedAt!),

            ),

        ],

      ),

    );

  }



  Widget _buildTimelineRow({

    required IconData icon,

    required String title,

    required String value,

  }) {

    return Padding(

      padding: const EdgeInsets.only(

        bottom: 11,

      ),

      child: Row(

        children: [

          Icon(

            icon,

            size: 18,

            color: const Color(0xFF6366F1),

          ),

          const SizedBox(width: 9),

          Text(

            title,

            style: GoogleFonts.manrope(

              fontSize: 11,

              fontWeight: FontWeight.w600,

              color: const Color(0xFF9CA3AF),

            ),

          ),

          const Spacer(),

          Text(

            value,

            style: GoogleFonts.manrope(

              fontSize: 11,

              fontWeight: FontWeight.w800,

              color: const Color(0xFF374151),

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildDetailCard({

    required String title,

    required Widget child,

  }) {

    return Container(

      width: double.infinity,

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

            title,

            style: GoogleFonts.manrope(

              fontSize: 12,

              fontWeight: FontWeight.w800,

              color: const Color(0xFF374151),

            ),

          ),

          const SizedBox(height: 11),

          child,

        ],

      ),

    );

  }



  // ============================================================

  // FAB

  // ============================================================



  Widget _buildFloatingActionButton() {

    return FloatingActionButton.extended(

      onPressed: _createProjectPlaceholder,

      backgroundColor: const Color(0xFF4F46E5),

      foregroundColor: Colors.white,

      elevation: 5,

      icon: const Icon(

        Icons.add_rounded,

      ),

      label: Text(

        'New Project',

        style: GoogleFonts.manrope(

          fontSize: 12,

          fontWeight: FontWeight.w800,

        ),

      ),

    );

  }



  void _createProjectPlaceholder() {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        behavior: SnackBarBehavior.floating,

        backgroundColor:

            const Color(0xFF111827),

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(12),

        ),

        content: Text(

          'Project creation screen is coming next.',

          style: GoogleFonts.manrope(

            fontSize: 12,

            fontWeight: FontWeight.w700,

            color: Colors.white,

          ),

        ),

      ),

    );

  }



  // ============================================================

  // EMPTY

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

            width: 66,

            height: 66,

            decoration: BoxDecoration(

              color: const Color(0xFFEEF2FF),

              borderRadius:

                  BorderRadius.circular(20),

            ),

            child: const Icon(

              Icons.folder_open_rounded,

              size: 31,

              color: Color(0xFF6366F1),

            ),

          ),

          const SizedBox(height: 16),

          Text(

            'No projects found',

            style: GoogleFonts.manrope(

              fontSize: 16,

              fontWeight: FontWeight.w800,

              color: const Color(0xFF111827),

            ),

          ),

          const SizedBox(height: 6),

          Text(

            'Create a project or change your filters.',

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



  // ============================================================

  // ERROR

  // ============================================================



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

              'Unable to load projects',

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

    await _projectService.getAllProjects();

  }



  // ============================================================

  // HELPERS

  // ============================================================



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



  Color _statusColor(ProjectStatus status) {

    switch (status) {

      case ProjectStatus.draft:

        return const Color(0xFF6B7280);

      case ProjectStatus.planning:

        return const Color(0xFF3B82F6);

      case ProjectStatus.active:

        return const Color(0xFF10B981);

      case ProjectStatus.onHold:

        return const Color(0xFFF59E0B);

      case ProjectStatus.completed:

        return const Color(0xFF8B5CF6);

      case ProjectStatus.archived:

        return const Color(0xFF9CA3AF);

    }

  }



  Color _priorityColor(ProjectPriority priority) {

    switch (priority) {

      case ProjectPriority.low:

        return const Color(0xFF6B7280);

      case ProjectPriority.medium:

        return const Color(0xFF3B82F6);

      case ProjectPriority.high:

        return const Color(0xFFF59E0B);

      case ProjectPriority.critical:

        return const Color(0xFFEF4444);

    }

  }



  Color _projectColor(Project project) {

    final value = project.color;



    if (value == null || value.isEmpty) {

      return const Color(0xFF6366F1);

    }



    final hex = value.replaceFirst('#', '');



    if (hex.length == 6) {

      final parsed =

          int.tryParse('FF$hex', radix: 16);



      if (parsed != null) {

        return Color(parsed);

      }

    }



    return const Color(0xFF6366F1);

  }



  IconData _projectIcon(Project project) {

    final icon = project.icon;



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

      case 'business':

        return Icons.business_center_rounded;

      case 'cloud':

        return Icons.cloud_rounded;

      default:

        return Icons.folder_rounded;

    }

  }



  String _formatDate(DateTime date) {

    return '${date.day.toString().padLeft(2, '0')}/'

        '${date.month.toString().padLeft(2, '0')}/'

        '${date.year}';

  }



  void _showSnack(

    String message, {

    bool error = false,

  }) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        behavior: SnackBarBehavior.floating,

        backgroundColor: error

            ? const Color(0xFFDC2626)

            : const Color(0xFF111827),

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(12),

        ),

        content: Text(

          message,

          style: GoogleFonts.manrope(

            fontSize: 12,

            fontWeight: FontWeight.w700,

            color: Colors.white,

          ),

        ),

      ),

    );

  }

}