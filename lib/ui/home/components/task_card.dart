import 'package:flutter/material.dart';
import '../../../data/entity/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?> onCheckedChange;
  final VoidCallback onClick;
  final bool hasSubtasks;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;
  final bool isSubtask;

  const TaskCard({
    super.key,
    required this.task,
    required this.onCheckedChange,
    required this.onClick,
    this.hasSubtasks = false,
    this.isExpanded = false,
    this.onExpandToggle,
    this.isSubtask = false,
  });

  @override
  Widget build(BuildContext context) {
    final alpha = task.isCompleted ? 0.5 : 1.0;

    return Opacity(
      opacity: alpha,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isSubtask ? 0 : 2,
        color: isSubtask
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceVariant.withAlpha(51),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Checkbox(
                  value: task.isCompleted,
                  onChanged: onCheckedChange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: isSubtask ? 14 : 16,
                          fontWeight: isSubtask ? FontWeight.normal : FontWeight.w500,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.durationMinutes > 0)
                        Text(
                          "${task.durationMinutes}m • ${task.estimatedBlocks} blocks",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasSubtasks)
                  IconButton(
                    onPressed: onExpandToggle,
                    icon: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
