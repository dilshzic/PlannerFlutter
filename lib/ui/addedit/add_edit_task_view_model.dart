import 'package:flutter/material.dart';
import 'package:planner/data/entity/task.dart';
import 'package:planner/data/repository/task_repository.dart';
import 'package:planner/logic/gemini_parser.dart';

class AddEditTaskViewModel extends ChangeNotifier {
  final TaskRepository _repository;
  final GeminiParser _geminiParser;
  final Task? _existingTask;

  String title = "";
  String description = "";
  int priority = 1;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int durationMinutes = 30;
  String? recurrenceRule;
  bool isCompleted = false;
  List<Task> subtasks = [];
  bool isGeneratingChecklist = false;

  AddEditTaskViewModel(this._repository, this._geminiParser, [this._existingTask]) {
    if (_existingTask != null) {
      title = _existingTask.title;
      description = _existingTask.description;
      priority = _existingTask.priority;
      selectedDate = _existingTask.scheduledDate;
      if (_existingTask.scheduledDate != null) {
        selectedTime = TimeOfDay.fromDateTime(_existingTask.scheduledDate!);
      }
      durationMinutes = _existingTask.durationMinutes;
      recurrenceRule = _existingTask.recurrenceRule;
      isCompleted = _existingTask.isCompleted;
      _loadSubtasks();
    }
  }

  Future<void> _loadSubtasks() async {
    if (_existingTask == null) return;
    subtasks = await _repository.getSubtasks(_existingTask.id);
    notifyListeners();
  }

  void onAddSubtask(String subtaskTitle) {
    if (subtaskTitle.trim().isEmpty) return;
    final subtask = Task(
      title: subtaskTitle,
      parentId: _existingTask?.id, // Note: if new task, parentId is null for now
      categoryId: "SUB",
      scheduledDate: selectedDate,
    );
    subtasks.add(subtask);
    notifyListeners();
  }

  void onDeleteSubtask(int index) {
    subtasks.removeAt(index);
    notifyListeners();
  }

  void onToggleSubtask(int index, bool value) {
    final sub = subtasks[index];
    subtasks[index] = Task(
      id: sub.id,
      title: sub.title,
      description: sub.description,
      categoryId: sub.categoryId,
      priority: sub.priority,
      parentId: sub.parentId,
      isZone: sub.isZone,
      scheduledDate: sub.scheduledDate,
      startDateTime: sub.startDateTime,
      endDateTime: sub.endDateTime,
      completedDate: sub.completedDate,
      deadline: sub.deadline,
      durationMinutes: sub.durationMinutes,
      recurrenceRule: sub.recurrenceRule,
      lastGeneratedDate: sub.lastGeneratedDate,
      isCompleted: value,
      estimatedBlocks: sub.estimatedBlocks,
      totalBlocksSpent: sub.totalBlocksSpent,
      userId: sub.userId,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    notifyListeners();
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

  void onTitleChange(String value) {
    title = value;
    notifyListeners();
  }

  void onDescriptionChange(String value) {
    description = value;
    notifyListeners();
  }

  void onPriorityChange(int value) {
    priority = value;
    notifyListeners();
  }

  void onDateChange(DateTime? value) {
    selectedDate = value;
    notifyListeners();
  }

  void onTimeChange(TimeOfDay? value) {
    selectedTime = value;
    notifyListeners();
  }

  void onDurationChange(int value) {
    durationMinutes = value;
    notifyListeners();
  }

  void onRecurrenceChange(String? value) {
    recurrenceRule = value;
    notifyListeners();
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

    final mainTask = Task(
      id: _existingTask?.id,
      title: title,
      description: description,
      priority: priority,
      scheduledDate: finalScheduledDate,
      durationMinutes: durationMinutes,
      recurrenceRule: recurrenceRule,
      isCompleted: isCompleted,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    if (_existingTask == null) {
      await _repository.insertTask(mainTask);
    } else {
      await _repository.updateTask(mainTask);
    }

    // Save subtasks
    for (var sub in subtasks) {
      final linkedSub = Task(
        id: sub.id,
        title: sub.title,
        description: sub.description,
        categoryId: sub.categoryId,
        priority: sub.priority,
        parentId: mainTask.id,
        isZone: sub.isZone,
        scheduledDate: finalScheduledDate,
        startDateTime: sub.startDateTime,
        endDateTime: sub.endDateTime,
        completedDate: sub.completedDate,
        deadline: sub.deadline,
        durationMinutes: sub.durationMinutes,
        recurrenceRule: sub.recurrenceRule,
        lastGeneratedDate: sub.lastGeneratedDate,
        isCompleted: sub.isCompleted,
        estimatedBlocks: sub.estimatedBlocks,
        totalBlocksSpent: sub.totalBlocksSpent,
        userId: sub.userId,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _repository.insertTask(linkedSub);
    }
  }
}
