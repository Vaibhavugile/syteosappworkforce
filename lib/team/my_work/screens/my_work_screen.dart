import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../models/task.dart';
import '../../../admin/projects/screens/task_details_screen.dart';

class MyWorkScreen extends StatefulWidget {
  const MyWorkScreen({super.key});

  @override
  State<MyWorkScreen> createState() => _MyWorkScreenState();
}

class _MyWorkScreenState extends State<MyWorkScreen> {
  static const _ink = Color(0xFF18213A);
  static const _muted = Color(0xFF778198);
  static const _indigo = Color(0xFF5B5CEB);
  static const _background = Color(0xFFF6F7FB);

  final _searchController = TextEditingController();
  final Map<String, String> _projectNames = {};
  String _filter = 'All';
  String _search = '';

  final _filters = const [
    'All',
    'Due Today',
    'Overdue',
    'In Progress',
    'In Review',
    'Completed',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _tasksStream(String uid) {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: uid)
        .snapshots();
  }

  Future<void> _loadProjectNames(List<Task> tasks) async {
    final ids = tasks
        .map((task) => task.projectId)
        .where((id) => id.isNotEmpty && !_projectNames.containsKey(id))
        .toSet();
    if (ids.isEmpty) return;

    final results = await Future.wait(ids.map((id) async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('projects')
            .doc(id)
            .get();
        return MapEntry(id, (doc.data()?['name'] as String?) ?? 'Project');
      } catch (_) {
        return MapEntry(id, 'Project');
      }
    }));

    if (!mounted) return;
    setState(() => _projectNames.addEntries(results));
  }

  bool _isCompleted(Task task) => task.status == TaskStatus.completed;

  bool _isOverdue(Task task) {
    final due = task.dueDate;
    if (due == null || _isCompleted(task) || task.status == TaskStatus.cancelled) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(due.year, due.month, due.day).isBefore(today);
  }

  bool _isDueToday(Task task) {
    final due = task.dueDate;
    if (due == null || _isCompleted(task) || task.status == TaskStatus.cancelled) {
      return false;
    }
    final now = DateTime.now();
    return due.year == now.year && due.month == now.month && due.day == now.day;
  }

  List<Task> _applyFilters(List<Task> tasks) {
    final query = _search.trim().toLowerCase();
    final result = tasks.where((task) {
      final matchesSearch = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          (_projectNames[task.projectId] ?? '').toLowerCase().contains(query);
      if (!matchesSearch) return false;
      switch (_filter) {
        case 'Due Today':
          return _isDueToday(task);
        case 'Overdue':
          return _isOverdue(task);
        case 'In Progress':
          return task.status == TaskStatus.inProgress;
        case 'In Review':
          return task.status == TaskStatus.inReview;
        case 'Completed':
          return _isCompleted(task);
        default:
          return true;
      }
    }).toList();

    result.sort((a, b) {
      if (_isOverdue(a) != _isOverdue(b)) return _isOverdue(a) ? -1 : 1;
      if (_isDueToday(a) != _isDueToday(b)) return _isDueToday(a) ? -1 : 1;
      if (_isCompleted(a) != _isCompleted(b)) return _isCompleted(a) ? 1 : -1;
      final aDue = a.dueDate;
      final bDue = b.dueDate;
      if (aDue == null && bDue == null) return 0;
      if (aDue == null) return 1;
      if (bDue == null) return -1;
      return aDue.compareTo(bDue);
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Text('Please sign in to view your work.',
              style: GoogleFonts.inter(color: _muted)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('My Work',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, color: _ink, fontSize: 20)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _tasksStream(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _stateView(Icons.cloud_off_outlined,
                'Unable to load tasks', '${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: _indigo));
          }

          final tasks = snapshot.data!.docs.map((doc) {
            return Task.fromMap(doc.id, doc.data());
          }).toList();

          // Fetch project names only when an unknown project appears.
          final unknown = tasks.any((task) =>
              task.projectId.isNotEmpty &&
              !_projectNames.containsKey(task.projectId));
          if (unknown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadProjectNames(tasks);
            });
          }

          final visible = _applyFilters(tasks);
          final completed = tasks.where(_isCompleted).length;
          final overdue = tasks.where(_isOverdue).length;
          final dueToday = tasks.where(_isDueToday).length;
          final inProgress = tasks
              .where((task) => task.status == TaskStatus.inProgress)
              .length;
          final inReview = tasks
              .where((task) => task.status == TaskStatus.inReview)
              .length;

          return RefreshIndicator(
            color: _indigo,
            onRefresh: () async {
              _projectNames.clear();
              await _loadProjectNames(tasks);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
              children: [
                Text('Your workspace',
                    style: GoogleFonts.inter(
                        fontSize: 25, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 5),
                Text('Stay on top of your assigned tasks.',
                    style: GoogleFonts.inter(fontSize: 13, color: _muted)),
                const SizedBox(height: 22),
                _overview(tasks.length, dueToday, overdue, inProgress,
                    inReview, completed),
                const SizedBox(height: 24),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _search = value),
                  style: GoogleFonts.inter(fontSize: 14, color: _ink),
                  decoration: InputDecoration(
                    hintText: 'Search tasks or projects',
                    hintStyle: GoogleFonts.inter(color: _muted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: _muted),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 19),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Color(0xFFE8EAF1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Color(0xFFE8EAF1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: _indigo, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 39,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final selected = _filter == filter;
                      return ChoiceChip(
                        label: Text(filter),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = filter),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : _ink,
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: _indigo,
                        showCheckmark: false,
                        side: BorderSide(
                          color: selected ? _indigo : const Color(0xFFE7E9F1),
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_filter == 'All' ? 'Assigned tasks' : _filter,
                        style: GoogleFonts.inter(
                            color: _ink, fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('${visible.length} tasks',
                        style: GoogleFonts.inter(color: _muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 13),
                if (visible.isEmpty)
                  _emptyCard()
                else
                  ...visible.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: _taskCard(task),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _overview(int total, int today, int overdue, int progress,
      int review, int completed) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 650 ? 3 : 2;
      final width = (constraints.maxWidth - (columns - 1) * 11) / columns;
      return Wrap(
        spacing: 11,
        runSpacing: 11,
        children: [
          _stat('Total tasks', total, Icons.assignment_outlined, _indigo, width),
          _stat('Due today', today, Icons.today_outlined,
              const Color(0xFFDB8B24), width),
          _stat('Overdue', overdue, Icons.warning_amber_rounded,
              const Color(0xFFE35B66), width),
          _stat('In progress', progress, Icons.play_circle_outline,
              const Color(0xFF397BC7), width),
          _stat('In review', review, Icons.rate_review_outlined,
              const Color(0xFF8D62CB), width),
          _stat('Completed', completed, Icons.check_circle_outline,
              const Color(0xFF249978), width),
        ],
      );
    });
  }

  Widget _stat(String label, int count, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFEAECF3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(height: 13),
        Text('$count',
            style: GoogleFonts.inter(
                fontSize: 26, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 3),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: _muted, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _taskCard(Task task) {
    final statusColor = _statusColor(task.status);
    final due = task.dueDate;
    final overdue = _isOverdue(task);
    final today = _isDueToday(task);
    final percent = task.completionPercentage.clamp(0, 100).toDouble();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TaskDetailsScreen(taskId: task.taskId),
        )),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFEAECF3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.folder_outlined, size: 15, color: _indigo),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_projectNames[task.projectId] ?? 'Project',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              _pill(_priorityLabel(task.priority), _priorityColor(task.priority)),
            ]),
            const SizedBox(height: 12),
            Text(task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
            if (task.description.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: _muted, fontSize: 12, height: 1.5)),
            ],
            const SizedBox(height: 16),
            Row(children: [
              _pill(_statusLabel(task.status), statusColor),
              const Spacer(),
              if (due != null) ...[
                Icon(Icons.calendar_today_outlined,
                    size: 13,
                    color: overdue ? const Color(0xFFE35B66) : _muted),
                const SizedBox(width: 5),
                Text(
                  overdue
                      ? 'Overdue · ${DateFormat('d MMM').format(due)}'
                      : today
                          ? 'Due today'
                          : DateFormat('d MMM yyyy').format(due),
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: overdue || today
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: overdue ? const Color(0xFFE35B66) : _muted),
                ),
              ],
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFECEEF6),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _isCompleted(task) ? const Color(0xFF249978) : _indigo),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${percent.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: _ink, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog: return 'Backlog';
      case TaskStatus.todo: return 'To do';
      case TaskStatus.inProgress: return 'In progress';
      case TaskStatus.inReview: return 'In review';
      case TaskStatus.changesRequested: return 'Changes requested';
      case TaskStatus.completed: return 'Completed';
      case TaskStatus.blocked: return 'Blocked';
      case TaskStatus.cancelled: return 'Cancelled';
    }
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress: return const Color(0xFF397BC7);
      case TaskStatus.inReview: return const Color(0xFF8D62CB);
      case TaskStatus.changesRequested: return const Color(0xFFCB8528);
      case TaskStatus.completed: return const Color(0xFF249978);
      case TaskStatus.blocked: return const Color(0xFFE35B66);
      case TaskStatus.cancelled: return _muted;
      case TaskStatus.backlog: return const Color(0xFF78849A);
      case TaskStatus.todo: return _indigo;
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low: return 'Low';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.high: return 'High';
      case TaskPriority.urgent: return 'Urgent';
    }
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low: return const Color(0xFF249978);
      case TaskPriority.medium: return const Color(0xFF397BC7);
      case TaskPriority.high: return const Color(0xFFCB8528);
      case TaskPriority.urgent: return const Color(0xFFE35B66);
    }
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 46),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFEAECF3)),
      ),
      child: Column(children: [
        const Icon(Icons.task_alt_rounded, color: _indigo, size: 38),
        const SizedBox(height: 13),
        Text('No tasks found',
            style: GoogleFonts.inter(
                color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Try another filter or search term.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: _muted, fontSize: 12)),
      ]),
    );
  }

  Widget _stateView(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: _muted, size: 38),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.inter(
                  color: _ink, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _muted, fontSize: 12)),
        ]),
      ),
    );
  }
}
