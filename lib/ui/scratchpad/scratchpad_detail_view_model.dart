import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_core_entities/scratchpad_note.dart';
import 'package:narwhal/data/repository/scratchpad_repository.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:flt_alx_core_ai/flt_alx_core_ai.dart';
import 'package:narwhal/services/ai/scratchpad_task_extractor.dart';
import 'package:narwhal/ui/scratchpad/components/task_extraction_bottom_sheet.dart';

class ScratchpadDetailViewModel extends ChangeNotifier {
  final ScratchpadRepository _repository;
  final TaskNodeRepository _nodeRepository;
  final ScratchpadNote? _existingNote;

  late TextEditingController titleController;
  late TextEditingController contentController;
  
  Timer? _debounce;
  ScratchpadNote? _currentNote;
  
  List<TaskNode> projects = [];
  String? selectedProjectId;
  bool isExtractingTasks = false;

  ScratchpadDetailViewModel(this._repository, this._nodeRepository, this._existingNote) {
    _currentNote = _existingNote;
    titleController = TextEditingController(text: _existingNote?.title ?? "");
    contentController = TextEditingController(text: _existingNote?.content ?? "");
    selectedProjectId = _existingNote?.projectId;
    
    titleController.addListener(_onTextChanged);
    contentController.addListener(_onTextChanged);
    
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    projects = await _nodeRepository.getNodesByType(NodeType.project);
    notifyListeners();
  }

  void setProject(String? projectId) {
    selectedProjectId = projectId;
    saveNote();
    notifyListeners();
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      saveNote();
    });
  }

  Future<void> saveNote() async {
    final note = (_currentNote ?? ScratchpadNote()).copyWith(
      title: titleController.text,
      content: contentController.text,
      projectId: selectedProjectId,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    _currentNote = note;
    await _repository.upsertNote(note);
  }

  Future<void> deleteNote() async {
    if (_currentNote != null) {
      await _repository.moveToTrash(_currentNote!.id);
    }
  }

  bool get isArchived => _currentNote?.isArchived ?? false;

  Future<void> toggleArchive() async {
    if (_currentNote != null) {
      final note = _currentNote!.copyWith(
        isArchived: !isArchived,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _currentNote = note;
      await _repository.upsertNote(note);
      notifyListeners();
    }
  }

  Future<void> extractTasksWithAi(
    BuildContext context,
    AiBrainManager brainManager,
  ) async {
    final content = contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some thoughts or tasks to the note first!')),
      );
      return;
    }

    isExtractingTasks = true;
    notifyListeners();

    try {
      final extractor = ScratchpadTaskExtractor(brainManager);
      final result = await extractor.extractTasks(
        title: titleController.text.trim(),
        content: content,
        linkedProjectId: selectedProjectId,
        activeProjects: projects,
      );

      isExtractingTasks = false;
      notifyListeners();

      if (result.tasks.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No actionable tasks detected in note.')),
          );
        }
        return;
      }

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (bottomSheetContext) => TaskExtractionBottomSheet(
            result: result,
            activeProjects: projects,
            onConfirm: (tasksToCreate) async {
              int createdCount = 0;
              for (final t in tasksToCreate) {
                final taskNode = TaskNode(
                  title: t.title,
                  description: t.description,
                  parentId: t.suggestedProjectId,
                  priority: t.priority,
                  durationMinutes: t.durationMinutes,
                  isZone: t.isZone,
                  scheduledDate: t.scheduledDate,
                  nodeType: NodeType.task,
                );
                await _nodeRepository.upsertNode(taskNode);
                createdCount++;
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✨ Created $createdCount task${createdCount != 1 ? 's' : ''} in Narwhal Planner!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
          ),
        );
      }
    } catch (e) {
      isExtractingTasks = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task Extraction Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    titleController.removeListener(_onTextChanged);
    contentController.removeListener(_onTextChanged);
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }
}
