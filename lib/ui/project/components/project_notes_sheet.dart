import 'package:flutter/material.dart';
import 'package:narwhal/ui/project/project_detail_view_model.dart';

class ProjectNotesSheet extends StatelessWidget {
  final ProjectDetailViewModel viewModel;

  const ProjectNotesSheet({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Project Scratchpad', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: viewModel.notesController,
              maxLines: null,
              expands: true,
              onChanged: viewModel.onNotesChanged,
              decoration: const InputDecoration(
                hintText: 'Write down your project ideas here...',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16, height: 1.6),
              autofocus: true,
            ),
          ),
        ],
      ),
    );
  }
}
