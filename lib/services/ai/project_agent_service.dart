import 'dart:convert';
import 'package:flt_alx_core_ai/flt_alx_core_ai.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:intl/intl.dart';

class ProjectAgentService {
  final AiBrainManager _brainManager;

  ProjectAgentService(this._brainManager);

  String _formatProjectContext(TaskNode project, List<TaskNode> tasks) {
    final buffer = StringBuffer();
    buffer.writeln("PROJECT SUMMARY:");
    buffer.writeln("Title: ${project.title}");
    buffer.writeln("Description: ${project.description.isNotEmpty ? project.description : 'No description'}");
    buffer.writeln("Notes: ${project.notes.isNotEmpty ? project.notes : 'No notes'}");
    if (project.deadline != null) {
      buffer.writeln("Deadline: ${DateFormat('yyyy-MM-dd').format(project.deadline!)}");
    } else {
      buffer.writeln("Deadline: None");
    }
    buffer.writeln("");
    buffer.writeln("TASKS & HIERARCHY:");

    if (tasks.isEmpty) {
      buffer.writeln("- No tasks have been created yet.");
    } else {
      for (final t in tasks) {
        final status = t.isCompleted ? "[X]" : "[ ]";
        final date = t.scheduledDate != null 
            ? " (Scheduled: ${DateFormat('yyyy-MM-dd').format(t.scheduledDate!)})" 
            : "";
        final duration = t.durationMinutes > 0 ? " (${t.durationMinutes}m)" : "";
        final priority = " (Priority: P${t.priority})";
        buffer.writeln("- $status ${t.title}$priority$date$duration");
      }
    }
    return buffer.toString();
  }

  Future<BrainResponse> askAboutProject(
    TaskNode project,
    List<TaskNode> tasks,
    String userQuery, {
    List<Map<String, String>>? history,
  }) async {
    final context = _formatProjectContext(project, tasks);
    final prompt = '''
$context

User Query: "$userQuery"

You are Narwhal, a premium AI Project Copilot. Review the project context and hierarchy details provided above, then answer the user query.
Be extremely helpful, structured, and context-aware. If they ask about conflicts, highlight overlapping deadlines or heavy workloads. If they ask for suggestions, give practical, clear steps. Keep the answer concise and highly readable.

You can execute actions on the user's planner. When the user asks you to add a task or mark/complete a task as done, you MUST append the appropriate action command at the very end of your response text (outside normal conversation).

Commands:
- To add a task to this project: [ADD_TASK: Title of the task]
- To complete/mark a task as done in this project: [COMPLETE_TASK: Title of the task or task ID]
''';

    return await _brainManager.askBrain(
      prompt,
      config: _brainManager.defaultConfig.copyWith(
        metadata: {
          ..._brainManager.defaultConfig.metadata,
          if (history != null) 'history': history,
        },
      ),
    );
  }

  Future<List<String>> suggestTaskBreakdown(
    TaskNode project,
    List<TaskNode> tasks,
    String topic,
  ) async {
    final context = _formatProjectContext(project, tasks);
    final prompt = '''
$context

Goal for Breakdown: "$topic"

Suggest a breakdown of new, concrete tasks for this project to achieve the specified goal.
Return ONLY a raw JSON array of strings (no markdown blocks, no leading/trailing text) containing precisely the task titles.
Example format:
["Task 1 name", "Task 2 name"]
''';

    try {
      final response = await _brainManager.askBrain(prompt);
      final text = response.text.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> parsedList = jsonDecode(text);
      return parsedList.map((e) => e.toString()).toList();
    } catch (e) {
      print("Error in task breakdown generation: $e");
      return [];
    }
  }

  Future<String> analyzeTimelineAndConflicts(
    TaskNode project,
    List<TaskNode> tasks,
  ) async {
    final context = _formatProjectContext(project, tasks);
    final prompt = '''
$context

Perform a timeline and capacity analysis on this project.
Identify:
1. Total estimated time needed (sum of durations/blocks).
2. Proximity of the project deadline (if set).
3. Any scheduling issues (e.g. completed date conflicts, unscheduled tasks, too many tasks due on the same day).
Be brief, clear, and actionable. Keep the response to 3-4 bullet points.
''';

    try {
      final response = await _brainManager.askBrain(prompt);
      return response.text;
    } catch (e) {
      return "Unable to analyze timeline: $e";
    }
  }
}
