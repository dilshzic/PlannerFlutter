import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:narwhal/ui/calendar/calendar_view_model.dart';
import 'package:narwhal/ui/calendar/components/day_details_bottom_sheet.dart';

class WeekAgenda extends StatelessWidget {
  final CalendarViewModel viewModel;
  
  const WeekAgenda({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final now = viewModel.focusedDay;
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7)); 
    
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = startOfWeek.add(Duration(days: index));
        final tasks = viewModel.getTasksForDay(day);
        final isToday = isSameDay(day, DateTime.now());
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: isToday ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isToday ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              viewModel.onDaySelected(day, viewModel.focusedDay);
              showDayDetailsBottomSheet(context, viewModel, day);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d').format(day),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isToday ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tasks.isEmpty)
                    const Text('No tasks scheduled.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                  else
                    ...tasks.take(3).map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          Icon(
                            t.isCompleted ? Icons.check_circle : Icons.circle, 
                            size: 10, 
                            color: t.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.title, 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(decoration: t.isCompleted ? TextDecoration.lineThrough : null),
                            )
                          ),
                        ],
                      ),
                    )),
                  if (tasks.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('+ ${tasks.length - 3} more task(s)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
