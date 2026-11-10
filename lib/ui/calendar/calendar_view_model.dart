import 'dart:async';
import 'package:flutter/material.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:flutter_core_entities/workload_level.dart';

class CalendarDayState {
  final DateTime date;
  final WorkloadLevel workload;
  final List<TaskNode> tasks;
  final List<TaskNode> zones;

  CalendarDayState({
    required this.date, 
    required this.workload, 
    required this.tasks, 
    required this.zones,
  });
}

class CalendarViewModel extends ChangeNotifier {
  final TaskNodeRepository _nodeRepo;
  StreamSubscription? _nodeSubscription;

  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay = DateTime.now();
  Map<DateTime, CalendarDayState> dayStates = {};
  List<TaskNode> allTasks = [];
  List<TaskNode> activeStrategyGoals = [];

  CalendarViewModel(this._nodeRepo) {
    _nodeSubscription = _nodeRepo.nodeUpdates.listen((_) {
      _loadAllTasks();
    });
    _loadAllTasks();
  }

  @override
  void dispose() {
    _nodeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAllTasks() async {
    allTasks = await _nodeRepo.getNodesByType(NodeType.task);
    
    final strategyTasks = allTasks.where((t) => t.categoryId == 'Strategy' && t.deadline != null && !t.isCompleted).toList();
    strategyTasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));
    activeStrategyGoals = strategyTasks.where((t) => t.deadline!.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();
    
    _calculateDayStates();
    notifyListeners();
  }

  void _calculateDayStates() {
    final taskIds = allTasks.map((t) => t.id).toSet();
    bool isSubtask(TaskNode t) => t.parentId != null && taskIds.contains(t.parentId);

    final groupedTasks = <DateTime, List<TaskNode>>{};
    for (var task in allTasks) {
      if (task.scheduledDate == null) continue;
      final day = DateTime(task.scheduledDate!.year, task.scheduledDate!.month, task.scheduledDate!.day);
      groupedTasks.putIfAbsent(day, () => []).add(task);
    }

    dayStates = groupedTasks.map((day, tasksForDay) {
      final zones = tasksForDay.where((t) => t.isZone).toList();
      final regularTasks = tasksForDay.where((t) => !t.isZone).toList();
      
      final totalMinutes = tasksForDay.fold(0, (sum, t) => sum + (!isSubtask(t) ? t.durationMinutes : 0));
      final workload = _calculateWorkload(totalMinutes);
      
      return MapEntry(day, CalendarDayState(
        date: day, 
        workload: workload, 
        tasks: regularTasks,
        zones: zones
      ));
    });
  }

  WorkloadLevel _calculateWorkload(int minutes) {
    if (minutes >= 480) return WorkloadLevel.CASUALTY;
    if (minutes >= 240) return WorkloadLevel.GRIND;
    return WorkloadLevel.RECOVERY;
  }

  void onMonthChanged(DateTime day) {
    focusedDay = day;
    notifyListeners();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    this.selectedDay = selectedDay;
    this.focusedDay = focusedDay;
    notifyListeners();
  }

  WorkloadLevel getWorkloadForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return dayStates[normalizedDay]?.workload ?? WorkloadLevel.RECOVERY;
  }

  List<TaskNode> getTasksForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return dayStates[normalizedDay]?.tasks ?? [];
  }

  List<TaskNode> getZonesForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return dayStates[normalizedDay]?.zones ?? [];
  }

  int getDaysTo(DateTime targetDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }
}
