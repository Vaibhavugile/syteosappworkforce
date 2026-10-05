import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/task.dart';
import '../../../models/task_daily_update.dart';
import '../../../services/task_daily_update_service.dart';
import '../../../services/task_service.dart';

class MyDailyWorkHistoryScreen extends StatefulWidget {
  const MyDailyWorkHistoryScreen({super.key});

  @override
  State<MyDailyWorkHistoryScreen> createState() =>
      _MyDailyWorkHistoryScreenState();
}

class _MyDailyWorkHistoryScreenState
    extends State<MyDailyWorkHistoryScreen> {
  final TaskDailyUpdateService _dailyWorkService =
      TaskDailyUpdateService.instance;
  final TaskService _taskService = TaskService.instance;

  DateTime? _selectedDate;
  bool _showOnlyToday = false;

  static const _background = Color(0xFFF7F8FC);
  static const _text = Color(0xFF171923);
  static const _muted = Color(0xFF73778A);
  static const _border = Color(0xFFE7E9F2);
  static const _primary = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _orange = Color(0xFFF59E0B);
  static const _red = Color(0xFFEF4444);
  static const _purple = Color(0xFF8B5CF6);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Daily Work',
              style: TextStyle(
                color: _text,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Your submitted work history',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded, color: _text),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<TaskDailyUpdate>>(
        stream: _dailyWorkService.watchMyDailyWork(),
        builder: (context, updateSnapshot) {
          if (updateSnapshot.hasError) {
            return _errorState(updateSnapshot.error.toString());
          }

          if (updateSnapshot.connectionState == ConnectionState.waiting &&
              updateSnapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          final allUpdates = updateSnapshot.data ?? <TaskDailyUpdate>[];
          final visibleUpdates = _filterUpdates(allUpdates);

          return FutureBuilder<List<Task>>(
            future: _taskService.getMyTasks(),
            builder: (context, taskSnapshot) {
              final tasks = taskSnapshot.data ?? <Task>[];
              final taskMap = <String, Task>{
                for (final task in tasks) task.taskId: task,
              };

              final totalHours = visibleUpdates.fold<double>(
                0,
                (sum, update) => sum + (update.hoursSpent ?? 0),
              );
              final averageCompletion = visibleUpdates.isEmpty
                  ? 0.0
                  : visibleUpdates.fold<double>(
                        0,
                        (sum, update) =>
                            sum + update.completionPercentage,
                      ) /
                      visibleUpdates.length;
              final proofCount = visibleUpdates.fold<int>(
                0,
                (sum, update) => sum + update.attachmentIds.length,
              );

              return RefreshIndicator(
                color: _primary,
                onRefresh: () async => setState(() {}),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
                  children: [
                    _buildHero(
                      total: visibleUpdates.length,
                      hours: totalHours,
                      averageCompletion: averageCompletion,
                      proofs: proofCount,
                    ),
                    const SizedBox(height: 16),
                    _buildFilters(),
                    const SizedBox(height: 18),
                    if (visibleUpdates.isEmpty)
                      _emptyState()
                    else
                      ...visibleUpdates.map(
                        (update) => _buildUpdateCard(
                          update,
                          taskMap[update.taskId],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<TaskDailyUpdate> _filterUpdates(List<TaskDailyUpdate> updates) {
    final selected = _selectedDate;
    if (!_showOnlyToday && selected == null) return updates;

    final date = selected ?? DateTime.now();
    return updates.where((update) => _sameDay(update.date, date)).toList();
  }

  Widget _buildHero({
    required int total,
    required double hours,
    required double averageCompletion,
    required int proofs,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(.18),
            blurRadius: 24,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _whitePill(
                _showOnlyToday || _selectedDate != null
                    ? 'FILTERED'
                    : 'ALL HISTORY',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Your work record',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Every daily update submitted from your assigned tasks.',
            style: TextStyle(
              color: Colors.white.withOpacity(.78),
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroMetric('$total', 'Updates'),
              _heroMetric(hours.toStringAsFixed(1), 'Hours'),
              _heroMetric('${averageCompletion.round()}%', 'Avg. done'),
              _heroMetric('$proofs', 'Proof files'),
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
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(.68),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whitePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: _filterButton(
            icon: Icons.today_rounded,
            label: 'Today',
            active: _showOnlyToday && _selectedDate == null,
            onTap: () {
              setState(() {
                _showOnlyToday = !_showOnlyToday;
                _selectedDate = null;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _filterButton(
            icon: Icons.calendar_month_rounded,
            label: _selectedDate == null
                ? 'Choose date'
                : DateFormat('dd MMM').format(_selectedDate!),
            active: _selectedDate != null,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _filterButton(
            icon: Icons.all_inclusive_rounded,
            label: 'All',
            active: !_showOnlyToday && _selectedDate == null,
            onTap: () {
              setState(() {
                _showOnlyToday = false;
                _selectedDate = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _filterButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? _primary.withOpacity(.35) : _border,
            ),
            color: active ? _primary.withOpacity(.06) : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? _primary : _muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? _primary : _text,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedDate = selected;
      _showOnlyToday = false;
    });
  }

  Widget _buildUpdateCard(TaskDailyUpdate update, Task? task) {
    final statusColor = _statusColor(update.status);
    final completion = update.completionPercentage.clamp(0, 100).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
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
                      task?.title ?? 'Assigned task',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, dd MMM yyyy').format(update.date),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _statusPill(update.statusLabel, statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            update.description,
            style: const TextStyle(
              color: _text,
              fontSize: 11,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _smallMetric(
                Icons.percent_rounded,
                '${completion.round()}%',
                'Completion',
                _primary,
              ),
              const SizedBox(width: 8),
              _smallMetric(
                Icons.schedule_rounded,
                update.hoursSpent == null
                    ? '—'
                    : '${update.hoursSpent!.toStringAsFixed(1)}h',
                'Time',
                _orange,
              ),
              const SizedBox(width: 8),
              _smallMetric(
                Icons.attach_file_rounded,
                '${update.attachmentIds.length}',
                'Proof',
                _green,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 5,
              backgroundColor: const Color(0xFFE9EBF3),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallMetric(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
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

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _statusColor(TaskDailyUpdateStatus status) {
    switch (status) {
      case TaskDailyUpdateStatus.draft:
        return _muted;
      case TaskDailyUpdateStatus.submitted:
        return _primary;
      case TaskDailyUpdateStatus.underReview:
        return _purple;
      case TaskDailyUpdateStatus.approved:
        return _green;
      case TaskDailyUpdateStatus.changesRequested:
        return _red;
    }
  }

  Widget _emptyState() {
    final filtered = _showOnlyToday || _selectedDate != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.work_history_outlined,
            color: _muted,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            filtered ? 'No work found for this date' : 'No daily work yet',
            style: const TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            filtered
                ? 'Try another date or switch back to All.'
                : 'Your submitted daily work will appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: _red, size: 42),
            const SizedBox(height: 12),
            const Text(
              'Unable to load your work',
              style: TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
