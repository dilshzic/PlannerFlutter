import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/ui/calendar/calendar_view_model.dart';


void showDayDetailsBottomSheet(BuildContext context, CalendarViewModel viewModel, DateTime day) {
  final tasks = viewModel.getTasksForDay(day);
  
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(day),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (tasks.isEmpty)
              const Expanded(
                child: Center(child: Text("No tasks scheduled for this day.")),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Dismissible(
                      key: Key('dismiss_${task.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        await context.read<TaskNodeRepository>().deleteNode(task.id);
                        // Bottom sheet won't hot-reload itself without state management, but the repo deletes it.
                      },
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: task.isCompleted ? Colors.green : Theme.of(context).primaryColor,
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: task.description.isNotEmpty 
                          ? Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis) 
                          : null,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}
