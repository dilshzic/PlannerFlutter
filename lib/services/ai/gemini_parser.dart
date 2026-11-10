import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class ParsedTask {
  final String title;
  final DateTime? date;
  final int durationMinutes;
  final bool isZone;
  final String? recurrenceRule;
  final int priority;

  ParsedTask({
    required this.title,
    this.date,
    required this.durationMinutes,
    required this.isZone,
    this.recurrenceRule,
    required this.priority,
  });
}

class GeminiParser {
  final GenerativeModel _model;

  GeminiParser(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-3.1-flash-lite',
          apiKey: apiKey,
        );

  Future<ParsedTask?> parseTask(String input) async {
    final now = DateTime.now();
    final prompt = [
      Content.text('''
        You are a smart scheduler assistant. Extract structured data from this user input: "$input".
        Current Date: ${now.toIso8601String()}.
        
        Return ONLY a raw JSON object (no markdown) with these fields:
        - "title": Clean task name.
        - "date": YYYY-MM-DD. Calculate based on "tomorrow", "next friday". Null if missing.
        - "duration": Integer minutes. Default 0. Only set a value if the user explicitly mentions a duration.
        - "isZone": Boolean. True for events/classes/shifts. False for tasks.
        - "recurrence": RRULE string (e.g. "FREQ=WEEKLY;BYDAY=MO"). Null if one-off.
        - "priority": 1-4.
      ''')
    ];

    try {
      final response = await _model.generateContent(prompt);
      final text = response.text?.replaceAll('```json', '').replaceAll('```', '').trim();
      if (text == null) return null;

      final json = jsonDecode(text);
      return ParsedTask(
        title: json['title'] ?? '',
        date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
        durationMinutes: json['duration'] ?? 0,
        isZone: json['isZone'] ?? false,
        recurrenceRule: json['recurrence'],
        priority: json['priority'] ?? 1,
      );
    } catch (e) {
      print("Parsing Error: $e");
      return null;
    }
  }

  Future<List<String>> generateChecklist(String taskTitle) async {
    final prompt = [
      Content.text('''
        Break down this task into a logical step-by-step checklist: "$taskTitle".
        Return ONLY a raw JSON array of strings (no markdown).
        Example: ["Step 1", "Step 2", "Step 3"]
      ''')
    ];

    try {
      final response = await _model.generateContent(prompt);
      final text = response.text?.replaceAll('```json', '').replaceAll('```', '').trim();
      if (text == null) return [];

      final List<dynamic> list = jsonDecode(text);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      print("Checklist Error: $e");
      return [];
    }
  }

  Future<String> suggestRescheduling(List<String> tasks, String workloadStatus) async {
    final prompt = [
      Content.text('''
        The user's workload is currently "$workloadStatus".
        They have the following tasks today:
        ${tasks.map((t) => "- $t").join("\n")}
        
        Suggest which tasks should be moved to tomorrow to balance the day. 
        Keep the suggestion encouraging and concise (max 2 sentences).
      ''')
    ];

    try {
      final response = await _model.generateContent(prompt);
      return response.text?.trim() ?? "You've got a busy day. Consider moving low priority items to tomorrow.";
    } catch (e) {
      return "Busy day! Take it one step at a time.";
    }
  }

  Future<String> generateDailyMotivation(int progress, String workloadStatus) async {
    final prompt = [
      Content.text('''
        Generate a short, personalized motivational sentence (max 10 words) for a user.
        Current progress: $progress% of tasks completed.
        Workload status: $workloadStatus.
        Make it context-aware (e.g., encouraging if progress is low but it's a 'Grind' day, or celebratory if progress is high).
      ''')
    ];

    try {
      final response = await _model.generateContent(prompt);
      return response.text?.trim() ?? "Keep pushing forward!";
    } catch (e) {
      return "Let's make today count!";
    }
  }
}
