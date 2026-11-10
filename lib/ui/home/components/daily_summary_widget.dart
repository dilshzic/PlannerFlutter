import 'package:flutter/material.dart';
import 'package:flutter_core_entities/workload_level.dart';
import 'package:narwhal/ui/components/narwhal_icon.dart';

class DailySummaryWidget extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final int totalMinutes;
  final WorkloadLevel workloadLevel;
  final String motivationText;
  final String? reschedulingSuggestion;
  final bool isAnalyzing;
  final VoidCallback onAnalyzeClick;
  final VoidCallback onDismissSuggestion;

  const DailySummaryWidget({
    super.key,
    required this.totalTasks,
    required this.completedTasks,
    required this.totalMinutes,
    required this.workloadLevel,
    required this.motivationText,
    this.reschedulingSuggestion,
    required this.isAnalyzing,
    required this.onAnalyzeClick,
    required this.onDismissSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    final workloadColor = _getWorkloadColor(workloadLevel);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Motivation Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(102),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Text(
              motivationText,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Main Stats Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    workloadColor.withAlpha(38),
                    workloadColor.withAlpha(13),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Daily Summary",
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                          Text(
                            workloadLevel.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: workloadColor,
                                ),
                          ),
                        ],
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 54,
                            height: 54,
                            child: CircularProgressIndicator(
                              value: progress,
                              color: workloadColor,
                              backgroundColor: workloadColor.withAlpha(51),
                              strokeWidth: 6,
                            ),
                          ),
                          Text(
                            "${(progress * 100).toInt()}%",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(Icons.check_circle, "$completedTasks/$totalTasks", "Tasks", workloadColor),
                      _StatItem(Icons.schedule, "${totalMinutes ~/ 60}h ${totalMinutes % 60}m", "Total", workloadColor),
                      _StatItem(Icons.bolt, totalTasks > 0 ? "${totalMinutes ~/ totalTasks}m" : "0m", "Avg", workloadColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (workloadLevel == WorkloadLevel.CASUALTY || reschedulingSuggestion != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer.withAlpha(51),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).colorScheme.error.withAlpha(51)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const NarwhalIcon(size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Workload Alert",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (reschedulingSuggestion == null) ...[
                        const Text(
                          "Your day is looking very heavy. Want me to suggest a better balance?",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isAnalyzing ? null : onAnalyzeClick,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: isAnalyzing
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text("Analyze & Fix", style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ] else ...[
                        Text(reschedulingSuggestion!, style: const TextStyle(fontSize: 12)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: onDismissSuggestion,
                            child: const Text("Got it", style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getWorkloadColor(WorkloadLevel level) {
    switch (level) {
      case WorkloadLevel.CASUALTY:
        return const Color(0xFFE57373);
      case WorkloadLevel.GRIND:
        return const Color(0xFF81C784);
      case WorkloadLevel.RECOVERY:
        return const Color(0xFFFFD54F);
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
