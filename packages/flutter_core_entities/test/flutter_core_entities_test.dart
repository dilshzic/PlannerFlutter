import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:flutter_core_entities/scratchpad_note.dart';
import 'package:flutter_core_entities/app_user.dart';
import 'package:flutter_core_entities/time_block_record.dart';

void main() {
  group('TaskNode Entity Tests', () {
    test('TaskNode serializes to and from Map correctly', () {
      final now = DateTime.now();
      final node = TaskNode(
        id: 'node-1',
        title: 'Complete Report',
        description: 'Monthly summary',
        nodeType: NodeType.task,
        scheduledDate: now,
        isCompleted: true,
        priority: 2,
        durationMinutes: 45,
      );

      final map = node.toMap();
      final restored = TaskNode.fromMap(map);

      expect(restored.id, equals('node-1'));
      expect(restored.title, equals('Complete Report'));
      expect(restored.description, equals('Monthly summary'));
      expect(restored.nodeType, equals(NodeType.task));
      expect(restored.isCompleted, isTrue);
      expect(restored.priority, equals(2));
      expect(restored.durationMinutes, equals(45));
    });

    test('TaskNode.copyWith properly clears nullable values with sentinel and flags', () {
      final node = TaskNode(
        id: 'node-2',
        title: 'Task with fields',
        parentId: 'parent-123',
        scheduledDate: DateTime(2026, 10, 18),
        completedDate: DateTime(2026, 10, 17),
        deadline: DateTime(2026, 10, 25),
      );

      final clearedByNull = node.copyWith(
        parentId: null,
        scheduledDate: null,
        completedDate: null,
        deadline: null,
      );

      expect(clearedByNull.parentId, isNull);
      expect(clearedByNull.scheduledDate, isNull);
      expect(clearedByNull.completedDate, isNull);
      expect(clearedByNull.deadline, isNull);

      final clearedByFlags = node.copyWith(
        clearParentId: true,
        clearScheduledDate: true,
        clearCompletedDate: true,
        clearDeadline: true,
      );

      expect(clearedByFlags.parentId, isNull);
      expect(clearedByFlags.scheduledDate, isNull);
      expect(clearedByFlags.completedDate, isNull);
      expect(clearedByFlags.deadline, isNull);
    });
  });

  group('ScratchpadNote Entity Tests', () {
    test('ScratchpadNote serializes and handles null projectId clearing', () {
      final note = ScratchpadNote(
        id: 'note-1',
        title: 'Architecture Ideas',
        content: 'Use clean architecture',
        projectId: 'proj-xyz',
        createdAt: 1000,
        updatedAt: 2000,
      );

      final map = note.toMap();
      final restored = ScratchpadNote.fromMap(map);
      expect(restored.id, equals('note-1'));
      expect(restored.projectId, equals('proj-xyz'));

      final cleared = note.copyWith(projectId: null);
      expect(cleared.projectId, isNull);
      expect(cleared.title, equals('Architecture Ideas'));
    });
  });

  group('AppUser & TimeBlockRecord Tests', () {
    test('AppUser equality and properties', () {
      final user = AppUser(
        id: 'user-1',
        email: 'test@example.com',
        displayName: 'Test User',
        isAnonymous: false,
      );

      expect(user.id, equals('user-1'));
      expect(user.email, equals('test@example.com'));
      expect(user.displayName, equals('Test User'));
      expect(user.isAnonymous, isFalse);
    });

    test('TimeBlockRecord serializes to and from Map with 120 blocks normalization', () {
      final blocks = List.generate(120, (i) => i % 2 == 0 ? "proj-1" : "");
      final record = TimeBlockRecord(
        date: '2026-10-17',
        blocks: blocks,
      );

      final map = record.toMap();
      final restored = TimeBlockRecord.fromMap(map, '2026-10-17');
      expect(restored.date, equals('2026-10-17'));
      expect(restored.blocks.length, equals(120));
      expect(restored.blocks[0], equals('proj-1'));
      expect(restored.blocks[1], equals(''));
    });
  });
}
