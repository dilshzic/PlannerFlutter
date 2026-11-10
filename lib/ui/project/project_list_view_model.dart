import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';

class ProjectListViewModel extends ChangeNotifier {
  final TaskNodeRepository _repository;
  List<TaskNode> activeProjects = [];
  List<TaskNode> archivedProjects = [];
  
  bool isLoading = false;
  StreamSubscription? _projectSubscription;

  ProjectListViewModel(this._repository) {
    loadProjects();
    _projectSubscription = _repository.nodeUpdates.listen((_) => loadProjects());
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadProjects() async {
    isLoading = true;
    notifyListeners();
    
    final allProjects = await _repository.getNodesByType(NodeType.project);
    
    // Sort by pinned, then most recent use, then updated
    allProjects.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      final aAccess = a.lastAccessedAt ?? 0;
      final bAccess = b.lastAccessedAt ?? 0;
      if (aAccess != bAccess) {
        return bAccess.compareTo(aAccess);
      }
      
      return b.updatedAt.compareTo(a.updatedAt);
    });
    
    activeProjects = allProjects.where((p) => !p.isCompleted).toList();
    archivedProjects = allProjects.where((p) => p.isCompleted).toList();
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> archiveProject(TaskNode project, bool archive) async {
    final updated = project.copyWith(
      isCompleted: archive,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.upsertNode(updated);
  }

  Future<void> addProject(String title, String description, String? colorHex) async {
    final project = TaskNode(
      title: title, 
      description: description, 
      colorHex: colorHex,
      nodeType: NodeType.project,
    );
    await _repository.upsertNode(project);
    await loadProjects();
  }

  Future<void> deleteProject(String id) async {
    await _repository.deleteNode(id);
    await loadProjects();
  }

  Future<void> togglePin(TaskNode project) async {
    final updated = project.copyWith(isPinned: !project.isPinned);
    await _repository.upsertNode(updated);
  }

  Future<void> markProjectAccessed(TaskNode project) async {
    final updated = project.copyWith(
      lastAccessedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.upsertNode(updated);
  }
}
