import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_core_entities/scratchpad_note.dart';
import 'package:narwhal/data/repository/scratchpad_repository.dart';

class ScratchpadTrashViewModel extends ChangeNotifier {
  final ScratchpadRepository _repository;
  List<ScratchpadNote> deletedNotes = [];
  bool isLoading = false;
  StreamSubscription? _notesSubscription;

  ScratchpadTrashViewModel(this._repository) {
    loadNotes();
    _notesSubscription = _repository.notesUpdates.listen((_) => loadNotes());
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadNotes() async {
    isLoading = true;
    notifyListeners();
    
    final allNotes = await _repository.getAllNotes();
    deletedNotes = allNotes.where((n) => n.isDeleted).toList();
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> restoreNote(String id) async {
    await _repository.restoreNote(id);
    await loadNotes();
  }

  Future<void> deleteNotePermanently(String id) async {
    await _repository.deleteNotePermanently(id);
    await loadNotes();
  }

  Future<void> emptyTrash() async {
    final notesToDelete = List<ScratchpadNote>.from(deletedNotes);
    for (var note in notesToDelete) {
      await _repository.deleteNotePermanently(note.id);
    }
    await loadNotes();
  }
}
