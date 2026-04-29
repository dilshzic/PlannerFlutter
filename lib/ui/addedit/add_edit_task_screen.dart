import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:planner/ui/addedit/add_edit_task_view_model.dart';
import 'package:planner/data/repository/task_repository.dart';
import 'package:planner/data/entity/task.dart';
import 'package:planner/logic/gemini_parser.dart';

class AddEditTaskScreen extends StatelessWidget {
  final Task? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddEditTaskViewModel(
        context.read<TaskRepository>(),
        context.read<GeminiParser>(),
        task,
      ),
      child: Consumer<AddEditTaskViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(task == null ? 'Create Task' : 'Edit Task'),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (viewModel.title.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }
                    await viewModel.saveTask();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    context,
                    title: 'Main Info',
                    child: Column(
                      children: [
                        TextField(
                          onChanged: viewModel.onTitleChange,
                          controller: TextEditingController(text: viewModel.title)
                            ..selection = TextSelection.collapsed(offset: viewModel.title.length),
                          decoration: const InputDecoration(
                            hintText: 'Task Title',
                            border: InputBorder.none,
                          ),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildPrioritySelector(context, viewModel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: 'Scheduling',
                    icon: Icons.event_note,
                    child: Column(
                      children: [
                        _buildDateTimePicker(context, viewModel),
                        const Divider(),
                        _buildDurationSlider(context, viewModel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: 'Notes',
                    icon: Icons.description,
                    child: TextField(
                      onChanged: viewModel.onDescriptionChange,
                      controller: TextEditingController(text: viewModel.description)
                        ..selection = TextSelection.collapsed(offset: viewModel.description.length),
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Add some details...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: 'Checklist',
                    icon: Icons.list,
                    child: _buildSubtaskSection(context, viewModel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubtaskSection(BuildContext context, AddEditTaskViewModel viewModel) {
    final TextEditingController subtaskController = TextEditingController();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Subtasks & Checklist", style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: viewModel.isGeneratingChecklist ? null : viewModel.generateAIChecklist,
              icon: viewModel.isGeneratingChecklist
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 18),
              label: const Text("AI Break down"),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: subtaskController,
                decoration: const InputDecoration(hintText: "Add a step manually..."),
              ),
            ),
            IconButton(
              onPressed: () {
                viewModel.onAddSubtask(subtaskController.text);
                subtaskController.clear();
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...viewModel.subtasks.asMap().entries.map((entry) {
          final index = entry.key;
          final sub = entry.value;
          return ListTile(
            leading: Checkbox(
              value: sub.isCompleted,
              onChanged: (value) => viewModel.onToggleSubtask(index, value ?? false),
            ),
            title: Text(sub.title, style: TextStyle(decoration: sub.isCompleted ? TextDecoration.lineThrough : null)),
            trailing: IconButton(
              onPressed: () => viewModel.onDeleteSubtask(index),
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, IconData? icon, required Widget child}) {
    return Card(
      shape: RoundedCornerShape(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                ],
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector(BuildContext context, AddEditTaskViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [1, 2, 3].map((p) {
        final isSelected = viewModel.priority == p;
        return ChoiceChip(
          label: Text('Priority $p'),
          selected: isSelected,
          onSelected: (_) => viewModel.onPriorityChange(p),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimePicker(BuildContext context, AddEditTaskViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: viewModel.selectedDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (date != null) viewModel.onDateChange(date);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                viewModel.selectedDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(viewModel.selectedDate!),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
        const VerticalDivider(),
        Expanded(
          child: InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: viewModel.selectedTime ?? TimeOfDay.now(),
              );
              if (time != null) viewModel.onTimeChange(time);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                viewModel.selectedTime == null ? 'Select Time' : viewModel.selectedTime!.format(context),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSlider(BuildContext context, AddEditTaskViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duration: ${viewModel.durationMinutes} minutes'),
        Slider(
          value: viewModel.durationMinutes.toDouble(),
          min: 5,
          max: 120,
          divisions: 23,
          onChanged: (value) => viewModel.onDurationChange(value.round()),
        ),
      ],
    );
  }
}

class RoundedCornerShape extends RoundedRectangleBorder {
  RoundedCornerShape(double radius) : super(borderRadius: BorderRadius.all(Radius.circular(radius)));
}
