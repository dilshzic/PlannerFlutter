import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/ui/project/project_detail_view_model.dart';
import 'package:narwhal/ui/project/components/recursive_task_card.dart';
import 'package:narwhal/ui/project/project_detail_screen.dart';

/// Builds the task list widgets (sub-projects, phases, active & completed tasks)
/// for the ProjectDetailScreen.
class ProjectTaskListBuilder {
  ProjectTaskListBuilder._();

  static Widget buildListHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          const SizedBox(width: 48),
          const Expanded(child: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
          const SizedBox(width: 80, child: Text('Due', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
          const SizedBox(width: 80, child: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  static List<Widget> buildTaskWidgets(
    BuildContext context,
    ProjectDetailViewModel viewModel, {
    required bool isLandscape,
    required VoidCallback Function(TaskNode task) onTaskTap,
    required VoidCallback onAddSubProject,
    required VoidCallback onAddPhase,
  }) {
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
            onPressed: onAddSubProject,
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
              onPressed: onAddPhase,
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
          onClick: onTaskTap(phase),
          projectColorHex: viewModel.project.colorHex,
        ),
      ));
    }

    if (isLandscape) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(buildListHeader(context));
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
          onClick: onTaskTap(task),
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

    return widgets;
  }
}
