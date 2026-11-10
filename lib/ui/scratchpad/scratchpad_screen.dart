import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:narwhal/data/repository/scratchpad_repository.dart';
import 'package:narwhal/ui/scratchpad/scratchpad_list_view_model.dart';
import 'package:narwhal/ui/scratchpad/scratchpad_detail_screen.dart';
import 'package:narwhal/ui/scratchpad/scratchpad_trash_screen.dart';

class ScratchpadScreen extends StatelessWidget {
  const ScratchpadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScratchpadListViewModel(context.read<ScratchpadRepository>()),
      child: Consumer<ScratchpadListViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(viewModel.showArchived ? 'Archived Notes' : 'Scratchpad'),
              actions: [
                IconButton(
                  icon: Icon(viewModel.showArchived ? Icons.archive : Icons.archive_outlined),
                  tooltip: viewModel.showArchived ? 'View Active Notes' : 'View Archived Notes',
                  onPressed: viewModel.toggleShowArchived,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Trash',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScratchpadTrashScreen()),
                    );
                    viewModel.loadNotes();
                  },
                ),
              ],
            ),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : (viewModel.showArchived ? viewModel.archivedNotes.isEmpty : viewModel.notes.isEmpty)
                    ? _buildEmptyState(context, viewModel.showArchived)
                    : _buildNotesList(context, viewModel),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScratchpadDetailScreen()),
                );
                viewModel.loadNotes();
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isArchived) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isArchived ? Icons.archive : Icons.edit_note, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(isArchived ? 'No archived notes' : 'No notes yet', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (!isArchived)
            const Text('Create a new note to start brainstorming', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, ScratchpadListViewModel viewModel) {
    final list = viewModel.showArchived ? viewModel.archivedNotes : viewModel.notes;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final note = list[index];
        final date = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);
        final formattedDate = '${date.month}/${date.day}/${date.year}';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScratchpadDetailScreen(note: note)),
              );
              viewModel.loadNotes();
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.isNotEmpty ? note.title : 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      note.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
