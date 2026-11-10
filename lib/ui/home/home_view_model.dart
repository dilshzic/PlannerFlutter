import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:flutter_core_entities/task_with_subtasks.dart';
import 'package:flutter_core_entities/workload_level.dart';
import 'package:flutter_core_entities/category.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/data/repository/category_repository.dart';
import 'package:narwhal/services/ai/gemini_parser.dart';
import 'package:narwhal/services/notification_service.dart';

class HomeViewModel extends ChangeNotifier {
  final TaskNodeRepository _nodeRepo;
  final CategoryRepository _categoryRepo;
  final GeminiParser _geminiParser;

  StreamSubscription? _nodeSubscription;

  List<TaskWithSubtasks> todayTasks = [];
  List<TaskWithSubtasks> backlogTasks = []; // UPDATED TYPE
  List<Category> categories = [];
  Map<String, TaskNode> projectsMap = {};
  Set<String> expandedTaskIds = {};
  
  DateTime selectedDate = DateTime.now();
  String quickAddText = "";
  bool isLoading = false;
  bool isAnalyzingWorkload = false;
  String dailyMotivation = "Ready to conquer the day?";
  String? reschedulingSuggestion;

  // Stats
  int totalTasksCount = 0;
  int completedTasksCount = 0;
  int totalMinutes = 0;
  WorkloadLevel workloadStatus = WorkloadLevel.RECOVERY;

  HomeViewModel(this._nodeRepo, this._categoryRepo, this._geminiParser) {
    _init();
  }

  Future<void> _init() async {
    // Subscribe FIRST so we never miss the initial Firestore snapshot event
    _nodeSubscription = _nodeRepo.nodeUpdates.listen((_) {
      loadProjects();
      loadData();
    });

    await loadCategories();
    await loadProjects();
    await loadData(); // Also call once in case tasks are already in memory
  }

  @override
  void dispose() {
    _nodeSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadCategories() async {
    categories = await _categoryRepo.getAllCategories();
    notifyListeners();
  }

  Future<void> loadProjects() async {
    final allProjects = await _nodeRepo.getNodesByType(NodeType.project);
    projectsMap = {for (var p in allProjects) p.id: p};
    notifyListeners();
  }

  Future<void> loadData() async {
    final allTasks = await _nodeRepo.getNodesByType(NodeType.task);
    final taskIds = allTasks.map((t) => t.id).toSet();
    bool isSubtask(TaskNode t) => t.parentId != null && taskIds.contains(t.parentId);

    final todayStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final todayEnd = todayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    
    // 1. Filter Today's Tasks (top-level tasks: standalone or belonging to a project/phase)
    final dailyTopLevelTasks = allTasks.where((t) {
      if (t.scheduledDate == null) return false;
      return t.scheduledDate!.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) && 
             t.scheduledDate!.isBefore(todayEnd.add(const Duration(milliseconds: 1))) && 
             !isSubtask(t);
    }).toList();

    todayTasks = [];
    for (var task in dailyTopLevelTasks) {
      final subtasks = allTasks.where((t) => t.parentId == task.id).toList();
      todayTasks.add(TaskWithSubtasks(task: task, subtasks: subtasks));
    }

    // 2. Filter Backlog Tasks (Include subtasks for counting)
    final rawBacklogTopLevel = allTasks.where((t) {
      if (t.isCompleted || isSubtask(t)) return false;
      if (t.scheduledDate == null) return true;
      return t.scheduledDate!.isBefore(todayStart);
    }).toList();

    backlogTasks = [];
    for (var task in rawBacklogTopLevel) {
      final subtasks = allTasks.where((t) => t.parentId == task.id).toList();
      backlogTasks.add(TaskWithSubtasks(task: task, subtasks: subtasks));
    }

    // 3. Calculate Global Stats
    totalTasksCount = 0;
    completedTasksCount = 0;
    totalMinutes = 0;

    for (var task in allTasks) {
      if (task.scheduledDate == null) continue;
      final tDate = DateTime(task.scheduledDate!.year, task.scheduledDate!.month, task.scheduledDate!.day);
      if (tDate.isAtSameMomentAs(todayStart)) {
        totalTasksCount++;
        if (task.isCompleted) completedTasksCount++;
        if (!isSubtask(task)) totalMinutes += task.durationMinutes;
      }
    }

    workloadStatus = _calculateStatus(totalMinutes);
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    selectedDate = date;
    loadData();
    // notifyListeners() is called in loadData()
  }

  WorkloadLevel _calculateStatus(int minutes) {
    if (minutes >= 480) return WorkloadLevel.CASUALTY;
    if (minutes >= 240) return WorkloadLevel.GRIND;
    return WorkloadLevel.RECOVERY;
  }

  // --- ACTIONS ---

  Future<void> moveToToday(TaskNode task) async {
    final now = DateTime.now();
    final updated = task.copyWith(
      scheduledDate: DateTime(now.year, now.month, now.day, 9, 0),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _nodeRepo.upsertNode(updated);
    if (!updated.isCompleted) {
      await NotificationService().scheduleTaskNotification(updated);
    }
  }

  Future<void> scheduleTask(TaskNode task, DateTime date) async {
    final updated = task.copyWith(
      scheduledDate: date,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _nodeRepo.upsertNode(updated);
    if (!updated.isCompleted) {
      await NotificationService().scheduleTaskNotification(updated);
    }
  }

  Future<void> moveToBacklog(TaskNode task) async {
    final updated = task.copyWith(
      scheduledDate: null,
      clearScheduledDate: true,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _nodeRepo.upsertNode(updated);
    await NotificationService().cancelTaskNotification(task.id);
  }

  Future<void> quickAddTask({
    required String title,
    String? categoryId,
    DateTime? date,
    int priority = 1,
    String? colorHex,
  }) async {
    final newTask = TaskNode(
      title: title,
      categoryId: categoryId ?? "General",
      scheduledDate: date,
      priority: priority,
      colorHex: colorHex,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      nodeType: NodeType.task,
    );
    await _nodeRepo.upsertNode(newTask);
    if (newTask.scheduledDate != null) {
      await NotificationService().scheduleTaskNotification(newTask);
    }
  }

  Future<void> onQuickAdd() async {
    if (quickAddText.trim().isEmpty) return;
    isLoading = true;
    notifyListeners();

    try {
      final parsed = await _geminiParser.parseTask(quickAddText);
      if (parsed != null) {
        final newTask = TaskNode(
          title: parsed.title,
          priority: parsed.priority,
          scheduledDate: parsed.date ?? selectedDate,
          durationMinutes: parsed.durationMinutes,
          isZone: parsed.isZone,
          recurrenceRule: parsed.recurrenceRule,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          nodeType: NodeType.task,
        );
        await _nodeRepo.upsertNode(newTask);
        if (newTask.scheduledDate != null) {
          await NotificationService().scheduleTaskNotification(newTask);
        }
      } else {
        // Fallback: create a plain task with the raw input
        final fallbackTask = TaskNode(
          title: quickAddText,
          scheduledDate: selectedDate,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          nodeType: NodeType.task,
        );
        await _nodeRepo.upsertNode(fallbackTask);
      }
      quickAddText = "";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void onQuickAddTextChanged(String text) {
    quickAddText = text;
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(TaskNode task, bool isCompleted) async {
    await _nodeRepo.toggleNodeCompletion(task.id, isCompleted);
    if (isCompleted) {
      await NotificationService().cancelTaskNotification(task.id);
    } else {
      // Find the task after it's been updated to re-schedule
      final updatedTask = task.copyWith(isCompleted: false);
      await NotificationService().scheduleTaskNotification(updatedTask);
    }
  }

  Future<void> deleteTask(String id) async {
    await _nodeRepo.deleteNode(id);
    await NotificationService().cancelTaskNotification(id);
  }

  void onToggleExpand(String taskId) {
    if (expandedTaskIds.contains(taskId)) {
      expandedTaskIds.remove(taskId);
    } else {
      expandedTaskIds.add(taskId);
    }
    notifyListeners();
  }

  void dismissSuggestion() {
    reschedulingSuggestion = null;
    notifyListeners();
  }

  Future<void> analyzeWorkloadForRescheduling() async {
    if (workloadStatus != WorkloadLevel.CASUALTY) return;
    isAnalyzingWorkload = true;
    notifyListeners();

    try {
      final taskTitles = todayTasks.where((t) => !t.task.isCompleted).map((t) => t.task.title).toList();
      reschedulingSuggestion = await _geminiParser.suggestRescheduling(taskTitles, workloadStatus.name);
    } finally {
      isAnalyzingWorkload = false;
      notifyListeners();
    }
  }
}
