import 'package:flutter/material.dart';
import 'package:narwhal/ui/calendar/calendar_view_model.dart';
import 'package:flutter_core_entities/workload_level.dart';

class CalendarDayCell extends StatelessWidget {
  final CalendarViewModel viewModel;
  final DateTime day;
  final bool isToday;
  final bool isOutside;

  const CalendarDayCell({
    super.key,
    required this.viewModel,
    required this.day,
    this.isToday = false,
    this.isOutside = false,
  });

  @override
  Widget build(BuildContext context) {
    final workload = viewModel.getWorkloadForDay(day);
    final tasks = viewModel.getTasksForDay(day);
    final zones = viewModel.getZonesForDay(day);

    Color? backgroundColor;
    if (isToday) {
      backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
    } else {
      switch (workload) {
        case WorkloadLevel.CASUALTY:
          backgroundColor = Colors.red.withOpacity(0.15);
          break;
        case WorkloadLevel.GRIND:
          backgroundColor = Colors.green.withOpacity(0.15);
          break;
        case WorkloadLevel.RECOVERY:
          backgroundColor = null;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: isToday ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                color: isOutside ? Colors.grey : null,
                fontWeight: isToday ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(height: 4),
            // ZONE BARS
            ...zones.take(2).map((zone) => Container(
              width: double.infinity,
              height: 6,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const Spacer(),
            // TASK DOTS
            if (tasks.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: tasks.take(3).map((e) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
