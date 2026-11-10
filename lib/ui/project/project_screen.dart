import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:narwhal/ui/project/project_list_view_model.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/ui/project/project_detail_screen.dart';
import 'package:narwhal/ui/project/add_edit_project_screen.dart';
import 'package:narwhal/ui/project/archived_projects_screen.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectListViewModel(context.read<TaskNodeRepository>()),
      child: Consumer<ProjectListViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Projects'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.archive),
                  tooltip: 'Archived Projects',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ArchivedProjectsScreen()),
                    );
                    viewModel.loadProjects();
                  },
                ),
              ],
            ),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.activeProjects.isEmpty
                    ? _buildEmptyState(context)
                    : _buildProjectList(context, viewModel),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEditProjectScreen()),
                );
                viewModel.loadProjects();
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No projects yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Create one to organize your tasks', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProjectList(BuildContext context, ProjectListViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Text(
            'Active Projects',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 220, // Keep cards vertically short
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: viewModel.activeProjects.length,
            itemBuilder: (context, index) {
              final project = viewModel.activeProjects[index];
              Color? projectColor;
              if (project.colorHex != null) {
                final hex = project.colorHex!.replaceFirst('#', '');
                projectColor = Color(int.parse('FF$hex', radix: 16));
              }

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    viewModel.markProjectAccessed(project);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProjectDetailScreen(project: project)),
                    );
                  },
                  onLongPress: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEditProjectScreen(project: project)),
                    );
                    viewModel.loadProjects();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (projectColor != null)
                        Container(height: 10, color: projectColor),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(project.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                  ),
                                  IconButton(
                                    icon: Icon(project.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                                    onPressed: () => viewModel.togglePin(project),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (project.description.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    project.description,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              else
                                const Expanded(child: SizedBox()),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => viewModel.archiveProject(project, true),
                                    icon: const Icon(Icons.archive, size: 20),
                                    label: const Text('Archive'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
