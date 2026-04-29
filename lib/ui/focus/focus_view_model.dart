import 'dart:async';
import 'package:flutter/material.dart';
import 'package:planner/data/entity/task.dart';
import 'package:planner/data/entity/time_log.dart';
import 'package:planner/data/repository/task_repository.dart';

class FocusViewModel extends ChangeNotifier {
  final TaskRepository _repository;

  Task? activeTask;
  bool isRunning = false;
  int sessionBlocksEarned = 0;
  double currentBlockProgress = 0.0;
  int elapsedSecondsInBlock = 0;
  final int blockSeconds = 5 * 60; // 5 minutes

  List<Task> availableTasks = [];
  Timer? _timer;

  FocusViewModel(this._repository) {
    _loadAvailableTasks();
  }

  Future<void> _loadAvailableTasks() async {
    final tasks = await _repository.getAllTasks();
    availableTasks = tasks.where((t) => !t.isCompleted).toList();
    notifyListeners();
  }

  void selectTask(Task task) {
    activeTask = task;
    notifyListeners();
  }

  void toggleTimer() {
    if (isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void stopSession() {
    _pauseTimer();
    activeTask = null;
    sessionBlocksEarned = 0;
    elapsedSecondsInBlock = 0;
    currentBlockProgress = 0.0;
    notifyListeners();
  }

  void _startTimer() {
    if (activeTask == null) return;
    isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
    notifyListeners();
  }

  void _pauseTimer() {
    isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void _tick() {
    elapsedSecondsInBlock++;
    if (elapsedSecondsInBlock >= blockSeconds) {
      _commitBlockToDb();
      elapsedSecondsInBlock = 0;
      sessionBlocksEarned++;
      currentBlockProgress = 0.0;
    } else {
      currentBlockProgress = elapsedSecondsInBlock / blockSeconds;
    }
    notifyListeners();
  }

  Future<void> _commitBlockToDb() async {
    if (activeTask == null) return;

    final now = DateTime.now();
    final log = TimeLog(
      taskId: activeTask!.id,
      startTime: now.toIso8601String(),
      blocksEarned: 1,
      dateLogged: "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
    );
    await _repository.insertTimeLog(log);

    final updatedTask = Task(
      id: activeTask!.id,
      title: activeTask!.title,
      description: activeTask!.description,
      categoryId: activeTask!.categoryId,
      priority: activeTask!.priority,
      parentId: activeTask!.parentId,
      isZone: activeTask!.isZone,
      scheduledDate: activeTask!.scheduledDate,
      startDateTime: activeTask!.startDateTime,
      endDateTime: activeTask!.endDateTime,
      completedDate: activeTask!.completedDate,
      deadline: activeTask!.deadline,
      durationMinutes: activeTask!.durationMinutes,
      recurrenceRule: activeTask!.recurrenceRule,
      lastGeneratedDate: activeTask!.lastGeneratedDate,
      isCompleted: activeTask!.isCompleted,
      estimatedBlocks: activeTask!.estimatedBlocks,
      totalBlocksSpent: activeTask!.totalBlocksSpent + 1,
      userId: activeTask!.userId,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.updateTask(updatedTask);
    activeTask = updatedTask;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
