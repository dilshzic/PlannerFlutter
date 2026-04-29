import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:planner/data/entity/task.dart';

class FirestoreService {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint("Firestore access error: $e");
    }
    return null;
  }

  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (e) {
      debugPrint("Auth access error: $e");
    }
    return null;
  }

  CollectionReference? get _taskCollection {
    final auth = _auth;
    final db = _db;
    final uid = auth?.currentUser?.uid;
    if (uid == null || db == null) return null;
    return db.collection("users").doc(uid).collection("tasks");
  }

  Future<void> saveTask(Task task) async {
    try {
      final collection = _taskCollection;
      if (collection == null) return;
      await collection.doc(task.id).set(task.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("Firestore Save Error: $e");
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final collection = _taskCollection;
      if (collection == null) return;
      await collection.doc(taskId).delete();
    } catch (e) {
      debugPrint("Firestore Delete Error: $e");
    }
  }
}
