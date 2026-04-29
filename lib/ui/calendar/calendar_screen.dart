import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:planner/ui/calendar/calendar_view_model.dart';
import 'package:planner/data/repository/task_repository.dart';
import 'package:planner/data/entity/workload_level.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarViewModel(context.read<TaskRepository>()),
      child: Consumer<CalendarViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Calendar'),
            ),
            body: Column(
              children: [
                _buildExamCountdown(context),
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: viewModel.focusedDay,
                  calendarFormat: CalendarFormat.month,
                  onPageChanged: (focusedDay) {
                    viewModel.onMonthChanged(focusedDay);
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildDayCell(context, viewModel, day);
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _buildDayCell(context, viewModel, day, isToday: true);
                    },
                    outsideBuilder: (context, day, focusedDay) {
                      return _buildDayCell(context, viewModel, day, isOutside: true);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExamCountdown(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_hospital),
          SizedBox(width: 8),
          Text(
            'Exam in 45 days', // Hardcoded for now, like native if not calculated
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, CalendarViewModel viewModel, DateTime day, {bool isToday = false, bool isOutside = false}) {
    final workload = viewModel.getWorkloadForDay(day);
    final tasks = viewModel.getTasksForDay(day);

    Color? backgroundColor;
    if (isToday) {
      backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
    } else {
      switch (workload) {
        case WorkloadLevel.CASUALTY:
          backgroundColor = Colors.red[100];
          break;
        case WorkloadLevel.GRIND:
          backgroundColor = Colors.green[100];
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
      child: Column(
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: isOutside ? Colors.grey : null,
              fontWeight: isToday ? FontWeight.bold : null,
            ),
          ),
          const Spacer(),
          if (tasks.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: tasks.take(3).map((e) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              )).toList(),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
