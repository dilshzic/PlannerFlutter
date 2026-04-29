import 'package:flutter/material.dart';
import '../../../data/entity/task.dart';
import '../../../data/entity/task_with_subtasks.dart';
import 'task_card.dart';

class ExpandableTaskItem extends StatelessWidget {
  final TaskWithSubtasks item;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final Function(Task, bool) onToggleCheck;
  final VoidCallback onClick;

  const ExpandableTaskItem({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onToggleCheck,
    required this.onClick,
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
