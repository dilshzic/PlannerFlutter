import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_core_entities/scratchpad_note.dart';
import 'package:narwhal/data/repository/scratchpad_repository.dart';

class ScratchpadListViewModel extends ChangeNotifier {
  final ScratchpadRepository _repository;
  List<ScratchpadNote> notes = [];
  List<ScratchpadNote> archivedNotes = [];
  bool isLoading = false;
  bool showArchived = false;
  StreamSubscription? _notesSubscription;

  ScratchpadListViewModel(this._repository) {
    loadNotes();
    _notesSubscription = _repository.notesUpdates.listen((_) => loadNotes());
  }

  void toggleShowArchived() {
    showArchived = !showArchived;
    notifyListeners();
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
    notes = allNotes.where((n) => !n.isDeleted && !n.isArchived).toList();
    archivedNotes = allNotes.where((n) => !n.isDeleted && n.isArchived).toList();
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(String title, String content) async {
    final note = ScratchpadNote(title: title, content: content);
    await _repository.upsertNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _repository.moveToTrash(id);
    await loadNotes();
  }

  Future<void> archiveNote(ScratchpadNote note, bool archive) async {
    final updated = note.copyWith(
      isArchived: archive,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.upsertNote(updated);
  }
}
