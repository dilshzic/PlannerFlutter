import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_entities/time_block_record.dart';
import 'package:flutter_core_firestore_bridge/firestore_service.dart';
import 'package:flutter_core_auth_hybrid/auth_repository.dart';
import 'package:intl/intl.dart';

class TimeBlockRepository extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthRepository _authRepository;
  TimeBlockRecord? _currentRecord;
  String _currentDateId = "";
  String? _lastUid;
  StreamSubscription? _authSubscription;
  final Map<String, TimeBlockRecord> _recordsCache = {};
  
  TimeBlockRecord? get currentRecord => _currentRecord;
  String get currentDateId => _currentDateId;
  DateTime get currentDate => DateTime.tryParse(_currentDateId) ?? DateTime.now();
  bool get isViewingToday => _currentDateId == DateFormat('yyyy-MM-dd').format(DateTime.now());

  int get totalFilledBlocks => _currentRecord?.blocks.where((b) => b.isNotEmpty).length ?? 0;
  int get totalFocusedMinutes => totalFilledBlocks * 6;
  int get remainingBlocks => (120 - totalFilledBlocks).clamp(0, 120);

  int get firstEmptyBlockIndex {
    if (_currentRecord == null) return -1;
    for (int i = 0; i < _currentRecord!.blocks.length; i++) {
      if (_currentRecord!.blocks[i].isEmpty) return i;
    }
    return -1;
  }

  TimeBlockRepository(this._firestoreService, this._authRepository) {
    _lastUid = _authRepository.currentUser?.id;
    _initForToday();
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      final newUid = user?.id;
      if (newUid == _lastUid) return;
      _lastUid = newUid;

      _recordsCache.clear();
      if (user != null) {
        _loadRecord(_currentDateId);
      } else {
        _currentRecord = TimeBlockRecord(
          date: _currentDateId,
          blocks: List.generate(120, (_) => ""),
        );
        _recordsCache[_currentDateId] = _currentRecord!;
        notifyListeners();
      }
    });
  }

  void _initForToday() {
    _currentDateId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_authRepository.currentUser != null) {
      _loadRecord(_currentDateId);
    } else {
      _currentRecord = TimeBlockRecord(
        date: _currentDateId,
        blocks: List.generate(120, (_) => ""),
      );
      _recordsCache[_currentDateId] = _currentRecord!;
    }
  }

  Future<void> _loadRecord(String dateId) async {
    if (_recordsCache.containsKey(dateId)) {
      _currentRecord = _recordsCache[dateId];
      notifyListeners();
      return;
    }

    final data = await _firestoreService.getTimeBlockRecord(dateId);
    if (data != null) {
      _currentRecord = TimeBlockRecord.fromMap(data, dateId);
    } else {
      _currentRecord = TimeBlockRecord(
        date: dateId,
        blocks: List.generate(120, (_) => ""),
      );
    }
    _recordsCache[dateId] = _currentRecord!;
    notifyListeners();
  }

  Future<void> toggleBlock(int index, {String? projectId}) async {
    if (_currentRecord == null) return;
    if (index < 0 || index >= 120) return;

    final blocks = List<String>.from(_currentRecord!.blocks);
    
    if (blocks[index].isNotEmpty) {
      blocks[index] = "";
    } else {
      blocks[index] = projectId ?? "generic";
    }
    
    _currentRecord = TimeBlockRecord(
      date: _currentRecord!.date,
      blocks: blocks,
    );
    _recordsCache[_currentRecord!.date] = _currentRecord!;
    notifyListeners();

    await _firestoreService.saveTimeBlockRecord(_currentRecord!.date, _currentRecord!.toMap()).catchError((e) {
      debugPrint("Error saving time block record: $e");
    });
  }

  Future<int> markNextAvailableBlockForToday({String? projectId}) async {
    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    TimeBlockRecord? record = (_currentDateId == todayId && _currentRecord != null)
        ? _currentRecord
        : _recordsCache[todayId];

    if (record == null) {
      final data = await _firestoreService.getTimeBlockRecord(todayId);
      if (data != null) {
        record = TimeBlockRecord.fromMap(data, todayId);
      } else {
        record = TimeBlockRecord(
          date: todayId,
          blocks: List.generate(120, (_) => ""),
        );
      }
      _recordsCache[todayId] = record;
    }

    final blocks = List<String>.from(record.blocks);
    int emptyIndex = -1;
    for (int i = 0; i < blocks.length; i++) {
      if (blocks[i].isEmpty) {
        emptyIndex = i;
        break;
      }
    }

    if (emptyIndex != -1) {
      blocks[emptyIndex] = projectId ?? "generic";
      final updatedRecord = TimeBlockRecord(date: todayId, blocks: blocks);
      _recordsCache[todayId] = updatedRecord;

      if (_currentDateId == todayId) {
        _currentRecord = updatedRecord;
        notifyListeners();
      }

      await _firestoreService.saveTimeBlockRecord(todayId, updatedRecord.toMap()).catchError((e) {
        debugPrint("Error saving time block record: $e");
      });
    }

    return emptyIndex;
  }

  Future<void> loadDate(DateTime date) async {
    _currentDateId = DateFormat('yyyy-MM-dd').format(date);
    await _loadRecord(_currentDateId);
  }

  Future<void> previousDay() async {
    final prev = currentDate.subtract(const Duration(days: 1));
    await loadDate(prev);
  }

  Future<void> nextDay() async {
    final next = currentDate.add(const Duration(days: 1));
    await loadDate(next);
  }

  Future<void> goToToday() async {
    await loadDate(DateTime.now());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
