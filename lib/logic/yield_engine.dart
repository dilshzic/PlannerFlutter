import '../entity/task.dart';

class YieldEngine {
  double calculateYieldScore(Task task) {
    double score = task.priority * 10.0;

    final deadlineDate = task.deadline;

    if (deadlineDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final deadline = DateTime(deadlineDate.year, deadlineDate.month, deadlineDate.day);
      
      final daysUntil = deadline.difference(today).inDays;
      
      if (daysUntil <= 3) score += 50.0; // Urgent
      if (daysUntil <= 7) score += 20.0;
    }

    // Zones (mandatory events) shouldn't clutter the "High Yield" list usually
    if (task.isZone) score -= 100.0;

    return score;
  }
}
