import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:narwhal/data/repository/time_block_repository.dart';
import 'package:narwhal/services/focus_timer_service.dart';
import 'package:flutter_core_entities/task_with_subtasks.dart';
import '../../focus/focus_screen.dart';
import 'task_card.dart';

class ExpandableTaskItem extends StatelessWidget {
  final TaskWithSubtasks item;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final Function(TaskNode, bool) onToggleCheck;
  final VoidCallback onClick;
  final String? projectColorHex;
  final String? projectTitle;

  const ExpandableTaskItem({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onToggleCheck,
    required this.onClick,
    this.projectColorHex,
    this.projectTitle,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubtasks = item.subtasks.isNotEmpty;

    return Column(
      children: [
        TaskCard(
          task: item.task,
          onCheckedChange: (isChecked) => onToggleCheck(item.task, isChecked ?? false),
          onClick: onClick,
          hasSubtasks: hasSubtasks,
          isExpanded: isExpanded,
          onExpandToggle: onToggleExpand,
          projectColorHex: projectColorHex,
          projectTitle: projectTitle,
          subtaskCount: item.subtasks.length,
          completedSubtaskCount: item.subtasks.where((s) => s.isCompleted).length,
        ),
        if (isExpanded && item.task.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48.0, right: 16.0, top: 8.0, bottom: 8.0),
            child: MarkdownBody(
              data: item.task.description,
              styleSheet: MarkdownStyleSheet(
                p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (isExpanded && !item.task.isCompleted)
          Padding(
            padding: const EdgeInsets.only(left: 48.0, right: 16.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FocusScreen(task: item.task),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timer),
                    label: const Text("Start Focus"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final focusTimer = context.read<FocusTimerService>();
                      await focusTimer.addManualBlockFor(id: item.task.id, task: item.task);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added 1 time block! (6m)')),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text("Add Block"),
                  ),
                ],
              ),
            ),
          ),
        if (isExpanded && hasSubtasks)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: item.subtasks.asMap().entries.map((entry) {
                final sub = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      // Connector line placeholder
                      Container(
                        width: 24,
                        height: 40,
                        alignment: Alignment.center,
                        child: CustomPaint(
                          size: const Size(24, 40),
                          painter: _ConnectorPainter(isLast: entry.key == item.subtasks.length - 1),
                        ),
                      ),
                      Expanded(
                        child: TaskCard(
                          task: sub,
                          onCheckedChange: (isChecked) => onToggleCheck(sub, isChecked ?? false),
                          onClick: () {}, // Future: edit subtask
                          isSubtask: true,
                          projectColorHex: projectColorHex,
                          projectTitle: projectTitle,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final bool isLast;

  _ConnectorPainter({required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(127)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, isLast ? size.height / 2 : size.height);
    path.moveTo(size.width / 2, size.height / 2);
    path.lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
