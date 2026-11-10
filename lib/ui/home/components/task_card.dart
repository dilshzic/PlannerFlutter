import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';

class TaskCard extends StatelessWidget {
  final TaskNode task;
  final ValueChanged<bool?> onCheckedChange;
  final VoidCallback onClick;
  final bool hasSubtasks;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;
  final bool isSubtask;
  final String? projectColorHex;
  final String? projectTitle;
  final String? categoryTitle;
  final VoidCallback? onMoveToToday;
  final VoidCallback? onSchedule;
  final int? subtaskCount; // NEW
  final int? completedSubtaskCount;

  const TaskCard({
    super.key,
    required this.task,
    required this.onCheckedChange,
    required this.onClick,
    this.hasSubtasks = false,
    this.isExpanded = false,
    this.onExpandToggle,
    this.isSubtask = false,
    this.projectColorHex,
    this.projectTitle,
    this.categoryTitle,
    this.onMoveToToday,
    this.onSchedule,
    this.subtaskCount,
    this.completedSubtaskCount,
  });

  @override
  Widget build(BuildContext context) {
    final alpha = task.isCompleted ? 0.5 : 1.0;
    
    // Check if missed
    bool isMissed = false;
    if (task.scheduledDate != null && !task.isCompleted) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (task.scheduledDate!.isBefore(today)) {
        isMissed = true;
      }
    }
    
    Color? customColor;
    if (projectColorHex != null) {
      final hex = projectColorHex!.replaceFirst('#', '');
      customColor = Color(int.parse('FF$hex', radix: 16));
    }

    return Opacity(
      opacity: alpha,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isSubtask ? 0 : 2,
        clipBehavior: Clip.antiAlias,
        color: isSubtask
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceVariant.withAlpha(51),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                if (customColor != null)
                  Container(
                    width: 6,
                    color: customColor,
                  ),
                Expanded(
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
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (isMissed)
                                    _buildTag(context, "MISSED", Colors.red),
                                  if (subtaskCount != null && subtaskCount! > 0)
                                    _buildTag(
                                      context, 
                                      completedSubtaskCount != null ? "$completedSubtaskCount/$subtaskCount SUBTASKS" : "$subtaskCount SUBTASKS", 
                                      Colors.blueGrey,
                                    ),
                                  if (task.durationMinutes > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        "${task.durationMinutes}m",
                                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.secondary),
                                      ),
                                    ),
                                  if (projectTitle != null)
                                    _buildTag(context, projectTitle!, customColor ?? Colors.blueGrey),
                                  if (categoryTitle != null && categoryTitle != "General" && categoryTitle != "SUB")
                                    _buildTag(context, categoryTitle!, Colors.indigo),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (onMoveToToday != null && !task.isCompleted)
                          IconButton(
                            icon: const Icon(Icons.today, size: 20),
                            tooltip: 'Add to Today',
                            onPressed: onMoveToToday,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        if (onSchedule != null && !task.isCompleted)
                          IconButton(
                            icon: const Icon(Icons.calendar_month, size: 20),
                            tooltip: 'Schedule for Later',
                            onPressed: onSchedule,
                            color: Theme.of(context).colorScheme.secondary,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
