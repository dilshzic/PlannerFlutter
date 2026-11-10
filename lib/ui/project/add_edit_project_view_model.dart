import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';

class AddEditProjectViewModel extends ChangeNotifier {
  final TaskNodeRepository _repository;
  final TaskNode? _existingProject;
  final String? parentId;

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  
  String? colorHex;
  bool isLoading = false;

  AddEditProjectViewModel(this._repository, this._existingProject, {this.parentId}) {
    titleController = TextEditingController(text: _existingProject?.title ?? "");
    descriptionController = TextEditingController(text: _existingProject?.description ?? "");
    colorHex = _existingProject?.colorHex;
    
    titleController.addListener(_onTitleChanged);
    descriptionController.addListener(_onDescriptionChanged);
  }

  String get title => titleController.text;
  String get description => descriptionController.text;

  void _onTitleChanged() {
    notifyListeners();
  }

  void _onDescriptionChanged() {
    notifyListeners();
  }

  void onColorChange(String? value) {
    colorHex = value;
    notifyListeners();
  }

  Future<void> saveProject() async {
    final project = (_existingProject ?? TaskNode(nodeType: NodeType.project, parentId: parentId)).copyWith(
      title: title,
      description: description,
      colorHex: colorHex,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    await _repository.upsertNode(project);
  }

  Future<void> deleteProject() async {
    if (_existingProject != null) {
      await _repository.deleteNode(_existingProject.id);
    }
  }

  @override
  void dispose() {
    titleController.removeListener(_onTitleChanged);
    descriptionController.removeListener(_onDescriptionChanged);
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
