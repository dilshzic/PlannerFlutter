import 'package:flutter/material.dart';

class PrioritySelector extends StatelessWidget {
  final int priority;
  final ValueChanged<int> onPriorityChange;

  const PrioritySelector({
    super.key,
    required this.priority,
    required this.onPriorityChange,
  });

  Color _getPriorityColor(int p) {
    switch (p) {
      case 1: return Colors.green;
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      default: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Priority Level', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [1, 2, 3, 4].map((p) {
            final isSelected = priority == p;
            final color = _getPriorityColor(p);
            return GestureDetector(
              onTap: () => onPriorityChange(p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: color, width: 2) : null,
                ),
                child: Text(
                  'P$p',
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
