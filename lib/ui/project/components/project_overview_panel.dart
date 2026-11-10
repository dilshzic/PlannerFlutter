import 'package:flutter/material.dart';
import 'package:narwhal/ui/project/project_detail_view_model.dart';
import 'package:narwhal/ui/project/components/project_progress_circle.dart';
import 'package:narwhal/ui/scratchpad/scratchpad_detail_screen.dart';

/// The right-side overview panel shown in landscape mode, containing
/// project progress, description, notes, and linked scratchpad documents.
class ProjectOverviewPanel extends StatelessWidget {
  final ProjectDetailViewModel viewModel;
  final VoidCallback onEditProject;

  const ProjectOverviewPanel({
    super.key,
    required this.viewModel,
    required this.onEditProject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Project Overview'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEditProject,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Project Progress'),
              const SizedBox(height: 16),
              Center(child: ProjectProgressCircle(percentage: viewModel.completionPercentage, size: 120)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '${viewModel.completedCount} Tasks Complete of ${viewModel.totalCount}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Description'),
              const SizedBox(height: 8),
              Text(
                viewModel.project.description.isNotEmpty ? viewModel.project.description : 'No description provided.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Scratchpad & Notes'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: viewModel.notesController,
                  maxLines: 15,
                  onChanged: viewModel.onNotesChanged,
                  decoration: const InputDecoration(
                    hintText: 'Quick ideas, links, or documentation...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 32),
              _buildExpansionTile('Team members & Contacts'),
              _buildScratchpadExpansionTile(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildExpansionTile(String title) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      tilePadding: EdgeInsets.zero,
      children: const [ListTile(title: Text('No items yet'))],
    );
  }

  Widget _buildScratchpadExpansionTile(BuildContext context) {
    return ExpansionTile(
      title: const Text('Linked Scratchpad Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: viewModel.linkedScratchpads.isNotEmpty,
      children: viewModel.linkedScratchpads.isEmpty
          ? const [ListTile(title: Text('No linked documents'))]
          : viewModel.linkedScratchpads.map((note) {
              return ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(note.title.isNotEmpty ? note.title : 'Untitled Note'),
                subtitle: Text(
                  note.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ScratchpadDetailScreen(note: note)),
                  );
                },
              );
            }).toList(),
    );
  }
}
