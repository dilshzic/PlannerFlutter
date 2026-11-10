import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/services/focus_timer_service.dart';

class FocusViewModel extends ChangeNotifier {
  final FocusTimerService focusTimer;
  final TaskNode? task;

  FocusViewModel(this.focusTimer, {this.task}) {
    focusTimer.addListener(notifyListeners);
    if (task != null && focusTimer.activeId != task!.id) {
      focusTimer.startSession(
        id: task!.id,
        title: task!.title,
        task: task,
        colorHex: task!.colorHex,
      );
    }
  }

  bool get isRunning => focusTimer.isRunning;
  String get timeString => focusTimer.currentBlockTimeString;
  double get currentBlockProgress => focusTimer.currentBlockProgress;
  int get sessionBlocksEarned => focusTimer.sessionBlocksEarned;
  String get totalSessionTimeString => focusTimer.totalSessionTimeString;

  void startTimer() => focusTimer.resumeSession();
  void pauseTimer() => focusTimer.pauseSession();
  void stopTimer() => focusTimer.stopSession();
  Future<void> finishTask() => focusTimer.finishTask();

  @override
  void dispose() {
    focusTimer.removeListener(notifyListeners);
    super.dispose();
  }
}
