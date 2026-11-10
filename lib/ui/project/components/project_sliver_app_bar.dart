import 'package:flutter/material.dart';
import 'package:narwhal/ui/project/project_detail_view_model.dart';
import 'package:narwhal/ui/project/components/project_progress_circle.dart';
import 'package:narwhal/ui/components/narwhal_icon.dart';

class ProjectSliverAppBar extends StatelessWidget {
  final ProjectDetailViewModel viewModel;
  final VoidCallback onEditProject;
  final VoidCallback onShowAiAgent;
  final VoidCallback onShowNotes;
  final VoidCallback onDeleteProject;

  const ProjectSliverAppBar({
    super.key,
    required this.viewModel,
    required this.onEditProject,
    required this.onShowAiAgent,
    required this.onShowNotes,
    required this.onDeleteProject,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      actions: [
        IconButton(
          icon: const NarwhalIcon(size: 22),
          tooltip: 'Narwhal Project Copilot',
          onPressed: onShowAiAgent,
        ),
        IconButton(
          icon: const Icon(Icons.note_alt_outlined),
          tooltip: 'Project Notes',
          onPressed: onShowNotes,
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEditProject,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDeleteProject,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(viewModel.project.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        background: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ProjectProgressCircle(
                      percentage: viewModel.completionPercentage),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(viewModel.completionPercentage >= 1.0
                          ? 'Completed'
                          : 'Active'),
                      const SizedBox(height: 8),
                      const Text('Tasks',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          '${viewModel.completedCount} / ${viewModel.totalCount}'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
