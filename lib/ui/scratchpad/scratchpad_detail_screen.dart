import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_core_entities/scratchpad_note.dart';
import 'package:narwhal/data/repository/scratchpad_repository.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/ui/scratchpad/scratchpad_detail_view_model.dart';
import 'package:flt_alx_core_ai/flt_alx_core_ai.dart';

class ScratchpadDetailScreen extends StatelessWidget {
  final ScratchpadNote? note;

  const ScratchpadDetailScreen({super.key, this.note});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScratchpadDetailViewModel(
        context.read<ScratchpadRepository>(),
        context.read<TaskNodeRepository>(),
        note,
      ),
      child: Consumer<ScratchpadDetailViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Scratchpad Editor'),
              actions: [
                IconButton(
                  icon: viewModel.isExtractingTasks
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8)),
                  tooltip: 'Extract Tasks with Narwhal AI',
                  onPressed: viewModel.isExtractingTasks
                      ? null
                      : () => viewModel.extractTasksWithAi(
                            context,
                            context.read<AiBrainManager>(),
                          ),
                ),
                if (note != null || viewModel.titleController.text.isNotEmpty || viewModel.contentController.text.isNotEmpty) ...[
                  IconButton(
                    icon: Icon(viewModel.isArchived ? Icons.unarchive : Icons.archive_outlined),
                    tooltip: viewModel.isArchived ? 'Unarchive Note' : 'Archive Note',
                    onPressed: () => viewModel.toggleArchive(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteConfirm(context, viewModel),
                  ),
                ],
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  TextField(
                    controller: viewModel.titleController,
                    decoration: const InputDecoration(
                      hintText: 'Note Title',
                      border: InputBorder.none,
                    ),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (viewModel.projects.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: viewModel.selectedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Link to Project',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...viewModel.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title))),
                      ],
                      onChanged: viewModel.setProject,
                    ),
                  ],
                  const Divider(),
                  Expanded(
                    child: TextField(
                      controller: viewModel.contentController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText: 'Start brainstorming, typing ideas, pasting links...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ScratchpadDetailViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('This will permanently delete this note.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await viewModel.deleteNote();
              if (context.mounted) {
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context); // Go back
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
