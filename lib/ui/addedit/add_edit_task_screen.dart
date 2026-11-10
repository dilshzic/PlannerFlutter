import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:narwhal/ui/addedit/add_edit_task_view_model.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/services/ai/gemini_parser.dart';

import 'components/section_card.dart';
import 'components/project_selector.dart';
import 'components/strategy_section.dart';
import 'components/subtask_section.dart';
import 'components/main_info_section.dart';
import 'components/scheduling_section.dart';
import 'components/notes_section.dart';

class AddEditTaskScreen extends StatelessWidget {
  final TaskNode? task;
  final String? initialTitle;

  const AddEditTaskScreen({super.key, this.task, this.initialTitle});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddEditTaskViewModel(
        context.read<TaskNodeRepository>(),
        context.read<GeminiParser>(),
        task,
        initialTitle: initialTitle,
      ),
      child: Consumer<AddEditTaskViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(task == null ? 'Create Task' : 'Edit Task'),
              actions: [
                if (task != null)
                  IconButton(
                    icon: const Icon(Icons.drive_file_move_outline, color: Colors.blue),
                    tooltip: 'Convert to Project',
                    onPressed: () => _showConvertToProjectConfirm(context, viewModel),
                  ),
                if (task != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteConfirm(context, viewModel),
                  ),
              ],
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return _buildWideLayout(context, viewModel);
                } else {
                  return _buildNarrowLayout(context, viewModel);
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _showConvertToProjectConfirm(BuildContext context, AddEditTaskViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Project?'),
        content: const Text('This will turn this task into a Project. All its subtasks will automatically become tasks of the new project.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await viewModel.convertToProject();
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              }
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, AddEditTaskViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('This will permanently delete this task and all its subtasks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await viewModel.deleteTask();
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context, AddEditTaskViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MainInfoSection(
            title: viewModel.title,
            priority: viewModel.priority,
            onTitleChange: viewModel.onTitleChange,
            onPriorityChange: viewModel.onPriorityChange,
          ),
          const SizedBox(height: 16),
          ProjectSelector(
            parentId: viewModel.parentId,
            availableProjects: viewModel.availableProjects,
            onParentChange: viewModel.onParentChange,
          ),
          const SizedBox(height: 16),
          SchedulingSection(
            selectedDate: viewModel.selectedDate,
            selectedTime: viewModel.selectedTime,
            durationMinutes: viewModel.durationMinutes,
            isCustomDuration: viewModel.isCustomDuration,
            onDateChange: viewModel.onDateChange,
            onTimeChange: viewModel.onTimeChange,
            setDuration: viewModel.setDuration,
            clearSchedule: viewModel.clearSchedule,
          ),
          const SizedBox(height: 16),
          StrategySection(
            isStrategy: viewModel.isStrategy,
            deadline: viewModel.deadline,
            onStrategyChange: viewModel.onStrategyChange,
            onDeadlineChange: viewModel.onDeadlineChange,
          ),
          const SizedBox(height: 16),
          NotesSection(
            description: viewModel.description,
            onDescriptionChange: viewModel.onDescriptionChange,
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Checklist',
            icon: Icons.list,
            child: SubtaskSection(
              subtasks: viewModel.subtasks,
              isGeneratingChecklist: viewModel.isGeneratingChecklist,
              generateAIChecklist: viewModel.generateAIChecklist,
              onAddSubtask: viewModel.onAddSubtask,
              onToggleSubtask: viewModel.onToggleSubtask,
              onDeleteSubtask: viewModel.onDeleteSubtask,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, AddEditTaskViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MainInfoSection(
                  title: viewModel.title,
                  priority: viewModel.priority,
                  onTitleChange: viewModel.onTitleChange,
                  onPriorityChange: viewModel.onPriorityChange,
                ),
                const SizedBox(height: 24),
                ProjectSelector(
                  parentId: viewModel.parentId,
                  availableProjects: viewModel.availableProjects,
                  onParentChange: viewModel.onParentChange,
                ),
                const SizedBox(height: 24),
                NotesSection(
                  description: viewModel.description,
                  onDescriptionChange: viewModel.onDescriptionChange,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SchedulingSection(
                  selectedDate: viewModel.selectedDate,
                  selectedTime: viewModel.selectedTime,
                  durationMinutes: viewModel.durationMinutes,
                  isCustomDuration: viewModel.isCustomDuration,
                  onDateChange: viewModel.onDateChange,
                  onTimeChange: viewModel.onTimeChange,
                  setDuration: viewModel.setDuration,
                  clearSchedule: viewModel.clearSchedule,
                ),
                const SizedBox(height: 24),
                StrategySection(
                  isStrategy: viewModel.isStrategy,
                  deadline: viewModel.deadline,
                  onStrategyChange: viewModel.onStrategyChange,
                  onDeadlineChange: viewModel.onDeadlineChange,
                ),
                const SizedBox(height: 24),
                SectionCard(
                  title: 'Checklist',
                  icon: Icons.list,
                  child: SubtaskSection(
                    subtasks: viewModel.subtasks,
                    isGeneratingChecklist: viewModel.isGeneratingChecklist,
                    generateAIChecklist: viewModel.generateAIChecklist,
                    onAddSubtask: viewModel.onAddSubtask,
                    onToggleSubtask: viewModel.onToggleSubtask,
                    onDeleteSubtask: viewModel.onDeleteSubtask,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
