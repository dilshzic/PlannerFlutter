import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/ui/home/components/task_card.dart';
import 'package:narwhal/ui/addedit/add_edit_task_screen.dart';

class RecursiveTaskCard extends StatefulWidget {
  final TaskNode task;
  final Function(TaskNode, bool) onCheckedChange;
  final VoidCallback onClick;
  final String? projectColorHex;
  final int depth;

  const RecursiveTaskCard({
    super.key,
    required this.task,
    required this.onCheckedChange,
    required this.onClick,
    this.projectColorHex,
    this.depth = 0,
  });

  @override
  State<RecursiveTaskCard> createState() => _RecursiveTaskCardState();
}

class _RecursiveTaskCardState extends State<RecursiveTaskCard> {
  List<TaskNode> _subtasks = [];
  bool _isExpanded = false; // Default to collapsed for a cleaner look
  StreamSubscription? _nodeSubscription;
  final TextEditingController _newSubtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubtasks();
    _nodeSubscription = context.read<TaskNodeRepository>().nodeUpdates.listen((_) {
      if (mounted) _loadSubtasks();
    });
  }
  
  @override
  void didUpdateWidget(RecursiveTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
       _loadSubtasks();
    }
  }
  
  @override
  void dispose() {
    _newSubtaskController.dispose();
    _nodeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSubtasks() async {
    final repo = context.read<TaskNodeRepository>();
    final children = await repo.getChildrenOf(widget.task.id);
    if (mounted) {
      setState(() {
        _subtasks = children.where((t) => t.nodeType == NodeType.task).toList();
      });
    }
  }

  Future<void> _addSubtask(String title) async {
    if (title.trim().isEmpty) return;
    
    final repo = context.read<TaskNodeRepository>();
    final newTask = TaskNode(
      title: title,
      parentId: widget.task.id,
      nodeType: NodeType.task,
      categoryId: "SUB",
      scheduledDate: widget.task.scheduledDate, // Inherit schedule
    );
    
    await repo.upsertNode(newTask);
    _newSubtaskController.clear();
    _loadSubtasks();
  }

  @override
  Widget build(BuildContext context) {
    final indent = widget.depth * 32.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: indent),
            IconButton(
              icon: Icon(_isExpanded ? Icons.expand_more : (_subtasks.isEmpty ? Icons.add : Icons.chevron_right)),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              color: _subtasks.isEmpty && !_isExpanded ? Theme.of(context).colorScheme.primary : null,
            ),
              
            Expanded(
              child: Dismissible(
                key: Key('dismiss_${widget.task.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await context.read<TaskNodeRepository>().deleteNode(widget.task.id);
                },
                child: TaskCard(
                  task: widget.task,
                  onCheckedChange: (val) => widget.onCheckedChange(widget.task, val ?? false),
                  onClick: widget.onClick,
                  projectColorHex: widget.projectColorHex,
                  subtaskCount: _subtasks.length,
                  completedSubtaskCount: _subtasks.where((t) => t.isCompleted).length,
                ),
              ),
            ),
          ],
        ),
        if (_isExpanded) ...[
          ..._subtasks.map((sub) => Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: RecursiveTaskCard(
              key: ValueKey(sub.id),
              task: sub,
              onCheckedChange: widget.onCheckedChange,
              onClick: () async {
                 await Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: sub)),
                 );
                 _loadSubtasks(); 
              },
              projectColorHex: widget.projectColorHex,
              depth: widget.depth + 1,
            ),
          )),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                SizedBox(width: (widget.depth + 1) * 32.0 + 40),
                Expanded(
                  child: TextField(
                    controller: _newSubtaskController,
                    decoration: InputDecoration(
                      hintText: "Add subtask...",
                      border: InputBorder.none,
                      isDense: true,
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onSubmitted: _addSubtask,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, size: 20),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () => _addSubtask(_newSubtaskController.text),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
