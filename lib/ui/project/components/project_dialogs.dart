import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:narwhal/ui/project/project_detail_view_model.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/services/ai/project_agent_service.dart';
import 'package:narwhal/ui/project/project_agent_view_model.dart';
import 'package:narwhal/ui/project/components/project_agent_panel.dart';
import 'package:narwhal/ui/project/add_edit_project_screen.dart';
import 'package:flutter_core_entities/task_node.dart';

/// Static helper class containing all dialogs and bottom sheets
/// used by the ProjectDetailScreen.
class ProjectDialogs {
  ProjectDialogs._();

  static void showNotesSheet(BuildContext context, ProjectDetailViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
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
      ),
    );
  }

  static void showAiAgentBottomSheet(BuildContext context, ProjectDetailViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ChangeNotifierProvider(
          create: (context) => ProjectAgentViewModel(
            context.read<TaskNodeRepository>(),
            context.read<ProjectAgentService>(),
            viewModel.project,
          ),
          child: ProjectAgentPanel(
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  static void showDeleteConfirm(BuildContext context, ProjectDetailViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Project?'),
        content: const Text('This will permanently delete the project record. Your tasks will be detached but not deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await viewModel.deleteProject();
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

  static void showAddTaskDialog(BuildContext context, ProjectDetailViewModel viewModel) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Project Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'What needs to be done?'),
          autofocus: true,
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              viewModel.addTask(val.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                viewModel.addTask(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  static void showAddPhaseDialog(BuildContext context, ProjectDetailViewModel viewModel) {
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

  static void showAddSubProjectOptions(BuildContext context, ProjectDetailViewModel viewModel) {
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
                showLinkExistingProjectDialog(context, viewModel);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showLinkExistingProjectDialog(BuildContext context, ProjectDetailViewModel viewModel) async {
    final allProjects = await context.read<TaskNodeRepository>().getNodesByType(NodeType.project);
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
