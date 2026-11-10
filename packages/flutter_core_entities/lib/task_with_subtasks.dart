import 'package:flutter_core_entities/task_node.dart';

class TaskWithSubtasks {
  final TaskNode task;
  final List<TaskNode> subtasks;

  TaskWithSubtasks({required this.task, required this.subtasks});
}
