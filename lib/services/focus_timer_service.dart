import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:narwhal/data/repository/time_block_repository.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/services/notification_service.dart';

class FocusTimerService extends ChangeNotifier {
  TimeBlockRepository _timeBlockRepository;
  TaskNodeRepository _taskNodeRepository;

  Timer? _timer;
  String? _activeId;
  String _activeTitle = "";
  String? _activeColorHex;
  TaskNode? _activeTask;
  bool _isRunning = false;

  int _elapsedSecondsInCurrentBlock = 0; // 0..359 seconds
  int _sessionBlocksEarned = 0;
  int _totalSessionSeconds = 0;
  int _lastTickTimestampMs = 0;

  static const int blockDurationSeconds = 360; // 6 minutes = 1 block (10 blocks = 1 hour)

  // Getters
  String? get activeId => _activeId;
  String get activeTitle => _activeTitle;
  String? get activeColorHex => _activeColorHex;
  TaskNode? get activeTask => _activeTask;
  bool get isRunning => _isRunning;
  bool get hasActiveSession => _activeId != null && _activeId!.isNotEmpty;

  int get elapsedSecondsInCurrentBlock => _elapsedSecondsInCurrentBlock;
  double get currentBlockProgress =>
      (elapsedSecondsInCurrentBlock / blockDurationSeconds).clamp(0.0, 1.0);
  int get remainingBlockSeconds =>
      (blockDurationSeconds - _elapsedSecondsInCurrentBlock).clamp(0, blockDurationSeconds);
  int get sessionBlocksEarned => _sessionBlocksEarned;
  int get totalSessionSeconds => _totalSessionSeconds;

  String get currentBlockTimeString {
    final m = (_elapsedSecondsInCurrentBlock ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSecondsInCurrentBlock % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  String get remainingBlockTimeString {
    final rem = remainingBlockSeconds;
    final m = (rem ~/ 60).toString().padLeft(2, '0');
    final s = (rem % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  String get totalSessionTimeString {
    final m = (_totalSessionSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_totalSessionSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  FocusTimerService(this._timeBlockRepository, this._taskNodeRepository) {
    initFromPrefs();
  }

  void updateRepositories(TimeBlockRepository tbRepo, TaskNodeRepository taskRepo) {
    _timeBlockRepository = tbRepo;
    _taskNodeRepository = taskRepo;
  }

  Future<void> initFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('focus_active_id');
      if (savedId != null && savedId.isNotEmpty) {
        _activeId = savedId;
        _activeTitle = prefs.getString('focus_active_title') ?? "Focus Session";
        _activeColorHex = prefs.getString('focus_active_color');
        _isRunning = prefs.getBool('focus_is_running') ?? false;
        _elapsedSecondsInCurrentBlock = prefs.getInt('focus_elapsed_in_block') ?? 0;
        _sessionBlocksEarned = prefs.getInt('focus_session_blocks') ?? 0;
        _totalSessionSeconds = prefs.getInt('focus_total_seconds') ?? 0;
        final lastTickMs = prefs.getInt('focus_last_tick_ms') ?? 0;

        try {
          _activeTask = await _taskNodeRepository.getNodeById(savedId);
        } catch (_) {}

        if (_isRunning && lastTickMs > 0) {
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final elapsedSinceLastTick = (nowMs - lastTickMs) ~/ 1000;
          if (elapsedSinceLastTick > 0) {
            final totalUncredited = _elapsedSecondsInCurrentBlock + elapsedSinceLastTick;
            final blocksToFill = totalUncredited ~/ blockDurationSeconds;
            final remainingSec = totalUncredited % blockDurationSeconds;

            if (blocksToFill > 0) {
              for (int i = 0; i < blocksToFill; i++) {
                await _commitEarnedBlock(notifyUser: false);
              }
              NotificationService().showTimeBlockNotification(blocksToFill * 6);
            }
            _elapsedSecondsInCurrentBlock = remainingSec;
            _totalSessionSeconds += elapsedSinceLastTick;
          }
          _startTicking();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error initializing FocusTimerService prefs: $e");
    }
  }

  Future<void> startSession({
    required String id,
    required String title,
    TaskNode? task,
    String? colorHex,
  }) async {
    // If already active with same id, just resume if paused
    if (_activeId == id) {
      if (!_isRunning) resumeSession();
      return;
    }

    // Stop current session if running
    if (hasActiveSession) {
      await stopSession();
    }

    _activeId = id;
    _activeTitle = title;
    _activeTask = task;
    _activeColorHex = colorHex ?? task?.colorHex;
    _isRunning = true;
    _elapsedSecondsInCurrentBlock = 0;
    _sessionBlocksEarned = 0;
    _totalSessionSeconds = 0;
    _lastTickTimestampMs = DateTime.now().millisecondsSinceEpoch;

    await _saveToPrefs();
    _startTicking();
    notifyListeners();
  }

  void pauseSession() {
    if (!_isRunning) return;
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _lastTickTimestampMs = DateTime.now().millisecondsSinceEpoch;
    _saveToPrefs();
    notifyListeners();
  }

  void resumeSession() {
    if (_isRunning || !hasActiveSession) return;
    _isRunning = true;
    _lastTickTimestampMs = DateTime.now().millisecondsSinceEpoch;
    _saveToPrefs();
    _startTicking();
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isRunning) {
      pauseSession();
    } else {
      resumeSession();
    }
  }

  Future<void> stopSession() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _activeId = null;
    _activeTitle = "";
    _activeColorHex = null;
    _activeTask = null;
    _elapsedSecondsInCurrentBlock = 0;
    _sessionBlocksEarned = 0;
    _totalSessionSeconds = 0;
    _lastTickTimestampMs = 0;

    await _clearPrefs();
    notifyListeners();
  }

  Future<void> finishTask() async {
    final taskToFinish = _activeTask;
    await stopSession();

    if (taskToFinish != null) {
      final updated = taskToFinish.copyWith(
        isCompleted: true,
        completedDate: DateTime.now(),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _taskNodeRepository.upsertNode(updated);
    }
  }

  Future<void> addManualBlockFor({required String id, TaskNode? task}) async {
    final targetId = id.isNotEmpty ? id : "generic";
    await _timeBlockRepository.markNextAvailableBlockForToday(projectId: targetId);

    if (task != null) {
      final updated = task.copyWith(
        totalBlocksSpent: task.totalBlocksSpent + 1,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _taskNodeRepository.upsertNode(updated);
      if (_activeId == task.id) {
        _activeTask = updated;
      }
    }

    if (_activeId == targetId) {
      _sessionBlocksEarned++;
      _totalSessionSeconds += blockDurationSeconds;
      _saveToPrefs();
    }
    notifyListeners();
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void _tick() {
    if (!_isRunning) return;

    _elapsedSecondsInCurrentBlock++;
    _totalSessionSeconds++;
    _lastTickTimestampMs = DateTime.now().millisecondsSinceEpoch;

    if (_elapsedSecondsInCurrentBlock >= blockDurationSeconds) {
      _elapsedSecondsInCurrentBlock = 0;
      _sessionBlocksEarned++;
      _commitEarnedBlock(notifyUser: true);
    }

    if (_totalSessionSeconds % 5 == 0) {
      _saveToPrefs();
    }

    notifyListeners();
  }

  Future<void> _commitEarnedBlock({bool notifyUser = true}) async {
    final targetId = _activeId ?? "generic";
    await _timeBlockRepository.markNextAvailableBlockForToday(projectId: targetId);

    if (_activeTask != null) {
      final updated = _activeTask!.copyWith(
        totalBlocksSpent: _activeTask!.totalBlocksSpent + 1,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _activeTask = updated;
      await _taskNodeRepository.upsertNode(updated);
    }

    if (notifyUser) {
      NotificationService().showTimeBlockNotification(_sessionBlocksEarned * 6);
    }

    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeId != null) {
        await prefs.setString('focus_active_id', _activeId!);
        await prefs.setString('focus_active_title', _activeTitle);
        if (_activeColorHex != null) {
          await prefs.setString('focus_active_color', _activeColorHex!);
        } else {
          await prefs.remove('focus_active_color');
        }
        await prefs.setBool('focus_is_running', _isRunning);
        await prefs.setInt('focus_elapsed_in_block', _elapsedSecondsInCurrentBlock);
        await prefs.setInt('focus_session_blocks', _sessionBlocksEarned);
        await prefs.setInt('focus_total_seconds', _totalSessionSeconds);
        await prefs.setInt('focus_last_tick_ms', _lastTickTimestampMs);
      }
    } catch (_) {}
  }

  Future<void> _clearPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('focus_active_id');
      await prefs.remove('focus_active_title');
      await prefs.remove('focus_active_color');
      await prefs.remove('focus_is_running');
      await prefs.remove('focus_elapsed_in_block');
      await prefs.remove('focus_session_blocks');
      await prefs.remove('focus_total_seconds');
      await prefs.remove('focus_last_tick_ms');
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
