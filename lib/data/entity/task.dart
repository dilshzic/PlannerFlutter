import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final int priority;

  final String? parentId;
  final bool isZone;

  final DateTime? scheduledDate;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final DateTime? completedDate;
  final DateTime? deadline;

  final int durationMinutes;
  final String? recurrenceRule;
  final String? lastGeneratedDate;
  final bool isCompleted;

  final int estimatedBlocks;
  final int totalBlocksSpent;

  final String? userId;
  final int updatedAt;

  Task({
    String? id,
    this.title = "",
    this.description = "",
    this.categoryId = "General",
    this.priority = 1,
    this.parentId,
    this.isZone = false,
    this.scheduledDate,
    this.startDateTime,
    this.endDateTime,
    this.completedDate,
    this.deadline,
    this.durationMinutes = 30,
    this.recurrenceRule,
    this.lastGeneratedDate,
    this.isCompleted = false,
    this.estimatedBlocks = 0,
    this.totalBlocksSpent = 0,
    this.userId,
    int? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      categoryId: map['categoryId'] as String,
      priority: map['priority'] as int,
      parentId: map['parentId'] as String?,
      isZone: map['isZone'] == 1,
      scheduledDate: map['scheduledDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['scheduledDate'] as int) : null,
      startDateTime: map['startDateTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['startDateTime'] as int) : null,
      endDateTime: map['endDateTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endDateTime'] as int) : null,
      completedDate: map['completedDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['completedDate'] as int) : null,
      deadline: map['deadline'] != null ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int) : null,
      durationMinutes: map['durationMinutes'] as int,
      recurrenceRule: map['recurrenceRule'] as String?,
      lastGeneratedDate: map['lastGeneratedDate'] as String?,
      isCompleted: map['isCompleted'] == 1,
      estimatedBlocks: map['estimatedBlocks'] as int,
      totalBlocksSpent: map['totalBlocksSpent'] as int,
      userId: map['userId'] as String?,
      updatedAt: map['updatedAt'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'priority': priority,
      'parentId': parentId,
      'isZone': isZone ? 1 : 0,
      'scheduledDate': scheduledDate?.millisecondsSinceEpoch,
      'startDateTime': startDateTime?.millisecondsSinceEpoch,
      'endDateTime': endDateTime?.millisecondsSinceEpoch,
      'completedDate': completedDate?.millisecondsSinceEpoch,
      'deadline': deadline?.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'recurrenceRule': recurrenceRule,
      'lastGeneratedDate': lastGeneratedDate,
      'isCompleted': isCompleted ? 1 : 0,
      'estimatedBlocks': estimatedBlocks,
      'totalBlocksSpent': totalBlocksSpent,
      'userId': userId,
      'updatedAt': updatedAt,
    };
  }
}
