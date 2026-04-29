import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planner/ui/focus/focus_view_model.dart';
import 'package:planner/data/repository/task_repository.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FocusViewModel(context.read<TaskRepository>()),
      child: Consumer<FocusViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: viewModel.activeTask != null
                  ? _ActiveSessionView(viewModel: viewModel)
                  : _TaskSelectionView(viewModel: viewModel),
            ),
          );
        },
      ),
    );
  }
}

class _TaskSelectionView extends StatelessWidget {
  final FocusViewModel viewModel;

  const _TaskSelectionView({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          const Text(
            "What's the focus?",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: viewModel.availableTasks.isEmpty
                ? const Center(child: Text("No pending tasks for today."))
                : ListView.builder(
                    itemCount: viewModel.availableTasks.length,
                    itemBuilder: (context, index) {
                      final task = viewModel.availableTasks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: ListTile(
                          onTap: () => viewModel.selectTask(task),
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${task.durationMinutes}m • Priority ${task.priority}"),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionView extends StatelessWidget {
  final FocusViewModel viewModel;

  const _ActiveSessionView({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withAlpha(102), // 0.4 * 255
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "FOCUS SESSION",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                viewModel.activeTask!.title,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 16,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              SizedBox(
                width: 280,
                height: 280,
                child: CircularProgressIndicator(
                  value: viewModel.currentBlockProgress,
                  strokeWidth: 16,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    "${(viewModel.currentBlockProgress * 100).toInt()}%",
                    style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                  ),
                  const Text("OF CURRENT BLOCK", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FocusStat(label: "Blocks", value: "${viewModel.sessionBlocksEarned}"),
              const SizedBox(width: 48),
              _FocusStat(label: "Total Time", value: "${viewModel.sessionBlocksEarned * 5}m"),
            ],
          ),
          Row(
            children: [
              IconButton.filled(
                onPressed: viewModel.stopSession,
                icon: const Icon(Icons.stop),
                iconSize: 36,
                padding: const EdgeInsets.all(16),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: viewModel.toggleTimer,
                  icon: Icon(viewModel.isRunning ? Icons.pause : Icons.play_arrow, size: 32),
                  label: Text(viewModel.isRunning ? "PAUSE" : "RESUME"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusStat extends StatelessWidget {
  final String label;
  final String value;

  const _FocusStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
