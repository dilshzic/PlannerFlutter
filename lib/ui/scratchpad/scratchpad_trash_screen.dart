import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:narwhal/data/repository/scratchpad_repository.dart';
import 'package:narwhal/ui/scratchpad/scratchpad_trash_view_model.dart';
import 'package:intl/intl.dart';

class ScratchpadTrashScreen extends StatelessWidget {
  const ScratchpadTrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ScratchpadTrashViewModel(
        context.read<ScratchpadRepository>(),
      ),
      child: Consumer<ScratchpadTrashViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Trash'),
              actions: [
                if (viewModel.deletedNotes.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    tooltip: 'Empty Trash',
                    onPressed: () => _showEmptyTrashConfirm(context, viewModel),
                  ),
              ],
            ),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.deletedNotes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Trash is empty', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.deletedNotes.length,
                        itemBuilder: (context, index) {
                          final note = viewModel.deletedNotes[index];
                          final dateStr = DateFormat('MMM d, yyyy - h:mm a').format(DateTime.fromMillisecondsSinceEpoch(note.updatedAt));
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                note.title.isNotEmpty ? note.title : 'Untitled Note',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Deleted: $dateStr',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              onTap: () => _showRestoreDialog(context, viewModel, note.id),
                            ),
                          );
                        },
                      ),
          );
        },
      ),
    );
  }

  void _showEmptyTrashConfirm(BuildContext context, ScratchpadTrashViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text('This will permanently delete all notes in the trash. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await viewModel.emptyTrash();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Empty Trash', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, ScratchpadTrashViewModel viewModel, String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note Actions'),
        content: const Text('Do you want to restore this note or delete it permanently?'),
        actions: [
          TextButton(
            onPressed: () async {
              await viewModel.deleteNotePermanently(noteId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              await viewModel.restoreNote(noteId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}
