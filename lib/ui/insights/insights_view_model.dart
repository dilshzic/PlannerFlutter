import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';

class ProjectProgress {
  final TaskNode project;
  final int totalTasks;
  final int completedTasks;

  double get percent => totalTasks == 0 ? 0 : completedTasks / totalTasks;

  ProjectProgress(this.project, this.totalTasks, this.completedTasks);
}

class InsightsViewModel extends ChangeNotifier {
  final TaskNodeRepository _repository;
  StreamSubscription? _subscription;

  bool isLoading = true;

  int totalCompleted = 0;
  int totalPending = 0;
  int totalMinutesLogged = 0;

  List<ProjectProgress> projectProgressList = [];

  InsightsViewModel(this._repository) {
    _subscription = _repository.nodeUpdates.listen((_) {
      loadData();
    });
    loadData();
  }

  Future<void> loadData() async {
    final allTasks = await _repository.getNodesByType(NodeType.task);
    final allProjects = await _repository.getNodesByType(NodeType.project);

    int comp = 0;
    int pend = 0;
    int mins = 0;

    for (var task in allTasks) {
      if (task.isCompleted) {
        comp++;
        mins += task.durationMinutes;
      } else {
        pend++;
      }
    }
    
    totalCompleted = comp;
    totalPending = pend;
    totalMinutesLogged = mins;

    List<ProjectProgress> progress = [];
    for (var proj in allProjects) {
      if (proj.isCompleted) continue; // Skip archived/completed
      int pTotal = 0;
      int pComp = 0;
      for (var task in allTasks) {
        // Simple heuristic: if task is in this project
        if (task.parentId == proj.id) {
          pTotal++;
          if (task.isCompleted) pComp++;
        }
      }
      progress.add(ProjectProgress(proj, pTotal, pComp));
    }

    // Sort by most progress
    progress.sort((a, b) => b.percent.compareTo(a.percent));
    projectProgressList = progress;

    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
