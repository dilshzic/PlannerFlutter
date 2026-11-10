import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';

class TriageViewModel extends ChangeNotifier {
  final TaskNodeRepository _repository;
  StreamSubscription? _taskSubscription;
  List<TaskNode> backlogTasks = [];

  TriageViewModel(this._repository) {
    loadBacklog();
    _taskSubscription = _repository.nodeUpdates.listen((_) => loadBacklog());
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadBacklog() async {
    final tasks = await _repository.getNodesByType(NodeType.task);
    // Backlog tasks are those that are not completed and have no scheduled date
    backlogTasks = tasks.where((t) => !t.isCompleted && t.scheduledDate == null).toList();
    notifyListeners();
  }

  Future<void> onMoveToToday(TaskNode task) async {
    final now = DateTime.now();
    final updatedTask = task.copyWith(
      scheduledDate: DateTime(now.year, now.month, now.day, 9, 0),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.upsertNode(updatedTask);
  }

  Future<void> onMoveToTomorrow(TaskNode task) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final updatedTask = task.copyWith(
      scheduledDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.upsertNode(updatedTask);
  }

  Future<void> onDeleteTask(String id) async {
    await _repository.deleteNode(id);
  }
}
