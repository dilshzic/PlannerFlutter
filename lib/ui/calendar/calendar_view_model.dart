import 'package:flutter/material.dart';
import 'package:planner/data/repository/task_repository.dart';
import 'package:planner/data/entity/task.dart';
import 'package:planner/data/entity/workload_level.dart';

class CalendarDayState {
  final DateTime date;
  final WorkloadLevel workload;
  final List<Task> tasks;

  CalendarDayState({required this.date, required this.workload, required this.tasks});
}

class CalendarViewModel extends ChangeNotifier {
  final TaskRepository _repository;

  DateTime focusedDay = DateTime.now();
  Map<DateTime, CalendarDayState> dayStates = {};
  List<Task> allTasks = [];

  CalendarViewModel(this._repository) {
    _loadAllTasks();
  }

  Future<void> _loadAllTasks() async {
    allTasks = await _repository.getAllTasks();
    _calculateDayStates();
    notifyListeners();
  }

  void _calculateDayStates() {
    // Group tasks by day and calculate workload
    final groupedTasks = <DateTime, List<Task>>{};
    for (var task in allTasks) {
      if (task.scheduledDate == null) continue;
      final day = DateTime(task.scheduledDate!.year, task.scheduledDate!.month, task.scheduledDate!.day);
      groupedTasks.putIfAbsent(day, () => []).add(task);
    }

    dayStates = groupedTasks.map((day, tasks) {
      final totalMinutes = tasks.fold(0, (sum, t) => sum + (t.parentId == null ? t.durationMinutes : 0));
      final workload = _calculateWorkload(totalMinutes);
      return MapEntry(day, CalendarDayState(date: day, workload: workload, tasks: tasks));
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

  WorkloadLevel getWorkloadForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return dayStates[normalizedDay]?.workload ?? WorkloadLevel.RECOVERY;
  }

  List<Task> getTasksForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return dayStates[normalizedDay]?.tasks ?? [];
  }
}
