import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/services/ai/gemini_parser.dart';
import 'package:narwhal/services/notification_service.dart';

class AddEditTaskViewModel extends ChangeNotifier {
  final TaskNodeRepository _repository;
  final GeminiParser _geminiParser;
  final TaskNode? _existingTask;

  String title = "";
  String description = "";
  int priority = 1;
  NodeType _nodeType = NodeType.task;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int durationMinutes = 0;
  String? recurrenceRule;
  String? colorHex;
  bool isCompleted = false;
  List<TaskNode> subtasks = [];
  bool isGeneratingChecklist = false;
  
  bool isCustomDuration = false; // NEW
  bool isStrategy = false;
  DateTime? deadline;
  
  String? parentId;
  List<TaskNode> availableProjects = [];

  late final String _taskId;
  bool _isNewTask = false;
  Timer? _debounceTimer;

  AddEditTaskViewModel(this._repository, this._geminiParser, this._existingTask, {String? initialTitle}) {
    _taskId = _existingTask?.id ?? const Uuid().v4();
    _isNewTask = _existingTask == null;

    if (_existingTask != null) {
      title = _existingTask.title;
      description = _existingTask.description;
      priority = _existingTask.priority;
      _nodeType = _existingTask.nodeType;
      selectedDate = _existingTask.scheduledDate;
      if (_existingTask.scheduledDate != null) {
        selectedTime = TimeOfDay.fromDateTime(_existingTask.scheduledDate!);
      }
      durationMinutes = _existingTask.durationMinutes;
      recurrenceRule = _existingTask.recurrenceRule;
      colorHex = _existingTask.colorHex;
      isCompleted = _existingTask.isCompleted;
      
      isStrategy = _existingTask.categoryId == "Strategy";
      deadline = _existingTask.deadline;
      
      // If duration is not one of the quick ones, set custom to true
      if (![0, 1, 2, 5].contains(durationMinutes)) {
        isCustomDuration = true;
      }
      
      parentId = _existingTask.parentId;
      
      _loadSubtasks();
    } else if (initialTitle != null) {
      title = initialTitle;
    }
    
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final allProjects = await _repository.getNodesByType(NodeType.project);
    final allPhases = await _repository.getNodesByType(NodeType.phase);
    availableProjects = [...allProjects, ...allPhases];
    notifyListeners();
  }

  Future<void> _loadSubtasks() async {
    if (_existingTask == null) return;
    subtasks = await _repository.getChildrenOf(_existingTask.id);
    notifyListeners();
  }

  void onAddSubtask(String subtaskTitle) {
    if (subtaskTitle.trim().isEmpty) return;
    final subtask = TaskNode(
      title: subtaskTitle,
      parentId: _taskId,
      categoryId: "SUB",
      scheduledDate: selectedDate,
      nodeType: NodeType.task,
    );
    subtasks.add(subtask);
    notifyListeners();
    _onContentChanged();
  }

  void onDeleteSubtask(int index) {
    final removed = subtasks.removeAt(index);
    _repository.deleteNode(removed.id);
    notifyListeners();
    _onContentChanged();
  }

  void onToggleSubtask(int index, bool value) {
    final sub = subtasks[index];
    subtasks[index] = sub.copyWith(
      isCompleted: value,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    notifyListeners();
    _onContentChanged();
  }

  Future<void> generateAIChecklist() async {
    if (title.trim().isEmpty) return;
    isGeneratingChecklist = true;
    notifyListeners();

    try {
      final items = await _geminiParser.generateChecklist(title);
      for (var item in items) {
        onAddSubtask(item);
      }
    } finally {
      isGeneratingChecklist = false;
      notifyListeners();
    }
  }

  void _onContentChanged() {
    if (title.trim().isEmpty) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      saveTask();
    });
  }

  void onTitleChange(String value) {
    title = value;
    notifyListeners();
    _onContentChanged();
  }

  void onDescriptionChange(String value) {
    description = value;
    notifyListeners();
    _onContentChanged();
  }

  void onPriorityChange(int value) {
    priority = value;
    notifyListeners();
    _onContentChanged();
  }

  void onDateChange(DateTime? value) {
    selectedDate = value;
    notifyListeners();
    _onContentChanged();
  }

  void onTimeChange(TimeOfDay? value) {
    selectedTime = value;
    notifyListeners();
    _onContentChanged();
  }

  void clearSchedule() {
    selectedDate = null;
    selectedTime = null;
    notifyListeners();
    _onContentChanged();
  }

  void setDuration(int value, {bool isCustom = false}) {
    durationMinutes = value;
    isCustomDuration = isCustom;
    notifyListeners();
    _onContentChanged();
  }

  void onColorChange(String? value) {
    colorHex = value;
    notifyListeners();
    _onContentChanged();
  }

  void onRecurrenceChange(String? value) {
    recurrenceRule = value;
    notifyListeners();
    _onContentChanged();
  }

  void onStrategyChange(bool value) {
    isStrategy = value;
    notifyListeners();
    _onContentChanged();
  }

  void onDeadlineChange(DateTime? value) {
    deadline = value;
    notifyListeners();
    _onContentChanged();
  }

  void onParentChange(String? value) {
    parentId = value;
    notifyListeners();
    _onContentChanged();
  }

  Future<void> saveTask() async {
    DateTime? finalScheduledDate;
    if (selectedDate != null) {
      finalScheduledDate = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime?.hour ?? 0,
        selectedTime?.minute ?? 0,
      );
    }

    final mainTask = TaskNode(
      id: _taskId,
      title: title,
      description: description,
      priority: priority,
      colorHex: colorHex,
      scheduledDate: finalScheduledDate,
      durationMinutes: durationMinutes,
      recurrenceRule: recurrenceRule,
      isCompleted: isCompleted,
      nodeType: _nodeType,
      
      // Strategy Support
      categoryId: isStrategy ? "Strategy" : (_existingTask?.categoryId ?? "General"),
      deadline: deadline,
      
      // Preserve existing properties
      parentId: parentId,
      isZone: _existingTask?.isZone ?? false,
      startDateTime: _existingTask?.startDateTime,
      endDateTime: _existingTask?.endDateTime,
      completedDate: _existingTask?.completedDate,
      lastGeneratedDate: _existingTask?.lastGeneratedDate,
      estimatedBlocks: _existingTask?.estimatedBlocks ?? 0,
      totalBlocksSpent: _existingTask?.totalBlocksSpent ?? 0,
      userId: _existingTask?.userId,
      reminderOffsetMinutes: _existingTask?.reminderOffsetMinutes,
      
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    if (_isNewTask) {
      await _repository.upsertNode(mainTask);
      _isNewTask = false;
    } else {
      await _repository.upsertNode(mainTask);
    }

    if (mainTask.isCompleted) {
      await NotificationService().cancelTaskNotification(mainTask.id);
    } else {
      await NotificationService().scheduleTaskNotification(mainTask);
    }

    // Save subtasks
    for (var sub in subtasks) {
      final linkedSub = sub.copyWith(
        parentId: mainTask.id,
        scheduledDate: finalScheduledDate,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _repository.upsertNode(linkedSub);
    }
  }

  Future<void> deleteTask() async {
    if (!_isNewTask) {
      await _repository.deleteNode(_taskId);
      await NotificationService().cancelTaskNotification(_taskId);
    }
  }

  Future<void> convertToProject() async {
    _nodeType = NodeType.project;
    await saveTask();
  }

  @override
  void dispose() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      if (title.trim().isNotEmpty) {
        saveTask(); // Fire and forget final save
      }
    }
    super.dispose();
  }
}
