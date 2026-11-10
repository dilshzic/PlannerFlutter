import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firedart/firedart.dart' as fd;
import 'package:flutter_core_auth_hybrid/auth_repository.dart';
import 'package:flutter_core_entities/scratchpad_note.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'dart:io';

class FirestoreService {
  final AuthRepository _authRepository;
  
  FirestoreService(this._authRepository);

  dynamic get _db {
    if (!kIsWeb && Platform.isLinux) {
      return fd.Firestore.instance;
    }
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint("Firestore access error: $e");
    }
    return null;
  }

  String? get _uid {
    final user = _authRepository.currentUser;
    return user?.id;
  }



  Future<void> saveTaskNode(TaskNode node) async {
    try {
      final uid = _uid;
      final db = _db;
      if (uid == null || db == null) {
        print("FirestoreService: Cannot save task node, UID or DB is null (UID: $uid)");
        return;
      }

      print("FirestoreService: Saving task node ${node.id} for user $uid");

      if (!kIsWeb && Platform.isLinux) {
        await (db as fd.Firestore)
            .collection("users")
            .document(uid)
            .collection("task_nodes")
            .document(node.id)
            .set(node.toMap());
        print("FirestoreService: TaskNode ${node.id} saved successfully on Linux");
      } else {
        await (db as FirebaseFirestore)
            .collection("users")
            .doc(uid)
            .collection("task_nodes")
            .doc(node.id)
            .set(node.toMap(), SetOptions(merge: true));
        print("FirestoreService: TaskNode ${node.id} saved successfully on Mobile/Web");
      }
    } catch (e) {
      print("Firestore TaskNode Save Error: $e");
      rethrow;
    }
  }

  Future<void> deleteTaskNode(String nodeId) async {
    try {
      final uid = _uid;
      final db = _db;
      if (uid == null || db == null) return;
      if (!kIsWeb && Platform.isLinux) {
        await (db as fd.Firestore)
            .collection("users")
            .document(uid)
            .collection("task_nodes")
            .document(nodeId)
            .delete();
      } else {
        await (db as FirebaseFirestore)
            .collection("users")
            .doc(uid)
            .collection("task_nodes")
            .doc(nodeId)
            .delete();
      }
    } catch (e) {
      print("Firestore TaskNode Delete Error: $e");
    }
  }



  Future<void> saveTimeLog(Map<String, dynamic> log) async {
    try {
      final uid = _uid;
      final db = _db;
      if (uid == null || db == null) return;
      final id = log['id'] as String;

      if (!kIsWeb && Platform.isLinux) {
        await (db as fd.Firestore).collection("users").document(uid).collection("time_logs").document(id).set(log);
      } else {
        await (db as FirebaseFirestore).collection("users").doc(uid).collection("time_logs").doc(id).set(log);
      }
    } catch (e) {
      print("Firestore TimeLog Save Error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getTimeLogsForDate(String date) async {
    try {
      final uid = _uid;
      final db = _db;
      if (uid == null || db == null) return [];

      if (!kIsWeb && Platform.isLinux) {
        final docs = await (db as fd.Firestore)
            .collection("users")
            .document(uid)
            .collection("time_logs")
            .where("dateLogged", isEqualTo: date)
            .get();
        return docs.map((d) => d.map).toList();
      } else {
        final snapshot = await (db as FirebaseFirestore)
            .collection("users")
            .doc(uid)
            .collection("time_logs")
            .where("dateLogged", isEqualTo: date)
            .get();
        return snapshot.docs.map((d) => d.data()).toList();
      }
    } catch (e) {
      print("Firestore TimeLog Fetch Error: $e");
      return [];
    }
  }

  Future<void> saveTimeBlockRecord(String dateId, Map<String, dynamic> data) async {
    try {
      final uid = _uid;
      final db = _db;
      if (uid == null || db == null) return;
      if (!kIsWeb && Platform.isLinux) {
        await (db as fd.Firestore)
            .collection("users")
            .document(uid)
            .collection("time_blocks")
            .document(dateId)
            .set(data);
      } else {
        await (db as FirebaseFirestore)
            .collection("users")
            .doc(uid)
            .collection("time_blocks")
            .doc(dateId)
            .set(data, SetOptions(merge: true));
      }
    } catch (e) {
      print("Firestore TimeBlock Save Error: $e");
    }
  }

  Future<Map<String, dynamic>?> getTimeBlockRecord(String dateId) async {
    try {
      final uid = _uid;
      final db = _db;
      if (uid == null || db == null) return null;
      if (!kIsWeb && Platform.isLinux) {
        final doc = await (db as fd.Firestore)
            .collection("users")
            .document(uid)
            .collection("time_blocks")
            .document(dateId)
            .get();
        return doc.map;
      } else {
        final doc = await (db as FirebaseFirestore)
            .collection("users")
            .doc(uid)
            .collection("time_blocks")
            .doc(dateId)
            .get();
        return doc.data();
      }
    } catch (e) {
      // It will throw if document does not exist in firedart, so just return null
      return null;
    }
  }

  Future<void> saveScratchpadNote(ScratchpadNote note) async {
    try {
      final uid = _uid;
      final db = _db;
      if (uid == null || db == null) {
        print("FirestoreService: Cannot save scratchpad note, UID or DB is null (UID: $uid)");
        return;
      }

      print("FirestoreService: Saving scratchpad note ${note.id} for user $uid");

      if (!kIsWeb && Platform.isLinux) {
        await (db as fd.Firestore)
            .collection("users")
            .document(uid)
            .collection("scratchpad_notes")
            .document(note.id)
            .set(note.toMap());
      } else {
        await (db as FirebaseFirestore)
            .collection("users")
            .doc(uid)
            .collection("scratchpad_notes")
            .doc(note.id)
            .set(note.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      print("Firestore ScratchpadNote Save Error: $e");
      rethrow;
    }
  }

  Future<void> deleteScratchpadNote(String noteId) async {
    try {
      final uid = _uid;
      final db = _db;
      if (uid == null || db == null) return;
      if (!kIsWeb && Platform.isLinux) {
        await (db as fd.Firestore)
            .collection("users")
            .document(uid)
            .collection("scratchpad_notes")
            .document(noteId)
            .delete();
      } else {
        await (db as FirebaseFirestore)
            .collection("users")
            .doc(uid)
            .collection("scratchpad_notes")
            .doc(noteId)
            .delete();
      }
    } catch (e) {
      print("Firestore ScratchpadNote Delete Error: $e");
    }
  }

  /// Permanently deletes every document in all of the current user's
  /// collections. Throws on failure so callers can report it.
  Future<void> deleteAllUserData() async {
    final uid = _uid;
    final db = _db;
    if (uid == null || db == null) return;

    const collections = [
      "task_nodes",
      "scratchpad_notes",
      "time_logs",
      "time_blocks",
    ];

    for (final name in collections) {
      if (!kIsWeb && Platform.isLinux) {
        final col = (db as fd.Firestore).collection("users").document(uid).collection(name);
        final docs = await col.get();
        for (final d in docs) {
          await d.reference.delete();
        }
      } else {
        final col = (db as FirebaseFirestore).collection("users").doc(uid).collection(name);
        final snap = await col.get();
        for (final d in snap.docs) {
          await d.reference.delete();
        }
      }
    }
  }
}
