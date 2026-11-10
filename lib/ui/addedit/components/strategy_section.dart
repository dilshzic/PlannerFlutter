import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:narwhal/ui/addedit/components/section_card.dart';

class StrategySection extends StatelessWidget {
  final bool isStrategy;
  final DateTime? deadline;
  final ValueChanged<bool> onStrategyChange;
  final ValueChanged<DateTime> onDeadlineChange;

  const StrategySection({
    super.key,
    required this.isStrategy,
    required this.deadline,
    required this.onStrategyChange,
    required this.onDeadlineChange,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Strategy Goal',
      icon: Icons.flag,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Mark as Strategy Goal'),
            value: isStrategy,
            onChanged: onStrategyChange,
          ),
          if (isStrategy) ...[
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Target Date (Deadline)'),
              subtitle: Text(
                deadline == null ? 'Not set' : DateFormat('MMM dd, yyyy').format(deadline!),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: deadline ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (date != null) onDeadlineChange(date);
              },
            ),
          ]
        ],
      ),
    );
  }
}
