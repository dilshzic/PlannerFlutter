import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/ui/components/narwhal_icon.dart';

class SubtaskSection extends StatefulWidget {
  final List<TaskNode> subtasks;
  final bool isGeneratingChecklist;
  final VoidCallback generateAIChecklist;
  final ValueChanged<String> onAddSubtask;
  final void Function(int, bool) onToggleSubtask;
  final ValueChanged<int> onDeleteSubtask;

  const SubtaskSection({
    super.key,
    required this.subtasks,
    required this.isGeneratingChecklist,
    required this.generateAIChecklist,
    required this.onAddSubtask,
    required this.onToggleSubtask,
    required this.onDeleteSubtask,
  });

  @override
  State<SubtaskSection> createState() => _SubtaskSectionState();
}

class _SubtaskSectionState extends State<SubtaskSection> {
  late final TextEditingController _subtaskController;

  @override
  void initState() {
    super.initState();
    _subtaskController = TextEditingController();
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final text = _subtaskController.text.trim();
    if (text.isNotEmpty) {
      widget.onAddSubtask(text);
      _subtaskController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Subtasks & Checklist", style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: widget.isGeneratingChecklist ? null : widget.generateAIChecklist,
              icon: widget.isGeneratingChecklist
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const NarwhalIcon(size: 18),
              label: const Text("Narwhal Breakdown"),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _subtaskController,
                decoration: const InputDecoration(hintText: "Add a step manually..."),
                onSubmitted: (_) => _handleAdd(),
              ),
            ),
            IconButton(
              onPressed: _handleAdd,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.subtasks.asMap().entries.where((e) => !e.value.isCompleted).map((entry) {
          final index = entry.key;
          final sub = entry.value;
          return ListTile(
            leading: Checkbox(
              value: sub.isCompleted,
              onChanged: (value) => widget.onToggleSubtask(index, value ?? false),
            ),
            title: Text(sub.title, style: TextStyle(decoration: sub.isCompleted ? TextDecoration.lineThrough : null)),
            trailing: IconButton(
              onPressed: () => widget.onDeleteSubtask(index),
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            ),
          );
        }),
        if (widget.subtasks.any((s) => s.isCompleted))
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('Completed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              tilePadding: EdgeInsets.zero,
              children: widget.subtasks.asMap().entries.where((e) => e.value.isCompleted).map((entry) {
                final index = entry.key;
                final sub = entry.value;
                return ListTile(
                  leading: Checkbox(
                    value: sub.isCompleted,
                    onChanged: (value) => widget.onToggleSubtask(index, value ?? false),
                  ),
                  title: Text(sub.title, style: TextStyle(decoration: sub.isCompleted ? TextDecoration.lineThrough : null)),
                  trailing: IconButton(
                    onPressed: () => widget.onDeleteSubtask(index),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
