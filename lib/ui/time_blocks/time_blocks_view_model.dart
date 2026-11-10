import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/time_block_repository.dart';
import 'package:narwhal/services/focus_timer_service.dart';

class TimeBlocksViewModel extends ChangeNotifier {
  final TimeBlockRepository _repository;
  final FocusTimerService _focusTimer;

  DateTime _selectedDate = DateTime.now();
  bool _showTasks = false;

  DateTime get selectedDate => _selectedDate;
  bool get showTasks => _showTasks;
  FocusTimerService get focusTimer => _focusTimer;

  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get formattedDate {
    if (isToday) {
      return "Today, ${DateFormat('MMM d').format(_selectedDate)}";
    }
    return DateFormat('EEE, MMM d, yyyy').format(_selectedDate);
  }

  List<String> get blocks => _repository.currentRecord?.blocks ?? List.generate(120, (_) => "");

  int get totalFilledBlocks => blocks.where((b) => b.isNotEmpty).length;
  int get totalFocusedMinutes => totalFilledBlocks * 6;
  int get remainingBlocks => (120 - totalFilledBlocks).clamp(0, 120);
  double get completionPercentage => (totalFilledBlocks / 120.0).clamp(0.0, 1.0);

  /// Index of the block currently being accumulated by the focus timer
  int get activeBlockIndex {
    if (!isToday || !_focusTimer.hasActiveSession) return -1;
    return _repository.firstEmptyBlockIndex;
  }

  TimeBlocksViewModel(this._repository, this._focusTimer) {
    _repository.addListener(notifyListeners);
    _focusTimer.addListener(notifyListeners);
    _selectedDate = _repository.currentDate;
  }

  void toggleShowTasks(bool val) {
    _showTasks = val;
    notifyListeners();
  }

  void toggleBlock(int index) {
    _repository.toggleBlock(index, projectId: _focusTimer.activeId);
  }

  Future<void> previousDay() async {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    await _repository.loadDate(_selectedDate);
    notifyListeners();
  }

  Future<void> nextDay() async {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    await _repository.loadDate(_selectedDate);
    notifyListeners();
  }

  Future<void> selectDate(DateTime date) async {
    _selectedDate = date;
    await _repository.loadDate(_selectedDate);
    notifyListeners();
  }

  Future<void> goToToday() async {
    _selectedDate = DateTime.now();
    await _repository.loadDate(_selectedDate);
    notifyListeners();
  }

  Future<void> startSessionForNode(TaskNode node) async {
    await _focusTimer.startSession(
      id: node.id,
      title: node.title,
      task: node.nodeType == NodeType.task ? node : null,
      colorHex: node.colorHex,
    );
  }

  Future<void> startGenericSession() async {
    await _focusTimer.startSession(
      id: "generic",
      title: "Focus Session",
    );
  }

  void toggleFocusPlayPause() {
    _focusTimer.togglePlayPause();
  }

  Future<void> stopFocusSession() async {
    await _focusTimer.stopSession();
  }

  Future<void> finishTask() async {
    await _focusTimer.finishTask();
  }

  Future<void> addManualBlock() async {
    await _focusTimer.addManualBlockFor(
      id: _focusTimer.activeId ?? "generic",
      task: _focusTimer.activeTask,
    );
  }

  @override
  void dispose() {
    _repository.removeListener(notifyListeners);
    _focusTimer.removeListener(notifyListeners);
    super.dispose();
  }
}
