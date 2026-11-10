import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'insights_view_model.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InsightsViewModel(context.read<TaskNodeRepository>()),
      child: Consumer<InsightsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return Scaffold(
            appBar: AppBar(title: const Text("Insights")),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOverviewCards(context, viewModel),
                const SizedBox(height: 32),
                Text(
                  "Active Projects Progress",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...viewModel.projectProgressList.map((p) => _buildProjectProgress(context, p)),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, InsightsViewModel viewModel) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, "Completed", "${viewModel.totalCompleted}", Icons.check_circle, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(context, "Pending", "${viewModel.totalPending}", Icons.pending_actions, Colors.orange)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(context, "Logged", "${viewModel.totalMinutesLogged}m", Icons.timer, Colors.blue)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildProjectProgress(BuildContext context, ProjectProgress p) {
    Color? customColor;
    if (p.project.colorHex != null) {
      final hex = p.project.colorHex!.replaceFirst('#', '');
      customColor = Color(int.parse('FF$hex', radix: 16));
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p.project.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text("${(p.percent * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: p.percent,
            minHeight: 8,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            color: customColor ?? Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text("${p.completedTasks} / ${p.totalTasks} tasks", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
