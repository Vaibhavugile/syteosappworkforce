import 'dart:io';



import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import 'package:intl/intl.dart';



import '../../../models/project.dart';

import '../../../models/task.dart';

import '../../../models/task_attachment.dart';

import '../../../models/task_daily_update.dart';

import '../../../services/task_attachment_service.dart';

import '../../../services/task_daily_update_service.dart';

import '../../../services/task_service.dart';
import '../../../admin/projects/screens/create_task_screen.dart';



class DailyWorkScreen extends StatefulWidget {

  const DailyWorkScreen({

    super.key,

    this.taskId,

  });



  final String? taskId;



  @override

  State<DailyWorkScreen> createState() =>

      _DailyWorkScreenState();

}



class _DailyWorkScreenState

    extends State<DailyWorkScreen> {

  final TaskService _taskService =

      TaskService.instance;



  final TaskDailyUpdateService

      _dailyUpdateService =

      TaskDailyUpdateService.instance;



  final TaskAttachmentService

      _attachmentService =

      TaskAttachmentService.instance;



  final ImagePicker _imagePicker =

      ImagePicker();



  final TextEditingController

      _descriptionController =

      TextEditingController();



  final TextEditingController

      _hoursController =

      TextEditingController();



  DateTime _selectedDate =

      DateTime.now();



  Task? _selectedTask;



  List<Task> _tasks = [];



  List<File> _pendingFiles = [];



  bool _isLoadingTasks = true;

  bool _isSubmitting = false;



  double _completionPercentage = 0;



  String? _errorMessage;



  @override

  void initState() {

    super.initState();

    _loadTasks();

  }



  @override

  void dispose() {

    _descriptionController.dispose();

    _hoursController.dispose();

    super.dispose();

  }



  // ===========================================================================

  // LOAD TASKS

  // ===========================================================================



  Future<void> _loadTasks() async {

    setState(() {

      _isLoadingTasks = true;

      _errorMessage = null;

    });



    try {

      final tasks =

          await _taskService.getMyTasks();



      if (!mounted) return;



      final filteredTasks =

          tasks.where((task) {

        return task.status !=

                TaskStatus.completed &&

            task.status !=

                TaskStatus.cancelled;

      }).toList();



      Task? selectedTask;



      if (widget.taskId != null &&

          widget.taskId!.trim().isNotEmpty) {

        for (final task in filteredTasks) {

          if (task.taskId ==

              widget.taskId!.trim()) {

            selectedTask = task;

            break;

          }

        }

      }



      setState(() {

        _tasks = filteredTasks;

        _selectedTask = selectedTask;

        _isLoadingTasks = false;

      });

    } catch (e) {

      if (!mounted) return;



      setState(() {

        _isLoadingTasks = false;

        _errorMessage =

            'Unable to load your tasks.';

      });

    }

  }



  // ===========================================================================

  // DATE

  // ===========================================================================




  // ===========================================================================
  // CREATE NEW TASK
  // ===========================================================================

  Future<void> _createNewTask() async {
    FocusScope.of(context).unfocus();

    final existingTaskIds = _tasks
        .map((task) => task.taskId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CreateTaskScreen(),
      ),
    );

    if (!mounted || created != true) {
      return;
    }

    await _loadTasks();

    if (!mounted) return;

    Task? newlyCreatedTask;

    for (final task in _tasks) {
      if (!existingTaskIds.contains(task.taskId)) {
        newlyCreatedTask = task;
        break;
      }
    }

    if (newlyCreatedTask != null) {
      setState(() {
        _selectedTask = newlyCreatedTask;
      });

      _showSuccess('New task created and selected.');
    } else {
      _showSuccess(
        'Task created successfully. Refreshing your assigned tasks.',
      );
    }
  }

  Future<void> _selectDate() async {

    final today = DateTime.now();



    final selected =

        await showDatePicker(

      context: context,

      initialDate: _selectedDate,

      firstDate:

          DateTime(today.year - 1),

      lastDate:

          DateTime(today.year, today.month, today.day),

      builder: (context, child) {

        return Theme(

          data: Theme.of(context).copyWith(

            colorScheme:

                const ColorScheme.light(

              primary: Color(0xFF6366F1),

            ),

          ),

          child: child!,

        );

      },

    );



    if (selected == null) {

      return;

    }



    setState(() {

      _selectedDate = selected;

    });

  }



  // ===========================================================================

  // IMAGE

  // ===========================================================================



  Future<void> _pickImage() async {

    try {

      final image =

          await _imagePicker.pickImage(

        source: ImageSource.gallery,

        imageQuality: 85,

      );



      if (image == null) {

        return;

      }



      setState(() {

        _pendingFiles.add(

          File(image.path),

        );

      });

    } catch (e) {

      _showError(

        'Unable to select the image.',

      );

    }

  }



  // ===========================================================================

  // CAMERA

  // ===========================================================================



  Future<void> _takePhoto() async {

    try {

      final image =

          await _imagePicker.pickImage(

        source: ImageSource.camera,

        imageQuality: 85,

      );



      if (image == null) {

        return;

      }



      setState(() {

        _pendingFiles.add(

          File(image.path),

        );

      });

    } catch (e) {

      _showError(

        'Unable to capture the photo.',

      );

    }

  }



  // ===========================================================================

  // VIDEO

  // ===========================================================================



  Future<void> _pickVideo() async {

    try {

      final video =

          await _imagePicker.pickVideo(

        source: ImageSource.gallery,

      );



      if (video == null) {

        return;

      }



      setState(() {

        _pendingFiles.add(

          File(video.path),

        );

      });

    } catch (e) {

      _showError(

        'Unable to select the video.',

      );

    }

  }



  // ===========================================================================

  // FILE

  // ===========================================================================



  Future<void> _pickFiles() async {

    try {

      final result =

          await FilePicker.pickFiles(

        type: FileType.custom,

        allowedExtensions: [

          'pdf',

          'doc',

          'docx',

          'xls',

          'xlsx',

          'ppt',

          'pptx',

          'txt',

          'csv',

          'zip',

        ],

      );



      if (result.isEmpty) {

        return;

      }



      final files = result

          .where(

            (file) =>

                file.path != null &&

                file.path!.isNotEmpty,

          )

          .map(

            (file) => File(file.path!),

          )

          .toList();



      if (files.isEmpty) {

        return;

      }



      setState(() {

        _pendingFiles.addAll(files);

      });

    } catch (e) {

      _showError(

        'Unable to select the files.',

      );

    }

  }



  // ===========================================================================

  // ATTACHMENT MENU

  // ===========================================================================



  void _showAttachmentOptions() {

    showModalBottomSheet(

      context: context,

      backgroundColor: Colors.transparent,

      builder: (context) {

        return Container(

          padding: const EdgeInsets.fromLTRB(

            20,

            16,

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

              children: [

                Container(

                  width: 42,

                  height: 4,

                  decoration: BoxDecoration(

                    color: const Color(

                      0xFFE5E7EB,

                    ),

                    borderRadius:

                        BorderRadius.circular(20),

                  ),

                ),

                const SizedBox(height: 22),

                const Align(

                  alignment:

                      Alignment.centerLeft,

                  child: Text(

                    'Add proof',

                    style: TextStyle(

                      fontSize: 20,

                      fontWeight:

                          FontWeight.w800,

                    ),

                  ),

                ),

                const SizedBox(height: 6),

                const Align(

                  alignment:

                      Alignment.centerLeft,

                  child: Text(

                    'Attach evidence of the work completed today.',

                    style: TextStyle(

                      fontSize: 13,

                      color: Color(

                        0xFF6B7280,

                      ),

                    ),

                  ),

                ),

                const SizedBox(height: 20),

                Row(

                  children: [

                    Expanded(

                      child: _attachmentOption(

                        icon:

                            Icons.photo_outlined,

                        title: 'Photo',

                        onTap: () {

                          Navigator.pop(

                            context,

                          );

                          _pickImage();

                        },

                      ),

                    ),

                    const SizedBox(width: 12),

                    Expanded(

                      child: _attachmentOption(

                        icon:

                            Icons.camera_alt_outlined,

                        title: 'Camera',

                        onTap: () {

                          Navigator.pop(

                            context,

                          );

                          _takePhoto();

                        },

                      ),

                    ),

                    const SizedBox(width: 12),

                    Expanded(

                      child: _attachmentOption(

                        icon:

                            Icons.videocam_outlined,

                        title: 'Video',

                        onTap: () {

                          Navigator.pop(

                            context,

                          );

                          _pickVideo();

                        },

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 12),

                SizedBox(

                  width: double.infinity,

                  child: _attachmentOption(

                    icon:

                        Icons.attach_file_rounded,

                    title:

                        'Documents & files',

                    horizontal: true,

                    onTap: () {

                      Navigator.pop(

                        context,

                      );

                      _pickFiles();

                    },

                  ),

                ),

              ],

            ),

          ),

        );

      },

    );

  }



  Widget _attachmentOption({

    required IconData icon,

    required String title,

    required VoidCallback onTap,

    bool horizontal = false,

  }) {

    return Material(

      color: const Color(0xFFF8FAFC),

      borderRadius:

          BorderRadius.circular(18),

      child: InkWell(

        borderRadius:

            BorderRadius.circular(18),

        onTap: onTap,

        child: Padding(

          padding: EdgeInsets.symmetric(

            horizontal:

                horizontal ? 18 : 8,

            vertical:

                horizontal ? 16 : 18,

          ),

          child: horizontal

              ? Row(

                  children: [

                    Container(

                      width: 42,

                      height: 42,

                      decoration:

                          BoxDecoration(

                        color:

                            const Color(

                          0xFFEDE9FE,

                        ),

                        borderRadius:

                            BorderRadius.circular(

                          13,

                        ),

                      ),

                      child: const Icon(

                        Icons

                            .attach_file_rounded,

                        color:

                            Color(0xFF6366F1),

                      ),

                    ),

                    const SizedBox(width: 14),

                    Text(

                      title,

                      style:

                          const TextStyle(

                        fontWeight:

                            FontWeight.w700,

                        fontSize: 14,

                      ),

                    ),

                  ],

                )

              : Column(

                  children: [

                    Icon(

                      icon,

                      size: 25,

                      color:

                          const Color(

                        0xFF6366F1,

                      ),

                    ),

                    const SizedBox(height: 8),

                    Text(

                      title,

                      style:

                          const TextStyle(

                        fontSize: 12,

                        fontWeight:

                            FontWeight.w700,

                      ),

                    ),

                  ],

                ),

        ),

      ),

    );

  }



  // ===========================================================================

  // REMOVE FILE

  // ===========================================================================



  void _removePendingFile(

    int index,

  ) {

    setState(() {

      _pendingFiles.removeAt(index);

    });

  }



  // ===========================================================================

  // SUBMIT

  // ===========================================================================



  Future<void> _submitDailyWork() async {

    FocusScope.of(context).unfocus();



    if (_selectedTask == null) {

      _showError(

        'Please select a task.',

      );

      return;

    }



    final description =

        _descriptionController.text.trim();



    if (description.isEmpty) {

      _showError(

        'Please describe what you worked on today.',

      );

      return;

    }



    double? hoursSpent;



    final hoursText =

        _hoursController.text.trim();



    if (hoursText.isNotEmpty) {

      hoursSpent =

          double.tryParse(hoursText);



      if (hoursSpent == null ||

          hoursSpent < 0) {

        _showError(

          'Please enter valid hours.',

        );

        return;

      }

    }



    setState(() {

      _isSubmitting = true;

    });



    try {

      final dailyUpdateId =

          await _dailyUpdateService

              .createDailyUpdate(

        taskId:

            _selectedTask!.taskId,

        projectId:

            _selectedTask!.projectId,

        date: _selectedDate,

        description: description,

        completionPercentage:

            _completionPercentage,

        hoursSpent: hoursSpent,

      );



      for (final file in _pendingFiles) {

        await _attachmentService

            .uploadDailyWorkAttachment(

          taskId:

              _selectedTask!.taskId,

          projectId:

              _selectedTask!.projectId,

          dailyUpdateId:

              dailyUpdateId,

          file: file,

          date: _selectedDate,

        );

      }



      if (!mounted) return;



      _showSuccess(

        'Daily work submitted successfully.',

      );



      Navigator.of(context).pop(true);

    } catch (e) {

      if (!mounted) return;



      _showError(

        _friendlyError(e),

      );

    } finally {

      if (mounted) {

        setState(() {

          _isSubmitting = false;

        });

      }

    }

  }



  // ===========================================================================

  // UI

  // ===========================================================================



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:

          const Color(0xFFF6F7FB),

      appBar: AppBar(

        elevation: 0,

        backgroundColor:

            const Color(0xFFF6F7FB),

        surfaceTintColor:

            Colors.transparent,

        title: const Text(

          'Daily Work',

          style: TextStyle(

            color: Color(0xFF111827),

            fontSize: 20,

            fontWeight: FontWeight.w800,

          ),

        ),

        leading: IconButton(

          onPressed:

              () => Navigator.pop(context),

          icon: const Icon(

            Icons.arrow_back_rounded,

            color: Color(0xFF111827),

          ),

        ),

      ),

      body: _isLoadingTasks

          ? const Center(

              child:

                  CircularProgressIndicator(

                color: Color(0xFF6366F1),

              ),

            )

          : _errorMessage != null

              ? _buildErrorState()

              : _tasks.isEmpty

                  ? _buildEmptyState()

                  : SafeArea(

                      child: SingleChildScrollView(

                        padding:

                            const EdgeInsets.fromLTRB(

                          20,

                          8,

                          20,

                          32,

                        ),

                        child: Column(

                          crossAxisAlignment:

                              CrossAxisAlignment.start,

                          children: [

                            _buildHeader(),

                            const SizedBox(

                              height: 18,

                            ),

                            _buildDateCard(),

                            const SizedBox(

                              height: 14,

                            ),

                            _buildTaskCard(),

                            const SizedBox(

                              height: 14,

                            ),

                            _buildDescriptionCard(),

                            const SizedBox(

                              height: 14,

                            ),

                            _buildProgressCard(),

                            const SizedBox(

                              height: 14,

                            ),

                            _buildHoursCard(),

                            const SizedBox(

                              height: 14,

                            ),

                            _buildAttachmentsCard(),

                            const SizedBox(

                              height: 24,

                            ),

                            _buildSubmitButton(),

                          ],

                        ),

                      ),

                    ),

    );

  }



  Widget _buildHeader() {

    return Container(

      width: double.infinity,

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

        borderRadius:

            BorderRadius.circular(24),

        boxShadow: [

          BoxShadow(

            color:

                const Color(0xFF6366F1)

                    .withOpacity(.18),

            blurRadius: 24,

            offset: const Offset(0, 10),

          ),

        ],

      ),

      child: Row(

        children: [

          Container(

            width: 52,

            height: 52,

            decoration: BoxDecoration(

              color: Colors.white

                  .withOpacity(.16),

              borderRadius:

                  BorderRadius.circular(16),

            ),

            child: const Icon(

              Icons.work_history_outlined,

              color: Colors.white,

              size: 28,

            ),

          ),

          const SizedBox(width: 16),

          const Expanded(

            child: Column(

              crossAxisAlignment:

                  CrossAxisAlignment.start,

              children: [

                Text(

                  'Log your work',

                  style: TextStyle(

                    color: Colors.white,

                    fontSize: 20,

                    fontWeight:

                        FontWeight.w800,

                  ),

                ),

                SizedBox(height: 4),

                Text(

                  'Record what you completed today.',

                  style: TextStyle(

                    color: Colors.white70,

                    fontSize: 13,

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildDateCard() {

    return _sectionCard(

      child: InkWell(

        onTap: _selectDate,

        borderRadius:

            BorderRadius.circular(20),

        child: Padding(

          padding:

              const EdgeInsets.all(18),

          child: Row(

            children: [

              _iconContainer(

                Icons.calendar_today_outlined,

              ),

              const SizedBox(width: 14),

              Expanded(

                child: Column(

                  crossAxisAlignment:

                      CrossAxisAlignment.start,

                  children: [

                    const Text(

                      'Work date',

                      style: TextStyle(

                        color:

                            Color(0xFF6B7280),

                        fontSize: 12,

                        fontWeight:

                            FontWeight.w600,

                      ),

                    ),

                    const SizedBox(height: 4),

                    Text(

                      DateFormat(

                        'EEEE, dd MMM yyyy',

                      ).format(

                        _selectedDate,

                      ),

                      style:

                          const TextStyle(

                        color:

                            Color(0xFF111827),

                        fontSize: 15,

                        fontWeight:

                            FontWeight.w800,

                      ),

                    ),

                  ],

                ),

              ),

              const Icon(

                Icons

                    .keyboard_arrow_right_rounded,

                color:

                    Color(0xFF9CA3AF),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildTaskCard() {
    const createNewTaskValue = '__create_new_task__';

    return _sectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.task_alt_outlined,
            title: 'Task',
            subtitle: 'Select the task you worked on or create a new one.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTask?.taskId,
            isExpanded: true,
            decoration: _inputDecoration(
              hint: 'Select assigned task',
              prefixIcon: Icons.task_alt_outlined,
            ),
            items: [
              DropdownMenuItem<String>(
                value: createNewTaskValue,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_task_rounded,
                        size: 19,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        '＋ Create New Task',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ..._tasks.map(
                (task) {
                  return DropdownMenuItem<String>(
                    value: task.taskId,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.task_alt_outlined,
                            size: 18,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            onChanged: (value) {
              if (value == createNewTaskValue) {
                _createNewTask();
                return;
              }

              if (value == null || value.trim().isEmpty) {
                return;
              }

              Task? selected;

              for (final task in _tasks) {
                if (task.taskId == value) {
                  selected = task;
                  break;
                }
              }

              if (selected == null) {
                return;
              }

              setState(() {
                _selectedTask = selected;
              });
            },
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _createNewTask,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE4E1FF),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create a new task',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF374151),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Add a task if your work is not in the list.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedTask != null) ...[
            const SizedBox(height: 12),
            _selectedTaskInfo(),
          ],
        ],
      ),
    );
  }


  Widget _selectedTaskInfo() {

    final task =

        _selectedTask!;



    return Container(

      padding:

          const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color:

            const Color(0xFFF8FAFC),

        borderRadius:

            BorderRadius.circular(14),

        border: Border.all(

          color:

              const Color(0xFFE5E7EB),

        ),

      ),

      child: Row(

        children: [

          Expanded(

            child: _miniInfo(

              'Status',

              _taskStatusLabel(

                task.status,

              ),

            ),

          ),

          Expanded(

            child: _miniInfo(

              'Current',

              '${task.completionPercentage.toStringAsFixed(0)}%',

            ),

          ),

          Expanded(

            child: _miniInfo(

              'Priority',

              _taskPriorityLabel(

                task.priority,

              ),

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildDescriptionCard() {

    return _sectionCard(

      padding: const EdgeInsets.all(18),

      child: Column(

        crossAxisAlignment:

            CrossAxisAlignment.start,

        children: [

          _sectionTitle(

            icon:

                Icons.notes_outlined,

            title: 'What did you work on?',

            subtitle:

                'Describe the work completed today.',

          ),

          const SizedBox(height: 16),

          TextField(

            controller:

                _descriptionController,

            maxLines: 5,

            minLines: 4,

            textCapitalization:

                TextCapitalization.sentences,

            decoration:

                _inputDecoration(

              hint:

                  'Example: Completed the login screen, fixed validation errors and tested the OTP flow.',

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildProgressCard() {

    return _sectionCard(

      padding: const EdgeInsets.all(18),

      child: Column(

        crossAxisAlignment:

            CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Expanded(

                child: _sectionTitle(

                  icon:

                      Icons.trending_up_rounded,

                  title:

                      'Completion after today',

                  subtitle:

                      'Update your task progress.',

                ),

              ),

              Text(

                '${_completionPercentage.toStringAsFixed(0)}%',

                style: const TextStyle(

                  fontSize: 22,

                  fontWeight:

                      FontWeight.w900,

                  color:

                      Color(0xFF4F46E5),

                ),

              ),

            ],

          ),

          const SizedBox(height: 12),

          SliderTheme(

            data:

                SliderTheme.of(context).copyWith(

              activeTrackColor:

                  const Color(0xFF6366F1),

              inactiveTrackColor:

                  const Color(0xFFE5E7EB),

              thumbColor:

                  const Color(0xFF4F46E5),

              overlayColor:

                  const Color(0xFF6366F1)

                      .withOpacity(.12),

              trackHeight: 5,

            ),

            child: Slider(

              value:

                  _completionPercentage,

              min: 0,

              max: 100,

              divisions: 20,

              label:

                  '${_completionPercentage.toStringAsFixed(0)}%',

              onChanged: (value) {

                setState(() {

                  _completionPercentage =

                      value;

                });

              },

            ),

          ),

          Row(

            mainAxisAlignment:

                MainAxisAlignment.spaceBetween,

            children: const [

              Text(

                '0%',

                style: TextStyle(

                  fontSize: 11,

                  color:

                      Color(0xFF9CA3AF),

                ),

              ),

              Text(

                '50%',

                style: TextStyle(

                  fontSize: 11,

                  color:

                      Color(0xFF9CA3AF),

                ),

              ),

              Text(

                '100%',

                style: TextStyle(

                  fontSize: 11,

                  color:

                      Color(0xFF9CA3AF),

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }



  Widget _buildHoursCard() {

    return _sectionCard(

      padding: const EdgeInsets.all(18),

      child: Column(

        crossAxisAlignment:

            CrossAxisAlignment.start,

        children: [

          _sectionTitle(

            icon:

                Icons.schedule_outlined,

            title: 'Time spent',

            subtitle:

                'Optional — enter hours spent today.',

          ),

          const SizedBox(height: 16),

          TextField(

            controller:

                _hoursController,

            keyboardType:

                const TextInputType.numberWithOptions(

              decimal: true,

            ),

            decoration:

                _inputDecoration(

              hint: 'e.g. 4.5',

              prefixIcon:

                  Icons.access_time_rounded,

              suffixText: 'hours',

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildAttachmentsCard() {

    return _sectionCard(

      padding: const EdgeInsets.all(18),

      child: Column(

        crossAxisAlignment:

            CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Expanded(

                child: _sectionTitle(

                  icon:

                      Icons.attach_file_rounded,

                  title: 'Proof & attachments',

                  subtitle:

                      'Add screenshots, videos or files.',

                ),

              ),

              IconButton(

                onPressed:

                    _showAttachmentOptions,

                style:

                    IconButton.styleFrom(

                  backgroundColor:

                      const Color(

                    0xFFEDE9FE,

                  ),

                ),

                icon: const Icon(

                  Icons.add_rounded,

                  color:

                      Color(0xFF6366F1),

                ),

              ),

            ],

          ),

          const SizedBox(height: 14),

          if (_pendingFiles.isEmpty)

            _emptyAttachmentBox()

          else

            Column(

              children:

                  List.generate(

                _pendingFiles.length,

                (index) {

                  return Padding(

                    padding:

                        EdgeInsets.only(

                      bottom:

                          index ==

                                  _pendingFiles.length -

                                      1

                              ? 0

                              : 10,

                    ),

                    child:

                        _pendingFileTile(

                      _pendingFiles[index],

                      index,

                    ),

                  );

                },

              ),

            ),

        ],

      ),

    );

  }



  Widget _emptyAttachmentBox() {

    return InkWell(

      onTap:

          _showAttachmentOptions,

      borderRadius:

          BorderRadius.circular(16),

      child: Container(

        width: double.infinity,

        padding:

            const EdgeInsets.symmetric(

          vertical: 24,

          horizontal: 16,

        ),

        decoration: BoxDecoration(

          color:

              const Color(0xFFF8FAFC),

          borderRadius:

              BorderRadius.circular(16),

          border: Border.all(

            color:

                const Color(0xFFE5E7EB),

          ),

        ),

        child: Column(

          children: [

            Container(

              width: 48,

              height: 48,

              decoration: BoxDecoration(

                color:

                    const Color(0xFFEDE9FE),

                borderRadius:

                    BorderRadius.circular(15),

              ),

              child: const Icon(

                Icons.cloud_upload_outlined,

                color:

                    Color(0xFF6366F1),

                size: 25,

              ),

            ),

            const SizedBox(height: 10),

            const Text(

              'Add proof of your work',

              style: TextStyle(

                fontSize: 14,

                fontWeight:

                    FontWeight.w800,

              ),

            ),

            const SizedBox(height: 4),

            const Text(

              'Images, videos, PDFs and documents',

              textAlign:

                  TextAlign.center,

              style: TextStyle(

                fontSize: 12,

                color:

                    Color(0xFF6B7280),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _pendingFileTile(

    File file,

    int index,

  ) {

    final name =

        file.path.split(

          Platform.pathSeparator,

        ).last;



    final extension =

        name.contains('.')

            ? name

                .split('.')

                .last

                .toUpperCase()

            : 'FILE';



    final isImage =

        _isImageFile(name);



    return Container(

      padding:

          const EdgeInsets.all(10),

      decoration: BoxDecoration(

        color:

            const Color(0xFFF8FAFC),

        borderRadius:

            BorderRadius.circular(15),

        border: Border.all(

          color:

              const Color(0xFFE5E7EB),

        ),

      ),

      child: Row(

        children: [

          Container(

            width: 46,

            height: 46,

            decoration: BoxDecoration(

              color: isImage

                  ? const Color(

                      0xFFE0F2FE,

                    )

                  : const Color(

                      0xFFEDE9FE,

                    ),

              borderRadius:

                  BorderRadius.circular(13),

            ),

            child: Icon(

              isImage

                  ? Icons.image_outlined

                  : _fileIcon(name),

              color: isImage

                  ? const Color(

                      0xFF0284C7,

                    )

                  : const Color(

                      0xFF6366F1,

                    ),

            ),

          ),

          const SizedBox(width: 12),

          Expanded(

            child: Column(

              crossAxisAlignment:

                  CrossAxisAlignment.start,

              children: [

                Text(

                  name,

                  maxLines: 1,

                  overflow:

                      TextOverflow.ellipsis,

                  style:

                      const TextStyle(

                    fontSize: 13,

                    fontWeight:

                        FontWeight.w700,

                  ),

                ),

                const SizedBox(height: 3),

                Text(

                  extension,

                  style:

                      const TextStyle(

                    fontSize: 11,

                    color:

                        Color(0xFF9CA3AF),

                    fontWeight:

                        FontWeight.w600,

                  ),

                ),

              ],

            ),

          ),

          IconButton(

            onPressed: () =>

                _removePendingFile(

              index,

            ),

            icon: const Icon(

              Icons.close_rounded,

              size: 19,

              color:

                  Color(0xFF9CA3AF),

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildSubmitButton() {

    return SizedBox(

      width: double.infinity,

      height: 56,

      child: FilledButton(

        onPressed: _isSubmitting

            ? null

            : _submitDailyWork,

        style: FilledButton.styleFrom(

          backgroundColor:

              const Color(0xFF4F46E5),

          disabledBackgroundColor:

              const Color(0xFFC7D2FE),

          shape:

              RoundedRectangleBorder(

            borderRadius:

                BorderRadius.circular(18),

          ),

        ),

        child: _isSubmitting

            ? const SizedBox(

                width: 23,

                height: 23,

                child:

                    CircularProgressIndicator(

                  strokeWidth: 2.5,

                  color: Colors.white,

                ),

              )

            : const Row(

                mainAxisAlignment:

                    MainAxisAlignment.center,

                children: [

                  Icon(

                    Icons

                        .check_circle_outline_rounded,

                    size: 21,

                  ),

                  SizedBox(width: 9),

                  Text(

                    'Submit Daily Work',

                    style: TextStyle(

                      fontSize: 15,

                      fontWeight:

                          FontWeight.w800,

                    ),

                  ),

                ],

              ),

      ),

    );

  }



  // ===========================================================================

  // EMPTY / ERROR

  // ===========================================================================



  Widget _buildEmptyState() {

    return Center(

      child: Padding(

        padding:

            const EdgeInsets.all(32),

        child: Column(

          mainAxisAlignment:

              MainAxisAlignment.center,

          children: [

            Container(

              width: 76,

              height: 76,

              decoration: BoxDecoration(

                color:

                    const Color(0xFFEDE9FE),

                borderRadius:

                    BorderRadius.circular(24),

              ),

              child: const Icon(

                Icons.task_alt_outlined,

                size: 38,

                color:

                    Color(0xFF6366F1),

              ),

            ),

            const SizedBox(height: 20),

            const Text(

              'No active tasks',

              style: TextStyle(

                fontSize: 21,

                fontWeight:

                    FontWeight.w800,

              ),

            ),

            const SizedBox(height: 8),

            const Text(

              'You currently have no active tasks assigned to you.',

              textAlign:

                  TextAlign.center,

              style: TextStyle(

                fontSize: 14,

                color:

                    Color(0xFF6B7280),

              ),

            ),

            const SizedBox(height: 24),

            OutlinedButton.icon(

              onPressed: _loadTasks,

              icon: const Icon(

                Icons.refresh_rounded,

              ),

              label:

                  const Text('Refresh'),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildErrorState() {

    return Center(

      child: Padding(

        padding:

            const EdgeInsets.all(32),

        child: Column(

          mainAxisAlignment:

              MainAxisAlignment.center,

          children: [

            const Icon(

              Icons.error_outline_rounded,

              size: 52,

              color:

                  Color(0xFFEF4444),

            ),

            const SizedBox(height: 16),

            Text(

              _errorMessage ??

                  'Something went wrong.',

              textAlign:

                  TextAlign.center,

              style: const TextStyle(

                fontSize: 15,

                color:

                    Color(0xFF6B7280),

              ),

            ),

            const SizedBox(height: 20),

            FilledButton(

              onPressed: _loadTasks,

              child:

                  const Text('Try again'),

            ),

          ],

        ),

      ),

    );

  }



  // ===========================================================================

  // HELPERS

  // ===========================================================================



  Widget _sectionCard({

    required Widget child,

    EdgeInsetsGeometry padding =

        const EdgeInsets.all(18),

  }) {

    return Container(

      width: double.infinity,

      padding: padding,

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:

            BorderRadius.circular(22),

        border: Border.all(

          color:

              const Color(0xFFE8EAF0),

        ),

        boxShadow: [

          BoxShadow(

            color:

                Colors.black.withOpacity(.025),

            blurRadius: 14,

            offset:

                const Offset(0, 5),

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

      crossAxisAlignment:

          CrossAxisAlignment.start,

      children: [

        _iconContainer(icon),

        const SizedBox(width: 12),

        Expanded(

          child: Column(

            crossAxisAlignment:

                CrossAxisAlignment.start,

            children: [

              Text(

                title,

                style:

                    const TextStyle(

                  fontSize: 15,

                  fontWeight:

                      FontWeight.w800,

                  color:

                      Color(0xFF111827),

                ),

              ),

              const SizedBox(height: 3),

              Text(

                subtitle,

                style:

                    const TextStyle(

                  fontSize: 12,

                  color:

                      Color(0xFF6B7280),

                ),

              ),

            ],

          ),

        ),

      ],

    );

  }



  Widget _iconContainer(

    IconData icon,

  ) {

    return Container(

      width: 42,

      height: 42,

      decoration: BoxDecoration(

        color:

            const Color(0xFFEDE9FE),

        borderRadius:

            BorderRadius.circular(13),

      ),

      child: Icon(

        icon,

        color:

            const Color(0xFF6366F1),

        size: 21,

      ),

    );

  }



  Widget _miniInfo(

    String label,

    String value,

  ) {

    return Column(

      crossAxisAlignment:

          CrossAxisAlignment.start,

      children: [

        Text(

          label,

          style: const TextStyle(

            fontSize: 10,

            color:

                Color(0xFF9CA3AF),

            fontWeight:

                FontWeight.w600,

          ),

        ),

        const SizedBox(height: 3),

        Text(

          value,

          maxLines: 1,

          overflow:

              TextOverflow.ellipsis,

          style: const TextStyle(

            fontSize: 12,

            color:

                Color(0xFF374151),

            fontWeight:

                FontWeight.w700,

          ),

        ),

      ],

    );

  }



  InputDecoration _inputDecoration({

    String? hint,

    IconData? prefixIcon,

    String? suffixText,

  }) {

    return InputDecoration(

      hintText: hint,

      prefixIcon: prefixIcon == null

          ? null

          : Icon(

              prefixIcon,

              color:

                  const Color(0xFF9CA3AF),

              size: 21,

            ),

      suffixText: suffixText,

      filled: true,

      fillColor:

          const Color(0xFFF8FAFC),

      contentPadding:

          const EdgeInsets.symmetric(

        horizontal: 16,

        vertical: 15,

      ),

      border: OutlineInputBorder(

        borderRadius:

            BorderRadius.circular(15),

        borderSide: const BorderSide(

          color:

              Color(0xFFE5E7EB),

        ),

      ),

      enabledBorder:

          OutlineInputBorder(

        borderRadius:

            BorderRadius.circular(15),

        borderSide: const BorderSide(

          color:

              Color(0xFFE5E7EB),

        ),

      ),

      focusedBorder:

          OutlineInputBorder(

        borderRadius:

            BorderRadius.circular(15),

        borderSide:

            const BorderSide(

          color:

              Color(0xFF6366F1),

          width: 1.5,

        ),

      ),

    );

  }



  String _taskStatusLabel(

    TaskStatus status,

  ) {

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



  String _taskPriorityLabel(

    TaskPriority priority,

  ) {

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



  bool _isImageFile(

    String fileName,

  ) {

    final name =

        fileName.toLowerCase();



    return name.endsWith('.jpg') ||

        name.endsWith('.jpeg') ||

        name.endsWith('.png') ||

        name.endsWith('.webp') ||

        name.endsWith('.gif') ||

        name.endsWith('.heic');

  }



  IconData _fileIcon(

    String fileName,

  ) {

    final name =

        fileName.toLowerCase();



    if (name.endsWith('.pdf')) {

      return Icons.picture_as_pdf_outlined;

    }



    if (name.endsWith('.doc') ||

        name.endsWith('.docx')) {

      return Icons.description_outlined;

    }



    if (name.endsWith('.xls') ||

        name.endsWith('.xlsx') ||

        name.endsWith('.csv')) {

      return Icons.table_chart_outlined;

    }



    if (name.endsWith('.ppt') ||

        name.endsWith('.pptx')) {

      return Icons.slideshow_outlined;

    }



    if (name.endsWith('.mp4') ||

        name.endsWith('.mov') ||

        name.endsWith('.avi') ||

        name.endsWith('.mkv')) {

      return Icons.videocam_outlined;

    }



    return Icons.insert_drive_file_outlined;

  }



  void _showError(

    String message,

  ) {

    if (!mounted) return;



    ScaffoldMessenger.of(context)

        .showSnackBar(

      SnackBar(

        behavior:

            SnackBarBehavior.floating,

        backgroundColor:

            const Color(0xFF111827),

        shape:

            RoundedRectangleBorder(

          borderRadius:

              BorderRadius.circular(14),

        ),

        content: Row(

          children: [

            const Icon(

              Icons.error_outline_rounded,

              color: Color(0xFFFCA5A5),

            ),

            const SizedBox(width: 10),

            Expanded(

              child: Text(message),

            ),

          ],

        ),

      ),

    );

  }



  void _showSuccess(

    String message,

  ) {

    if (!mounted) return;



    ScaffoldMessenger.of(context)

        .showSnackBar(

      SnackBar(

        behavior:

            SnackBarBehavior.floating,

        backgroundColor:

            const Color(0xFF111827),

        shape:

            RoundedRectangleBorder(

          borderRadius:

              BorderRadius.circular(14),

        ),

        content: Row(

          children: [

            const Icon(

              Icons.check_circle_outline_rounded,

              color: Color(0xFF86EFAC),

            ),

            const SizedBox(width: 10),

            Expanded(

              child: Text(message),

            ),

          ],

        ),

      ),

    );

  }



  String _friendlyError(

    Object error,

  ) {

    final message =

        error.toString();



    if (message.contains(

      'No authenticated user',

    )) {

      return 'Please sign in again.';

    }



    if (message.contains(

      'assigned to you',

    )) {

      return 'This task is not assigned to you.';

    }



    if (message.contains(

      'Daily work entry',

    )) {

      return message

          .replaceFirst(

            'Bad state: ',

            '',

          );

    }



    if (message.startsWith(

      'Invalid argument',

    )) {

      return message;

    }



    return 'Unable to submit daily work. Please try again.';

  }

}