import 'dart:convert';
import 'package:flt_alx_core_ai/flt_alx_core_ai.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:intl/intl.dart';

class ExtractedTaskSuggestion {
  String title;
  String description;
  String? suggestedProjectId;
  String? suggestedProjectTitle;
  String confidence; // 'HIGH', 'MEDIUM', 'LOW'
  String reasoning;
  DateTime? scheduledDate;
  int durationMinutes;
  int priority;
  bool isZone;
  bool isSelected;

  ExtractedTaskSuggestion({
    required this.title,
    this.description = '',
    this.suggestedProjectId,
    this.suggestedProjectTitle,
    this.confidence = 'MEDIUM',
    this.reasoning = '',
    this.scheduledDate,
    this.durationMinutes = 0,
    this.priority = 1,
    this.isZone = false,
    this.isSelected = true,
  });

  factory ExtractedTaskSuggestion.fromJson(Map<String, dynamic> json) {
    DateTime? date;
    if (json['scheduledDate'] != null && json['scheduledDate'].toString().isNotEmpty) {
      date = DateTime.tryParse(json['scheduledDate'].toString());
    }

    return ExtractedTaskSuggestion(
      title: json['title']?.toString() ?? 'Untitled Task',
      description: json['description']?.toString() ?? '',
      suggestedProjectId: json['suggestedProjectId']?.toString(),
      suggestedProjectTitle: json['suggestedProjectTitle']?.toString(),
      confidence: json['confidence']?.toString().toUpperCase() ?? 'MEDIUM',
      reasoning: json['reasoning']?.toString() ?? '',
      scheduledDate: date,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      isZone: json['isZone'] == true,
      isSelected: true,
    );
  }
}

class TaskExtractionResult {
  final String summary;
  final String? suggestedNewProject;
  final List<ExtractedTaskSuggestion> tasks;

  TaskExtractionResult({
    required this.summary,
    this.suggestedNewProject,
    required this.tasks,
  });

  factory TaskExtractionResult.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    return TaskExtractionResult(
      summary: json['summary']?.toString() ?? '',
      suggestedNewProject: json['suggestedNewProject']?.toString(),
      tasks: rawTasks.map((t) => ExtractedTaskSuggestion.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }
}

class ScratchpadTaskExtractor {
  final AiBrainManager _brainManager;

  ScratchpadTaskExtractor(this._brainManager);

  Future<TaskExtractionResult> extractTasks({
    required String title,
    required String content,
    String? linkedProjectId,
    required List<TaskNode> activeProjects,
  }) async {
    final now = DateTime.now();
    final currentDateStr = DateFormat('yyyy-MM-dd').format(now);
    final dayOfWeek = DateFormat('EEEE').format(now);

    final projectsContext = activeProjects.map((p) => {
      'id': p.id,
      'title': p.title,
      'description': p.description,
      'notes': p.notes,
    }).toList();

    String? linkedProjectTitle;
    if (linkedProjectId != null) {
      final match = activeProjects.where((p) => p.id == linkedProjectId).toList();
      if (match.isNotEmpty) linkedProjectTitle = match.first.title;
    }

    final prompt = '''
You are Narwhal AI, the intelligent executive copilot for Narwhal: The Smart Planner.
Analyze this scratchpad note and extract all actionable, concrete tasks with high context awareness and project suggestion.

=== CURRENT ENVIRONMENT CONTEXT ===
- Today's Date: $currentDateStr ($dayOfWeek)
- Note Linked Project: ${linkedProjectTitle ?? "None (Unassigned)"}

=== USER'S ACTIVE PROJECTS ===
${jsonEncode(projectsContext)}

=== SCRATCHPAD NOTE ===
Note Title: "$title"
Note Content:
"""
$content
"""

=== EXTRACTION RULES ===
1. Extract all actionable to-dos, tasks, and calendar events.
2. Filter out non-actionable thoughts, observations, facts, or reference notes.
3. Resolve temporal dates ("tomorrow", "next Friday", "in 2 days") to YYYY-MM-DD relative to Today ($currentDateStr).
4. Extract duration in minutes if mentioned (e.g. "30 mins", "1 hour" -> 60). Default: 0.
5. Set priority: 1 (Urgent/P1) to 4 (Low/P4).
6. Set isZone: true for fixed events/classes/appointments, false for standard tasks.
7. Project Suggestion & Assignment:
   - For every task, determine which of the user's active projects it belongs to.
   - If the note has a linked project, that is a strong default unless the task clearly pertains to another project.
   - Return suggestedProjectId, suggestedProjectTitle, confidence ("HIGH", "MEDIUM", "LOW"), and reasoning.
   - If no project matches, set suggestedProjectId to null.

Return ONLY a raw JSON object (no markdown, no backticks):
{
  "summary": "1-sentence summary",
  "suggestedNewProject": null,
  "tasks": [
    {
      "title": "Clear task title",
      "description": "Optional brief context",
      "suggestedProjectId": "project-id-or-null",
      "suggestedProjectTitle": "Project Title or null",
      "confidence": "HIGH",
      "reasoning": "Reasoning for project assignment",
      "scheduledDate": "YYYY-MM-DD or null",
      "durationMinutes": 0,
      "priority": 1,
      "isZone": false
    }
  ]
}
''';

    final response = await _brainManager.askBrain(prompt);
    var text = response.text.trim();
    if (text.startsWith('```')) {
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
    }

    final json = jsonDecode(text) as Map<String, dynamic>;
    return TaskExtractionResult.fromJson(json);
  }
}
