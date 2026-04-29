import 'package:flutter/material.dart';
import 'package:planner/data/entity/task.dart';
import 'package:planner/data/repository/task_repository.dart';

class TriageViewModel extends ChangeNotifier {
  final TaskRepository _repository;
  List<Task> backlogTasks = [];

  TriageViewModel(this._repository) {
    loadBacklog();
  }

  Future<void> loadBacklog() async {
    final tasks = await _repository.getAllTasks();
    // Backlog tasks are those that are not completed and have no scheduled date
    backlogTasks = tasks.where((t) => !t.isCompleted && t.scheduledDate == null).toList();
    notifyListeners();
  }

  Future<void> onMoveToToday(Task task) async {
    final now = DateTime.now();
    final updatedTask = _updateTaskDate(task, DateTime(now.year, now.month, now.day, 9, 0)); // Default to 9 AM today
    await _repository.updateTask(updatedTask);
    loadBacklog();
  }

  Future<void> onMoveToTomorrow(Task task) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final updatedTask = _updateTaskDate(task, DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0)); // Default to 9 AM tomorrow
    await _repository.updateTask(updatedTask);
    loadBacklog();
  }

  Future<void> onDeleteTask(String id) async {
    await _repository.deleteTask(id);
    loadBacklog();
  }

  Task _updateTaskDate(Task task, DateTime date) {
    return Task(
      id: task.id,
      title: task.title,
      description: task.description,
      categoryId: task.categoryId,
      priority: task.priority,
      parentId: task.parentId,
      isZone: task.isZone,
      scheduledDate: date,
      startDateTime: task.startDateTime,
      endDateTime: task.endDateTime,
      completedDate: task.completedDate,
      deadline: task.deadline,
      durationMinutes: task.durationMinutes,
      recurrenceRule: task.recurrenceRule,
      lastGeneratedDate: task.lastGeneratedDate,
      isCompleted: task.isCompleted,
      estimatedBlocks: task.estimatedBlocks,
      totalBlocksSpent: task.totalBlocksSpent,
      userId: task.userId,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
