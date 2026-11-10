import 'package:flutter/foundation.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:flutter_core_entities/app_user.dart';
import 'package:flutter_core_entities/time_log.dart';
import 'package:flutter_core_firestore_bridge/firestore_service.dart';
import 'package:flutter_core_auth_hybrid/auth_repository.dart';
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedart/firedart.dart' as fd;
import 'package:narwhal/services/home_widget_sync_service.dart';

class TaskNodeRepository extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthRepository _authRepository;
  
  List<TaskNode> _nodes = [];
  
  StreamSubscription? _nodesSubscription;
  
  final _nodesUpdateController = StreamController<void>.broadcast();
  Stream<void> get nodeUpdates => _nodesUpdateController.stream;

  TaskNodeRepository(this._firestoreService, this._authRepository) {
    _initFirestoreListener();
  }

  void _initFirestoreListener() {
    final existingUser = _authRepository.currentUser;
    if (existingUser != null) {
      _startFirestoreListener(existingUser.id);
    }

    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        // Always cancel and restart to pick up fresh data after cache clears
        // or any auth state change (e.g. token refresh, re-login).
        _nodesSubscription?.cancel();
        _nodesSubscription = null;
        _startFirestoreListener(user.id);
      } else {
        _nodesSubscription?.cancel();
        _nodesSubscription = null;
        _nodes = [];
        notifyListeners();
        _nodesUpdateController.add(null);
        HomeWidgetSyncService.instance.clearWidgetData();
      }
    });
  }

  void _syncHomeWidgets() {
    try {
      final projects = {for (var n in _nodes.where((n) => n.nodeType == NodeType.project)) n.id: n};
      HomeWidgetSyncService.instance.syncTodayTasks(
        tasks: _nodes,
        projectsMap: projects,
      );
    } catch (e) {
      debugPrint("Error syncing home widgets: $e");
    }
  }

  void _startFirestoreListener(String uid) {
    if (!kIsWeb && Platform.isLinux) {
      _listenToFiredart(uid);
    } else {
      try {
        _nodesSubscription = FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("task_nodes")
            .snapshots()
            .listen((snapshot) {
              _nodes = snapshot.docs.map((doc) => TaskNode.fromMap(doc.data())).toList();
              notifyListeners();
              _nodesUpdateController.add(null);
              _syncHomeWidgets();
            });
      } catch (e) {
        print("TaskNode Firestore Stream Setup Error: $e");
      }
    }
  }

  void _listenToFiredart(String uid) {
    _nodesSubscription?.cancel();
    
    if (!fd.FirebaseAuth.instance.isSignedIn) return;
    
    try {
      _nodesSubscription = fd.Firestore.instance
          .collection("users")
          .document(uid)
          .collection("task_nodes")
          .stream
          .listen((snapshots) {
            _nodes = snapshots.map((doc) => TaskNode.fromMap(doc.map)).toList();
            notifyListeners();
            _nodesUpdateController.add(null);
            _syncHomeWidgets();
          });
    } catch (e) {
      print("Linux TaskNode Firestore Stream Setup Error: $e");
    }
  }

  Future<List<TaskNode>> getAllNodes() async {
    return _nodes;
  }

  Future<List<TaskNode>> getNodesByType(NodeType type) async {
    return _nodes.where((n) => n.nodeType == type).toList();
  }

  Future<List<TaskNode>> getChildrenOf(String parentId) async {
    return _nodes.where((n) => n.parentId == parentId).toList();
  }

  Future<List<TaskNode>> getDescendantsOf(String parentId) async {
    final List<TaskNode> descendants = [];
    void findChildren(String currentId) {
      final children = _nodes.where((n) => n.parentId == currentId).toList();
      for (final child in children) {
        descendants.add(child);
        findChildren(child.id);
      }
    }
    findChildren(parentId);
    return descendants;
  }

  Future<TaskNode?> getNodeById(String id) async {
    try {
      return _nodes.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  AuthRepository get authRepository => _authRepository;
  AppUser? get currentUser => _authRepository.currentUser;

  Future<int> upsertNode(TaskNode node) async {
    final uid = _authRepository.currentUser?.id;
    if (uid == null) {
      print("Error: Attempted to upsert node without an authenticated user.");
      return 0;
    }

    final nodeWithUid = node.copyWith(userId: uid);
    final existingIndex = _nodes.indexWhere((n) => n.id == node.id);
    bool shouldCheckParent = false;
    
    if (existingIndex != -1) {
      if (_nodes[existingIndex].isCompleted != nodeWithUid.isCompleted) {
        shouldCheckParent = true;
      }
      _nodes[existingIndex] = nodeWithUid;
    } else {
      _nodes.add(nodeWithUid);
      shouldCheckParent = true;
    }
    
    notifyListeners();
    _nodesUpdateController.add(null);
    _syncHomeWidgets();
    
    _firestoreService.saveTaskNode(nodeWithUid).catchError((e) {
      print("Error saving node to Firestore: $e");
    });
    
    // Auto-complete logic
    if (shouldCheckParent && nodeWithUid.parentId != null) {
      _checkParentAutoCompletion(nodeWithUid.parentId!);
    }
    
    return 1;
  }

  Future<void> _checkParentAutoCompletion(String parentId) async {
    final parent = await getNodeById(parentId);
    if (parent == null || parent.nodeType != NodeType.task) return;

    final children = await getChildrenOf(parentId);
    if (children.isEmpty) return;

    final allCompleted = children.every((c) => c.isCompleted);

    if (allCompleted && !parent.isCompleted) {
      final updatedParent = parent.copyWith(
        isCompleted: true,
        completedDate: DateTime.now(),
      );
      await upsertNode(updatedParent);
    } else if (!allCompleted && parent.isCompleted) {
      final updatedParent = parent.copyWith(
        isCompleted: false,
        completedDate: null,
        clearCompletedDate: true,
      );
      await upsertNode(updatedParent);
    }
  }

  Future<int> deleteNode(String id) async {
    final node = await getNodeById(id);
    final parentId = node?.parentId;
    
    if (node?.nodeType == NodeType.task) {
      // Cascade delete all descendants (subtasks) of the task
      final descendants = await getDescendantsOf(id);
      for (var descendant in descendants) {
        _nodes.removeWhere((n) => n.id == descendant.id);
        _firestoreService.deleteTaskNode(descendant.id).catchError((e) {
          debugPrint("Error deleting descendant node from Firestore: $e");
        });
      }
    } else {
      // Detach all direct children (set parentId to null) so they aren't orphaned
      final children = await getChildrenOf(id);
      for (var child in children) {
        final updatedChild = child.copyWith(
          parentId: null,
          clearParentId: true,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await upsertNode(updatedChild);
      }
    }
    
    // Delete the node locally
    _nodes.removeWhere((n) => n.id == id);
    
    notifyListeners();
    _nodesUpdateController.add(null);
    _syncHomeWidgets();
    
    _firestoreService.deleteTaskNode(id).catchError((e) {
      debugPrint("Error deleting node from Firestore: $e");
    });
    
    if (parentId != null) {
      _checkParentAutoCompletion(parentId);
    }
    
    return 1;
  }

  Future<void> toggleNodeCompletion(String id, bool isCompleted) async {
    final node = await getNodeById(id);
    if (node != null) {
      final updatedNode = node.copyWith(
        isCompleted: isCompleted,
        completedDate: isCompleted ? DateTime.now() : null,
        clearCompletedDate: !isCompleted,
      );
      await upsertNode(updatedNode);
    }
  }

  Future<void> insertTimeLog(TimeLog log) async {
    _firestoreService.saveTimeLog(log.toMap()).catchError((e) {
      print("Error saving time log: $e");
    });
    _nodesUpdateController.add(null);
  }

  Future<List<TimeLog>> getTimeLogsForDate(String date) async {
    final maps = await _firestoreService.getTimeLogsForDate(date);
    return maps.map((m) => TimeLog.fromMap(m)).toList();
  }

  Future<void> saveTimeBlockRecord(String dateId, Map<String, dynamic> data) async {
    _firestoreService.saveTimeBlockRecord(dateId, data).catchError((e) {
      print("Error saving time block record: $e");
    });
  }

  Future<Map<String, dynamic>?> getTimeBlockRecord(String dateId) async {
    return await _firestoreService.getTimeBlockRecord(dateId);
  }

  @override
  void dispose() {
    _nodesSubscription?.cancel();
    _nodesUpdateController.close();
    super.dispose();
  }
}
