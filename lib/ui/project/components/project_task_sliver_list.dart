import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/ui/project/project_detail_view_model.dart';
import 'package:narwhal/ui/project/components/recursive_task_card.dart';
import 'package:narwhal/ui/addedit/add_edit_task_screen.dart';
import 'package:narwhal/ui/project/add_edit_project_screen.dart';
import 'package:narwhal/ui/project/project_detail_screen.dart';

class ProjectTaskSliverList extends StatelessWidget {
  final ProjectDetailViewModel viewModel;
  final TaskNodeRepository taskNodeRepository;
  final bool isLandscape;

  const ProjectTaskSliverList({
    super.key,
    required this.viewModel,
    required this.taskNodeRepository,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    // Sub-Projects Section
    widgets.add(Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Sub-Projects (${viewModel.subProjects.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: () => _showAddSubProjectOptions(context),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ],
      ),
    ));

    for (var subProject in viewModel.subProjects) {
      widgets.add(Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(subProject.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProjectDetailScreen(project: subProject)),
            );
          },
        ),
      ));
    }
    
    // Phases Section
    if (viewModel.phases.isNotEmpty || !isLandscape) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Phases (${viewModel.phases.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => _showAddPhaseDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Phase'),
            ),
          ],
        ),
      ));
    }

    for (var phase in viewModel.phases) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: RecursiveTaskCard(
          key: ValueKey(phase.id),
          task: phase,
          onCheckedChange: (t, val) => viewModel.toggleTaskCompletion(t, val),
          onClick: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: phase)),
            );
            viewModel.loadProjectTasks();
          },
          projectColorHex: viewModel.project.colorHex,
        ),
      ));
    }
    
    if (isLandscape) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(_buildListHeader());
    } else {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 16.0, top: 16.0),
        child: Text(
          'Tasks (${viewModel.totalCount})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ));
    }

    Widget buildTask(TaskNode task) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: RecursiveTaskCard(
          key: ValueKey(task.id),
          task: task,
          onCheckedChange: (t, val) => viewModel.toggleTaskCompletion(t, val),
          onClick: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: task)),
            );
            viewModel.loadProjectTasks();
          },
          projectColorHex: viewModel.project.colorHex,
        ),
      );
    }

    for (var task in viewModel.activeTasks) {
      widgets.add(buildTask(task));
    }

    if (viewModel.completedTasks.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text('Completed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            tilePadding: EdgeInsets.zero,
            children: viewModel.completedTasks.map((task) => buildTask(task)).toList(),
          ),
        ),
      ));
    }
    
    return SliverList(
      delegate: SliverChildListDelegate(widgets),
    );
  }

  Widget _buildListHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          SizedBox(width: 48),
          Expanded(child: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
          SizedBox(width: 80, child: Text('Due', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
          SizedBox(width: 80, child: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  void _showAddPhaseDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Phase'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Phase name (e.g. Phase 1)'),
          autofocus: true,
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              viewModel.addPhase(val.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                viewModel.addPhase(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add Phase'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showAddSubProjectOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create New Sub-Project'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddEditProjectScreen(parentId: viewModel.project.id)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Link Existing Project'),
              onTap: () {
                Navigator.pop(context);
                _showLinkExistingProjectDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkExistingProjectDialog(BuildContext context) async {
    final allProjects = await taskNodeRepository.getNodesByType(NodeType.project);
    final linkableProjects = allProjects.where((p) => p.id != viewModel.project.id && p.parentId != viewModel.project.id).toList();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Existing Project'),
        content: SizedBox(
          width: double.maxFinite,
          child: linkableProjects.isEmpty
              ? const Text('No projects available to link.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: linkableProjects.length,
                  itemBuilder: (context, index) {
                    final p = linkableProjects[index];
                    return ListTile(
                      title: Text(p.title),
                      subtitle: Text(p.parentId != null ? 'Currently a sub-project' : 'Top-level project'),
                      onTap: () async {
                        await viewModel.linkExistingProject(p.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }
}
