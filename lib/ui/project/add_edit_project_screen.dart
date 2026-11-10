import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/ui/project/add_edit_project_view_model.dart';

class AddEditProjectScreen extends StatelessWidget {
  final TaskNode? project;
  final String? parentId;

  const AddEditProjectScreen({super.key, this.project, this.parentId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddEditProjectViewModel(
        context.read<TaskNodeRepository>(),
        project,
        parentId: parentId,
      ),
      child: Consumer<AddEditProjectViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(project == null ? 'New Project' : 'Edit Project'),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (viewModel.title.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }
                    await viewModel.saveProject();
                    if (context.mounted) Navigator.pop(context, false);
                  },
                  child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel(context, 'Basic Info'),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: viewModel.titleController,
                          decoration: const InputDecoration(
                            hintText: 'Project Title',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.folder_outlined),
                          ),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        TextField(
                          controller: viewModel.descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'What is this project about?',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionLabel(context, 'Visual Identity'),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Choose a Theme Color', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildColorPicker(context, viewModel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (project != null)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showDeleteConfirm(context, viewModel),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Delete Project', style: TextStyle(color: Colors.red)),
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

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context, AddEditProjectViewModel viewModel) {
    final List<Color> colors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
        final isSelected = viewModel.colorHex == hex;
        return GestureDetector(
          onTap: () => viewModel.onColorChange(isSelected ? null : hex),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Theme.of(context).colorScheme.outline, width: 4) : null,
              boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)] : null,
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
          ),
        );
      }).toList(),
    );
  }

  void _showDeleteConfirm(BuildContext context, AddEditProjectViewModel viewModel) {
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
                Navigator.pop(context, true); // Go back and indicate deleted
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
