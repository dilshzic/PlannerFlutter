import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/time_block_repository.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/services/focus_timer_service.dart';
import 'package:narwhal/ui/time_blocks/time_blocks_view_model.dart';
import 'package:flutter_core_firestore_bridge/firestore_service.dart';
import 'package:flutter_core_auth_hybrid/auth_repository.dart';

class FakeFirestoreService extends FirestoreService {
  FakeFirestoreService(super.authRepo);

  final Map<String, Map<String, dynamic>> records = {};

  @override
  Future<void> saveTimeBlockRecord(String dateId, Map<String, dynamic> data) async {
    records[dateId] = data;
  }

  @override
  Future<Map<String, dynamic>?> getTimeBlockRecord(String dateId) async {
    return records[dateId];
  }
}

class FakeTaskNodeRepository extends TaskNodeRepository {
  FakeTaskNodeRepository(super.firestore, super.authRepo);

  final Map<String, TaskNode> _nodes = {};

  @override
  Future<TaskNode?> getNodeById(String id) async {
    return _nodes[id];
  }

  @override
  Future<int> upsertNode(TaskNode node) async {
    _nodes[node.id] = node;
    return 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirestoreService fakeFirestore;
  late AuthRepository fakeAuth;
  late TimeBlockRepository timeBlockRepo;
  late FakeTaskNodeRepository fakeTaskRepo;
  late FocusTimerService focusTimer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeAuth = AuthRepository(apiKey: 'test-api-key');
    fakeFirestore = FakeFirestoreService(fakeAuth);
    timeBlockRepo = TimeBlockRepository(fakeFirestore, fakeAuth);
    fakeTaskRepo = FakeTaskNodeRepository(fakeFirestore, fakeAuth);
    focusTimer = FocusTimerService(timeBlockRepo, fakeTaskRepo);
  });

  group('TimeBlockRepository Tests', () {
    test('Initializes with 120 empty blocks for today', () {
      expect(timeBlockRepo.currentRecord, isNotNull);
      expect(timeBlockRepo.currentRecord!.blocks.length, equals(120));
      expect(timeBlockRepo.totalFilledBlocks, equals(0));
      expect(timeBlockRepo.remainingBlocks, equals(120));
      expect(timeBlockRepo.firstEmptyBlockIndex, equals(0));
      expect(timeBlockRepo.isViewingToday, isTrue);
    });

    test('toggleBlock marks and unmarks slots', () async {
      await timeBlockRepo.toggleBlock(0, projectId: 'proj-1');
      expect(timeBlockRepo.currentRecord!.blocks[0], equals('proj-1'));
      expect(timeBlockRepo.totalFilledBlocks, equals(1));
      expect(timeBlockRepo.totalFocusedMinutes, equals(6));
      expect(timeBlockRepo.firstEmptyBlockIndex, equals(1));

      // Toggle again should clear
      await timeBlockRepo.toggleBlock(0);
      expect(timeBlockRepo.currentRecord!.blocks[0], equals(''));
      expect(timeBlockRepo.totalFilledBlocks, equals(0));
      expect(timeBlockRepo.firstEmptyBlockIndex, equals(0));
    });

    test('markNextAvailableBlockForToday fills sequentially', () async {
      final firstIdx = await timeBlockRepo.markNextAvailableBlockForToday(projectId: 'task-100');
      expect(firstIdx, equals(0));
      expect(timeBlockRepo.currentRecord!.blocks[0], equals('task-100'));

      final secondIdx = await timeBlockRepo.markNextAvailableBlockForToday(projectId: 'task-200');
      expect(secondIdx, equals(1));
      expect(timeBlockRepo.currentRecord!.blocks[1], equals('task-200'));
      expect(timeBlockRepo.totalFilledBlocks, equals(2));
      expect(timeBlockRepo.remainingBlocks, equals(118));
      expect(timeBlockRepo.totalFocusedMinutes, equals(12));
    });

    test('Date navigation updates current date', () async {
      final initialDate = timeBlockRepo.currentDate;
      await timeBlockRepo.previousDay();
      expect(timeBlockRepo.currentDate.day, equals(initialDate.subtract(const Duration(days: 1)).day));
      expect(timeBlockRepo.isViewingToday, isFalse);

      await timeBlockRepo.nextDay();
      expect(timeBlockRepo.currentDate.day, equals(initialDate.day));
      expect(timeBlockRepo.isViewingToday, isTrue);
    });
  });

  group('FocusTimerService Integration Tests', () {
    test('Starts, pauses, resumes, and stops a session for a task', () async {
      final task = TaskNode(
        id: 'task-abc',
        title: 'Design Time Blocks UI',
        nodeType: NodeType.task,
        durationMinutes: 30,
        colorHex: '#4CAF50',
      );
      await fakeTaskRepo.upsertNode(task);

      expect(focusTimer.hasActiveSession, isFalse);
      expect(focusTimer.isRunning, isFalse);

      // Start session
      await focusTimer.startSession(
        id: task.id,
        title: task.title,
        task: task,
        colorHex: task.colorHex,
      );

      expect(focusTimer.hasActiveSession, isTrue);
      expect(focusTimer.isRunning, isTrue);
      expect(focusTimer.activeId, equals('task-abc'));
      expect(focusTimer.activeTitle, equals('Design Time Blocks UI'));
      expect(focusTimer.activeColorHex, equals('#4CAF50'));
      expect(focusTimer.activeTask?.id, equals('task-abc'));

      // Pause
      focusTimer.pauseSession();
      expect(focusTimer.isRunning, isFalse);
      expect(focusTimer.hasActiveSession, isTrue);

      // Resume
      focusTimer.resumeSession();
      expect(focusTimer.isRunning, isTrue);

      // Stop
      await focusTimer.stopSession();
      expect(focusTimer.hasActiveSession, isFalse);
      expect(focusTimer.isRunning, isFalse);
      expect(focusTimer.activeId, isNull);
    });

    test('addManualBlockFor commits block to repository and updates task totalBlocksSpent', () async {
      final task = TaskNode(
        id: 'task-xyz',
        title: 'Write Documentation',
        nodeType: NodeType.task,
        totalBlocksSpent: 1,
      );
      await fakeTaskRepo.upsertNode(task);

      await focusTimer.startSession(
        id: task.id,
        title: task.title,
        task: task,
      );

      await focusTimer.addManualBlockFor(id: task.id, task: task);

      // Verify TimeBlockRepository got a block
      expect(timeBlockRepo.totalFilledBlocks, equals(1));
      expect(timeBlockRepo.currentRecord!.blocks[0], equals('task-xyz'));

      // Verify TaskNode totalBlocksSpent was incremented
      final updatedTask = await fakeTaskRepo.getNodeById('task-xyz');
      expect(updatedTask, isNotNull);
      expect(updatedTask!.totalBlocksSpent, equals(2));
      expect(focusTimer.sessionBlocksEarned, equals(1));
    });

    test('finishTask completes the task and clears focus session', () async {
      final task = TaskNode(
        id: 'task-fin',
        title: 'Complete Feature',
        nodeType: NodeType.task,
        isCompleted: false,
      );
      await fakeTaskRepo.upsertNode(task);

      await focusTimer.startSession(
        id: task.id,
        title: task.title,
        task: task,
      );

      await focusTimer.finishTask();

      expect(focusTimer.hasActiveSession, isFalse);
      final finishedTask = await fakeTaskRepo.getNodeById('task-fin');
      expect(finishedTask, isNotNull);
      expect(finishedTask!.isCompleted, isTrue);
      expect(finishedTask.completedDate, isNotNull);
    });
  });

  group('TimeBlocksViewModel Integration Tests', () {
    test('Coordinates with FocusTimerService and TimeBlockRepository', () async {
      final viewModel = TimeBlocksViewModel(timeBlockRepo, focusTimer);

      expect(viewModel.isToday, isTrue);
      expect(viewModel.totalFilledBlocks, equals(0));
      expect(viewModel.remainingBlocks, equals(120));
      expect(viewModel.completionPercentage, equals(0.0));
      // Without active session, activeBlockIndex is -1
      expect(viewModel.activeBlockIndex, equals(-1));

      // Start focus session
      final task = TaskNode(
        id: 'task-focus-1',
        title: 'Deep Work Session',
        nodeType: NodeType.task,
      );
      await viewModel.startSessionForNode(task);

      expect(focusTimer.hasActiveSession, isTrue);
      // With active session on today, activeBlockIndex points to first empty block (index 0)
      expect(viewModel.activeBlockIndex, equals(0));

      // Manually add block
      await viewModel.addManualBlock();
      expect(viewModel.totalFilledBlocks, equals(1));
      expect(viewModel.totalFocusedMinutes, equals(6));
      expect(viewModel.remainingBlocks, equals(119));
      expect(viewModel.completionPercentage, closeTo(1 / 120.0, 0.001));

      // Now next accumulating block is index 1
      expect(viewModel.activeBlockIndex, equals(1));

      // Stop session
      await viewModel.stopFocusSession();
      expect(viewModel.activeBlockIndex, equals(-1));

      viewModel.dispose();
    });
  });
}
