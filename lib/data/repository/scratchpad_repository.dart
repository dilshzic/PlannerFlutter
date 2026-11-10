import 'package:flutter/foundation.dart';
import 'package:flutter_core_entities/scratchpad_note.dart';
import 'package:flutter_core_entities/app_user.dart';
import 'package:flutter_core_firestore_bridge/firestore_service.dart';
import 'package:flutter_core_auth_hybrid/auth_repository.dart';
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firedart/firedart.dart' as fd;

class ScratchpadRepository extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthRepository _authRepository;
  
  List<ScratchpadNote> _notes = [];
  
  StreamSubscription? _notesSubscription;
  
  final _notesUpdateController = StreamController<void>.broadcast();
  Stream<void> get notesUpdates => _notesUpdateController.stream;

  ScratchpadRepository(this._firestoreService, this._authRepository) {
    _initFirestoreListener();
  }

  void _initFirestoreListener() {
    final existingUser = _authRepository.currentUser;
    if (existingUser != null) {
      _startFirestoreListener(existingUser.id);
    }

    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _notesSubscription?.cancel();
        _notesSubscription = null;
        _startFirestoreListener(user.id);
      } else {
        _notesSubscription?.cancel();
        _notesSubscription = null;
        _notes = [];
        notifyListeners();
        _notesUpdateController.add(null);
      }
    });
  }

  void _startFirestoreListener(String uid) {
    if (!kIsWeb && Platform.isLinux) {
      _listenToFiredart(uid);
    } else {
      try {
        _notesSubscription = FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("scratchpad_notes")
            .snapshots()
            .listen((snapshot) {
              _notes = snapshot.docs.map((doc) => ScratchpadNote.fromMap(doc.data())).toList();
              _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
              notifyListeners();
              _notesUpdateController.add(null);
            });
      } catch (e) {
        print("Scratchpad Firestore Stream Setup Error: $e");
      }
    }
  }

  void _listenToFiredart(String uid) {
    _notesSubscription?.cancel();
    
    if (!fd.FirebaseAuth.instance.isSignedIn) {
      return;
    }
    
    try {
      _notesSubscription = fd.Firestore.instance
          .collection("users")
          .document(uid)
          .collection("scratchpad_notes")
          .stream
          .listen((snapshots) {
            _notes = snapshots.map((doc) => ScratchpadNote.fromMap(doc.map)).toList();
            _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            notifyListeners();
            _notesUpdateController.add(null);
          });
    } catch (e) {
      print("Linux Scratchpad Firestore Stream Setup Error: $e");
    }
  }

  List<ScratchpadNote> get notes => List.unmodifiable(_notes);

  Future<List<ScratchpadNote>> getAllNotes() async {
    return _notes;
  }

  Future<ScratchpadNote?> getNoteById(String id) async {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  AuthRepository get authRepository => _authRepository;
  AppUser? get currentUser => _authRepository.currentUser;

  Future<int> upsertNote(ScratchpadNote note) async {
    final uid = _authRepository.currentUser?.id;
    if (uid == null) {
      print("Error: Attempted to upsert note without an authenticated user.");
      return 0;
    }

    final noteWithUid = note.copyWith(userId: uid);
    final existingIndex = _notes.indexWhere((n) => n.id == note.id);
    if (existingIndex != -1) {
      _notes[existingIndex] = noteWithUid;
    } else {
      _notes.add(noteWithUid);
    }
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
    _notesUpdateController.add(null);
    
    _firestoreService.saveScratchpadNote(noteWithUid).catchError((e) {
      print("Error saving note to Firestore: $e");
    });
    return 1;
  }

  Future<int> moveToTrash(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final updatedNote = note.copyWith(isDeleted: true, updatedAt: DateTime.now().millisecondsSinceEpoch);
      return await upsertNote(updatedNote);
    }
    return 0;
  }

  Future<int> restoreNote(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final updatedNote = note.copyWith(isDeleted: false, updatedAt: DateTime.now().millisecondsSinceEpoch);
      return await upsertNote(updatedNote);
    }
    return 0;
  }

  Future<int> deleteNotePermanently(String id) async {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    _notesUpdateController.add(null);
    _firestoreService.deleteScratchpadNote(id).catchError((e) {
      print("Error deleting note from Firestore: $e");
    });
    return 1;
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    _notesUpdateController.close();
    super.dispose();
  }
}
