import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:flutter_core_entities/scratchpad_note.dart';

void main() {
  group('TaskNode.copyWith Null Clearing Tests', () {
    test('Clears scheduledDate when passed null', () {
      final task = TaskNode(
        id: 'task-1',
        title: 'Important Meeting',
        nodeType: NodeType.task,
        scheduledDate: DateTime(2026, 10, 17),
      );
      expect(task.scheduledDate, isNotNull);

      final cleared = task.copyWith(scheduledDate: null);
      expect(cleared.scheduledDate, isNull);
      expect(cleared.title, equals('Important Meeting'));
    });

    test('Clears scheduledDate using explicit clearScheduledDate flag', () {
      final task = TaskNode(
        id: 'task-1',
        title: 'Meeting',
        nodeType: NodeType.task,
        scheduledDate: DateTime(2026, 10, 17),
      );

      final cleared = task.copyWith(clearScheduledDate: true);
      expect(cleared.scheduledDate, isNull);
    });

    test('Clears parentId, deadline, and completedDate using null or clear flags', () {
      final task = TaskNode(
        id: 'task-2',
        title: 'Subtask item',
        nodeType: NodeType.task,
        parentId: 'parent-project-1',
        deadline: DateTime(2026, 10, 20),
        completedDate: DateTime(2026, 10, 16),
      );

      final clearedByNull = task.copyWith(
        parentId: null,
        deadline: null,
        completedDate: null,
      );
      expect(clearedByNull.parentId, isNull);
      expect(clearedByNull.deadline, isNull);
      expect(clearedByNull.completedDate, isNull);

      final clearedByFlag = task.copyWith(
        clearParentId: true,
        clearDeadline: true,
        clearCompletedDate: true,
      );
      expect(clearedByFlag.parentId, isNull);
      expect(clearedByFlag.deadline, isNull);
      expect(clearedByFlag.completedDate, isNull);
    });

    test('Preserves existing non-null fields when not specified in copyWith', () {
      final task = TaskNode(
        id: 'task-3',
        title: 'Original Title',
        nodeType: NodeType.task,
        parentId: 'proj-123',
        scheduledDate: DateTime(2026, 10, 17),
        durationMinutes: 45,
      );

      final modified = task.copyWith(title: 'Updated Title');
      expect(modified.title, equals('Updated Title'));
      expect(modified.parentId, equals('proj-123'));
      expect(modified.scheduledDate, equals(DateTime(2026, 10, 17)));
      expect(modified.durationMinutes, equals(45));
    });
  });

  group('ScratchpadNote.copyWith Null Clearing Tests', () {
    test('Clears projectId when passed null or clearProjectId flag', () {
      final nowEpoch = DateTime.now().millisecondsSinceEpoch;
      final note = ScratchpadNote(
        id: 'note-1',
        title: 'Project Scratchpad',
        content: 'Some notes',
        projectId: 'project-999',
        createdAt: nowEpoch,
        updatedAt: nowEpoch,
      );
      expect(note.projectId, equals('project-999'));

      final clearedByNull = note.copyWith(projectId: null);
      expect(clearedByNull.projectId, isNull);
      expect(clearedByNull.title, equals('Project Scratchpad'));

      final clearedByFlag = note.copyWith(clearProjectId: true);
      expect(clearedByFlag.projectId, isNull);
    });

    test('Preserves projectId when not specified in copyWith', () {
      final nowEpoch = DateTime.now().millisecondsSinceEpoch;
      final note = ScratchpadNote(
        id: 'note-2',
        title: 'Note Title',
        content: 'Note Content',
        projectId: 'project-abc',
        createdAt: nowEpoch,
        updatedAt: nowEpoch,
      );

      final updated = note.copyWith(content: 'New content');
      expect(updated.content, equals('New content'));
      expect(updated.projectId, equals('project-abc'));
    });
  });

  group('Subtask Hierarchy & Filtering Logic Tests', () {
    test('Correctly distinguishes project tasks from nested subtasks', () {
      final project = TaskNode(
        id: 'proj-1',
        title: 'Mobile App Launch',
        nodeType: NodeType.project,
      );

      final projectTask = TaskNode(
        id: 'task-100',
        title: 'Implement Dark Mode',
        nodeType: NodeType.task,
        parentId: project.id, // Direct child of project
        scheduledDate: DateTime(2026, 10, 17),
        durationMinutes: 60,
      );

      final subtask = TaskNode(
        id: 'task-101',
        title: 'Extract Theme Colors',
        nodeType: NodeType.task,
        parentId: projectTask.id, // Child of another task
        durationMinutes: 20,
      );

      final standaloneTask = TaskNode(
        id: 'task-200',
        title: 'Buy Groceries',
        nodeType: NodeType.task,
        parentId: null,
        scheduledDate: DateTime(2026, 10, 17),
        durationMinutes: 30,
      );

      final allTasks = [projectTask, subtask, standaloneTask];
      final taskIds = allTasks.map((t) => t.id).toSet();

      // Definition used in HomeViewModel and CalendarViewModel:
      // A node is a subtask if its parentId is the ID of another task.
      bool isSubtask(TaskNode t) => t.parentId != null && taskIds.contains(t.parentId);

      expect(isSubtask(standaloneTask), isFalse, reason: 'Standalone tasks are not subtasks');
      expect(isSubtask(projectTask), isFalse, reason: 'Tasks under a project are top-level tasks, not subtasks');
      expect(isSubtask(subtask), isTrue, reason: 'Tasks under another task are subtasks');

      // Top-level workload tasks should include projectTask and standaloneTask, but NOT subtask (to avoid double-counting)
      final topLevelTasks = allTasks.where((t) => !isSubtask(t)).toList();
      expect(topLevelTasks, contains(projectTask));
      expect(topLevelTasks, contains(standaloneTask));
      expect(topLevelTasks, isNot(contains(subtask)));

      final totalMinutes = topLevelTasks.fold<int>(0, (sum, t) => sum + t.durationMinutes);
      expect(totalMinutes, equals(90));
    });
  });
}
