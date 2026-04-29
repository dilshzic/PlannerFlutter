import 'package:planner/data/entity/task.dart';

class TaskWithSubtasks {
  final Task task;
  final List<Task> subtasks;

  TaskWithSubtasks({required this.task, required this.subtasks});
}
