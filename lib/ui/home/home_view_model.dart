import 'package:flutter/material.dart';
import 'package:planner/data/entity/task.dart';
import 'package:planner/data/entity/task_with_subtasks.dart';
import 'package:planner/data/entity/workload_level.dart';
import 'package:planner/data/repository/task_repository.dart';
import 'package:planner/logic/gemini_parser.dart';

class HomeViewModel extends ChangeNotifier {
  final TaskRepository _repository;
  final GeminiParser _geminiParser;

  List<TaskWithSubtasks> tasks = [];
  Set<String> expandedTaskIds = {};
  DateTime selectedDate = DateTime.now();
  String quickAddText = "";
  bool isLoading = false;
  bool isAnalyzingWorkload = false;
  String dailyMotivation = "Let's make today count!";
  String? reschedulingSuggestion;

  int totalTasks = 0;
  int completedTasks = 0;
  int totalMinutes = 0;
  WorkloadLevel workloadStatus = WorkloadLevel.RECOVERY;

  HomeViewModel(this._repository, this._geminiParser) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    final allTasks = await _repository.getAllTasks();
    final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    final dailyTopLevelTasks = allTasks.where((t) {
      if (t.scheduledDate == null) return false;
      final tDate = DateTime(t.scheduledDate!.year, t.scheduledDate!.month, t.scheduledDate!.day);
      return tDate.isAtSameMomentAs(today) && t.parentId == null;
    }).toList();

    tasks = [];
    for (var task in dailyTopLevelTasks) {
      final subtasks = allTasks.where((t) => t.parentId == task.id).toList();
      tasks.add(TaskWithSubtasks(task: task, subtasks: subtasks));
    }

    // Calculate stats including subtasks
    totalTasks = 0;
    completedTasks = 0;
    totalMinutes = 0;

    for (var task in allTasks) {
      if (task.scheduledDate == null) continue;
      final tDate = DateTime(task.scheduledDate!.year, task.scheduledDate!.month, task.scheduledDate!.day);
      if (tDate.isAtSameMomentAs(today)) {
        totalTasks++;
        if (task.isCompleted) completedTasks++;
        if (task.parentId == null) totalMinutes += task.durationMinutes;
      }
    }

    workloadStatus = _calculateStatus(totalMinutes);
    notifyListeners();
  }

  void onToggleExpand(String taskId) {
    if (expandedTaskIds.contains(taskId)) {
      expandedTaskIds.remove(taskId);
    } else {
      expandedTaskIds.add(taskId);
    }
    notifyListeners();
  }

  WorkloadLevel _calculateStatus(int minutes) {
    if (minutes >= 480) return WorkloadLevel.CASUALTY;
    if (minutes >= 240) return WorkloadLevel.GRIND;
    return WorkloadLevel.RECOVERY;
  }

  Future<void> analyzeWorkloadForRescheduling() async {
    if (workloadStatus != WorkloadLevel.CASUALTY) return;
    isAnalyzingWorkload = true;
    notifyListeners();

    try {
      final taskTitles = tasks.where((t) => !t.task.isCompleted).map((t) => t.task.title).toList();
      reschedulingSuggestion = await _geminiParser.suggestRescheduling(taskTitles, workloadStatus.name);
    } finally {
      isAnalyzingWorkload = false;
      notifyListeners();
    }
  }

  void dismissSuggestion() {
    reschedulingSuggestion = null;
    notifyListeners();
  }

  void onQuickAddTextChanged(String text) {
    quickAddText = text;
    notifyListeners();
  }

  Future<void> onQuickAdd() async {
    if (quickAddText.trim().isEmpty) return;
    isLoading = true;
    notifyListeners();

    try {
      final parsed = await _geminiParser.parseTask(quickAddText);
      if (parsed != null) {
        final newTask = Task(
          title: parsed.title,
          priority: parsed.priority,
          scheduledDate: parsed.date ?? selectedDate,
          durationMinutes: parsed.durationMinutes,
          isZone: parsed.isZone,
          recurrenceRule: parsed.recurrenceRule,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await _repository.insertTask(newTask);
        quickAddText = "";
        loadTasks();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(Task task, bool isCompleted) async {
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      categoryId: task.categoryId,
      priority: task.priority,
      parentId: task.parentId,
      isZone: task.isZone,
      scheduledDate: task.scheduledDate,
      startDateTime: task.startDateTime,
      endDateTime: task.endDateTime,
      completedDate: isCompleted ? DateTime.now() : null,
      deadline: task.deadline,
      durationMinutes: task.durationMinutes,
      recurrenceRule: task.recurrenceRule,
      lastGeneratedDate: task.lastGeneratedDate,
      isCompleted: isCompleted,
      estimatedBlocks: task.estimatedBlocks,
      totalBlocksSpent: task.totalBlocksSpent,
      userId: task.userId,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.updateTask(updatedTask);
    loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    loadTasks();
  }
}
