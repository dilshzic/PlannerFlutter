import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/data/repository/scratchpad_repository.dart';
import 'package:flutter_core_entities/scratchpad_note.dart';

class ProjectDetailViewModel extends ChangeNotifier {
  final TaskNodeRepository _nodeRepo;
  final ScratchpadRepository _scratchpadRepo;
  TaskNode project;
  StreamSubscription? _nodeSubscription;
  StreamSubscription? _scratchpadSubscription;

  List<TaskNode> activeTasks = [];
  List<TaskNode> completedTasks = [];
  List<TaskNode> subProjects = [];
  List<TaskNode> phases = [];
  List<ScratchpadNote> linkedScratchpads = [];
  bool isLoading = false;
  
  // Notes handling
  late TextEditingController notesController;
  Timer? _notesDebounce;
  
  // Stats
  double completionPercentage = 0.0;
  int completedCount = 0;
  int totalCount = 0;

  ProjectDetailViewModel(this._nodeRepo, this._scratchpadRepo, this.project) {
    notesController = TextEditingController(text: project.notes);
    loadProjectTasks();
    loadLinkedScratchpads();
    _nodeSubscription = _nodeRepo.nodeUpdates.listen((_) {
      loadProjectData();
      loadProjectTasks();
    });
    _scratchpadSubscription = _scratchpadRepo.notesUpdates.listen((_) => loadLinkedScratchpads());
  }

  @override
  void dispose() {
    _nodeSubscription?.cancel();
    _scratchpadSubscription?.cancel();
    _notesDebounce?.cancel();
    notesController.dispose();
    super.dispose();
  }

  Future<void> loadProjectData() async {
    final updatedProject = await _nodeRepo.getNodeById(project.id);
    if (updatedProject != null && updatedProject.updatedAt > project.updatedAt) {
      project = updatedProject;
      // If notes were modified externally, update the controller (careful not to overwrite if currently editing)
      // For simplicity, we just update it if we aren't actively typing
      if (!notesController.text.contains(updatedProject.notes) && updatedProject.notes != notesController.text) {
          notesController.text = updatedProject.notes;
      }
      notifyListeners();
    }
  }

  Future<void> loadProjectTasks() async {
    if (activeTasks.isEmpty && completedTasks.isEmpty) {
      isLoading = true;
      notifyListeners();
    }

    final allChildren = await _nodeRepo.getChildrenOf(project.id);
    
    subProjects = allChildren.where((t) => t.nodeType == NodeType.project).toList();
    phases = allChildren.where((t) => t.nodeType == NodeType.phase).toList();
    final allTasks = allChildren.where((t) => t.nodeType == NodeType.task).toList();
    
    activeTasks = allTasks.where((t) => !t.isCompleted).toList();
    completedTasks = allTasks.where((t) => t.isCompleted).toList();
    
    totalCount = allTasks.length;
    completedCount = completedTasks.length;
    completionPercentage = totalCount > 0 ? completedCount / totalCount : 0.0;

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadLinkedScratchpads() async {
    final allNotes = await _scratchpadRepo.getAllNotes();
    linkedScratchpads = allNotes.where((n) => n.projectId == project.id && !n.isDeleted).toList();
    notifyListeners();
  }

  void onNotesChanged(String value) {
    if (_notesDebounce?.isActive ?? false) _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 500), () async {
      final updatedProject = project.copyWith(
        notes: value,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _nodeRepo.upsertNode(updatedProject);
      project = updatedProject;
      // No need for notifyListeners here if we only want to save, 
      // but might be good for cross-window sync if project object is used elsewhere.
    });
  }

  Future<void> addTask(String title) async {
    final task = TaskNode(
      title: title,
      nodeType: NodeType.task,
      parentId: project.id,
    );
    await _nodeRepo.upsertNode(task);
  }

  Future<void> addPhase(String title) async {
    final phase = TaskNode(
      title: title,
      nodeType: NodeType.phase,
      parentId: project.id,
    );
    await _nodeRepo.upsertNode(phase);
  }

  Future<void> toggleTaskCompletion(TaskNode task, bool isCompleted) async {
    await _nodeRepo.toggleNodeCompletion(task.id, isCompleted);
  }

  Future<void> linkExistingProject(String childProjectId) async {
    final childProject = await _nodeRepo.getNodeById(childProjectId);
    if (childProject != null) {
      final updatedChild = childProject.copyWith(
        parentId: project.id,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _nodeRepo.upsertNode(updatedChild);
    }
  }

  Future<void> deleteProject() async {
    await _nodeRepo.deleteNode(project.id);
  }
}
