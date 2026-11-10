import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:narwhal/ui/triage/triage_view_model.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/ui/addedit/add_edit_task_screen.dart';

class TriageScreen extends StatelessWidget {
  const TriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TriageViewModel(context.read<TaskNodeRepository>()),
      child: Consumer<TriageViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Triage Backlog', style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            body: viewModel.backlogTasks.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: viewModel.backlogTasks.length,
                    itemBuilder: (context, index) {
                      final task = viewModel.backlogTasks[index];
                      return _TriageListCard(
                        task: task,
                        onMoveToday: () => viewModel.onMoveToToday(task),
                        onMoveTomorrow: () => viewModel.onMoveToTomorrow(task),
                        onDelete: () => viewModel.onDeleteTask(task.id),
                        onClick: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: task)),
                          );
                          viewModel.loadBacklog();
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.done_all,
            size: 64,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text("Backlog Clear", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("All tasks are scheduled!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _TriageListCard extends StatelessWidget {
  final TaskNode task;
  final VoidCallback onMoveToday;
  final VoidCallback onMoveTomorrow;
  final VoidCallback onDelete;
  final VoidCallback onClick;

  const _TriageListCard({
    required this.task,
    required this.onMoveToday,
    required this.onMoveTomorrow,
    required this.onDelete,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onClick,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (task.durationMinutes > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 24.0),
                  child: Text(
                    "${task.durationMinutes}m • ${task.categoryId}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMoveToday,
                      icon: const Icon(Icons.today, size: 16),
                      label: const Text("Today"),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMoveTomorrow,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text("Tomorrow"),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
