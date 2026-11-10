import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Feedback", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "Frequently Asked Questions",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Find quick answers, then open docs or contact support if you still need help.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildFaqItem(
            context,
            "How do I quickly add a task?",
            "Use Quick Add on Timeline and type natural language like 'Study Cardio tomorrow 2h at 18:00'.",
          ),
          _buildFaqItem(
            context,
            "Why did my task not sync?",
            "Open Settings and check Sync Status. If it failed, use Retry Sync and verify network/sign-in.",
          ),
          _buildFaqItem(
            context,
            "How do project phases work?",
            "Open a project, add phases from Project Detail, then assign tasks to each phase while creating/editing tasks.",
          ),
          _buildFaqItem(
            context,
            "How does Focus mode calculate blocks?",
            "Focus mode tracks progress in 5-minute blocks. Completed session time is added to your daily block totals.",
          ),
          _buildFaqItem(
            context,
            "Can I clear local data safely?",
            "Yes. Clear Local Data removes on-device data only. Cloud data remains unchanged and can sync back later.",
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchUrl("https://planner-docs.example.com"),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text("Open Docs"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchUrl("mailto:support@example.com"),
                  icon: const Icon(Icons.email),
                  label: const Text("Support"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              answer,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
