import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:narwhal/ui/project/project_list_view_model.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/ui/project/project_detail_screen.dart';
import 'package:narwhal/ui/project/add_edit_project_screen.dart';

class ArchivedProjectsScreen extends StatelessWidget {
  const ArchivedProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectListViewModel(context.read<TaskNodeRepository>()),
      child: Consumer<ProjectListViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Archived Projects'),
            ),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.archivedProjects.isEmpty
                    ? _buildEmptyState(context)
                    : _buildProjectList(context, viewModel),
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
          Icon(Icons.archive_outlined, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No archived projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Projects you archive will appear here.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProjectList(BuildContext context, ProjectListViewModel viewModel) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 220, // Keep cards vertically short
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: viewModel.archivedProjects.length,
      itemBuilder: (context, index) {
        final project = viewModel.archivedProjects[index];
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
                        Text(project.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
                              onPressed: () => viewModel.archiveProject(project, false),
                              icon: const Icon(Icons.unarchive, size: 20),
                              label: const Text('Unarchive'),
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
    );
  }
}
