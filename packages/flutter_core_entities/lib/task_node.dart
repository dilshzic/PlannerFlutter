import 'package:uuid/uuid.dart';

enum NodeType { task, project, phase }

class TaskNode {
  final String id;
  final String title;
  final String description;
  final NodeType nodeType;
  
  // Hierarchy
  final String? parentId; // Unifies projectId, phaseId, and parent task id.
  
  // Common properties
  final String categoryId;
  final int priority;
  final bool isZone;
  final String? colorHex;
  final String notes; // Originally from Project
  final int orderIndex; // Originally from Phase

  // Timing & Scheduling
  final DateTime? scheduledDate;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final DateTime? completedDate;
  final DateTime? deadline;
  final int durationMinutes;
  final String? recurrenceRule;
  final String? lastGeneratedDate;
  
  // Status
  final bool isCompleted;

  // Time Blocking
  final int estimatedBlocks;
  final int totalBlocksSpent;

  // Notifications
  final int? reminderOffsetMinutes;

  // Metadata
  final String? userId;
  final int updatedAt;
  final int? lastAccessedAt;
  final bool isPinned;
  
  // Google Integration
  final String? googleTaskId;
  final String? googleEventId;

  TaskNode({
    String? id,
    this.title = "",
    this.description = "",
    this.nodeType = NodeType.task,
    this.parentId,
    this.categoryId = "General",
    this.priority = 1,
    this.isZone = false,
    this.colorHex,
    this.notes = "",
    this.orderIndex = 0,
    this.scheduledDate,
    this.startDateTime,
    this.endDateTime,
    this.completedDate,
    this.deadline,
    this.durationMinutes = 0,
    this.recurrenceRule,
    this.lastGeneratedDate,
    this.isCompleted = false,
    this.estimatedBlocks = 0,
    this.totalBlocksSpent = 0,
    this.reminderOffsetMinutes,
    this.userId,
    int? updatedAt,
    this.lastAccessedAt,
    this.isPinned = false,
    this.googleTaskId,
    this.googleEventId,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  static const Object _sentinel = Object();

  TaskNode copyWith({
    String? id,
    String? title,
    String? description,
    NodeType? nodeType,
    Object? parentId = _sentinel,
    String? categoryId,
    int? priority,
    bool? isZone,
    Object? colorHex = _sentinel,
    String? notes,
    int? orderIndex,
    Object? scheduledDate = _sentinel,
    Object? startDateTime = _sentinel,
    Object? endDateTime = _sentinel,
    Object? completedDate = _sentinel,
    Object? deadline = _sentinel,
    int? durationMinutes,
    Object? recurrenceRule = _sentinel,
    Object? lastGeneratedDate = _sentinel,
    bool? isCompleted,
    int? estimatedBlocks,
    int? totalBlocksSpent,
    Object? reminderOffsetMinutes = _sentinel,
    Object? userId = _sentinel,
    int? updatedAt,
    Object? lastAccessedAt = _sentinel,
    bool? isPinned,
    Object? googleTaskId = _sentinel,
    Object? googleEventId = _sentinel,
    bool clearParentId = false,
    bool clearScheduledDate = false,
    bool clearCompletedDate = false,
    bool clearDeadline = false,
  }) {
    return TaskNode(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      nodeType: nodeType ?? this.nodeType,
      parentId: clearParentId
          ? null
          : (identical(parentId, _sentinel) ? this.parentId : parentId as String?),
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      isZone: isZone ?? this.isZone,
      colorHex: identical(colorHex, _sentinel) ? this.colorHex : colorHex as String?,
      notes: notes ?? this.notes,
      orderIndex: orderIndex ?? this.orderIndex,
      scheduledDate: clearScheduledDate
          ? null
          : (identical(scheduledDate, _sentinel) ? this.scheduledDate : scheduledDate as DateTime?),
      startDateTime: identical(startDateTime, _sentinel) ? this.startDateTime : startDateTime as DateTime?,
      endDateTime: identical(endDateTime, _sentinel) ? this.endDateTime : endDateTime as DateTime?,
      completedDate: clearCompletedDate
          ? null
          : (identical(completedDate, _sentinel) ? this.completedDate : completedDate as DateTime?),
      deadline: clearDeadline
          ? null
          : (identical(deadline, _sentinel) ? this.deadline : deadline as DateTime?),
      durationMinutes: durationMinutes ?? this.durationMinutes,
      recurrenceRule: identical(recurrenceRule, _sentinel) ? this.recurrenceRule : recurrenceRule as String?,
      lastGeneratedDate: identical(lastGeneratedDate, _sentinel) ? this.lastGeneratedDate : lastGeneratedDate as String?,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedBlocks: estimatedBlocks ?? this.estimatedBlocks,
      totalBlocksSpent: totalBlocksSpent ?? this.totalBlocksSpent,
      reminderOffsetMinutes: identical(reminderOffsetMinutes, _sentinel)
          ? this.reminderOffsetMinutes
          : reminderOffsetMinutes as int?,
      userId: identical(userId, _sentinel) ? this.userId : userId as String?,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: identical(lastAccessedAt, _sentinel) ? this.lastAccessedAt : lastAccessedAt as int?,
      isPinned: isPinned ?? this.isPinned,
      googleTaskId: identical(googleTaskId, _sentinel) ? this.googleTaskId : googleTaskId as String?,
      googleEventId: identical(googleEventId, _sentinel) ? this.googleEventId : googleEventId as String?,
    );
  }

  factory TaskNode.fromMap(Map<String, dynamic> map) {
    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      return false;
    }

    DateTime? toDateTime(dynamic value) {
      if (value == null) return null;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      try {
        if (value.runtimeType.toString().contains('Timestamp')) {
          return value.toDate();
        }
        if (value is DateTime) return value;
      } catch (_) {}
      return null;
    }
    
    NodeType parseNodeType(String? typeStr) {
      if (typeStr == 'NodeType.project' || typeStr == 'project') return NodeType.project;
      if (typeStr == 'NodeType.phase' || typeStr == 'phase') return NodeType.phase;
      return NodeType.task;
    }

    return TaskNode(
      id: map['id']?.toString() ?? const Uuid().v4(),
      title: map['title']?.toString() ?? "Untitled",
      description: map['description']?.toString() ?? "",
      nodeType: parseNodeType(map['nodeType']?.toString()),
      parentId: map['parentId']?.toString(),
      categoryId: map['categoryId']?.toString() ?? "General",
      priority: map['priority'] is int ? map['priority'] : 1,
      isZone: toBool(map['isZone']),
      colorHex: map['colorHex']?.toString(),
      notes: map['notes']?.toString() ?? "",
      orderIndex: map['orderIndex'] is int ? map['orderIndex'] : 0,
      scheduledDate: toDateTime(map['scheduledDate']),
      startDateTime: toDateTime(map['startDateTime']),
      endDateTime: toDateTime(map['endDateTime']),
      completedDate: toDateTime(map['completedDate']),
      deadline: toDateTime(map['deadline']),
      durationMinutes: map['durationMinutes'] is int ? map['durationMinutes'] : 0,
      recurrenceRule: map['recurrenceRule']?.toString(),
      lastGeneratedDate: map['lastGeneratedDate']?.toString(),
      isCompleted: toBool(map['isCompleted']),
      estimatedBlocks: map['estimatedBlocks'] is int ? map['estimatedBlocks'] : 0,
      totalBlocksSpent: map['totalBlocksSpent'] is int ? map['totalBlocksSpent'] : 0,
      reminderOffsetMinutes: map['reminderOffsetMinutes'] as int?,
      userId: map['userId']?.toString(),
      updatedAt: map['updatedAt'] is int ? map['updatedAt'] : DateTime.now().millisecondsSinceEpoch,
      lastAccessedAt: map['lastAccessedAt'] as int?,
      isPinned: toBool(map['isPinned']),
      googleTaskId: map['googleTaskId']?.toString(),
      googleEventId: map['googleEventId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'nodeType': nodeType.toString().split('.').last,
      'parentId': parentId,
      'categoryId': categoryId,
      'priority': priority,
      'isZone': isZone,
      'colorHex': colorHex,
      'notes': notes,
      'orderIndex': orderIndex,
      'scheduledDate': scheduledDate?.millisecondsSinceEpoch,
      'startDateTime': startDateTime?.millisecondsSinceEpoch,
      'endDateTime': endDateTime?.millisecondsSinceEpoch,
      'completedDate': completedDate?.millisecondsSinceEpoch,
      'deadline': deadline?.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'recurrenceRule': recurrenceRule,
      'lastGeneratedDate': lastGeneratedDate,
      'isCompleted': isCompleted,
      'estimatedBlocks': estimatedBlocks,
      'totalBlocksSpent': totalBlocksSpent,
      'reminderOffsetMinutes': reminderOffsetMinutes,
      'userId': userId,
      'updatedAt': updatedAt,
      'lastAccessedAt': lastAccessedAt,
      'isPinned': isPinned,
      'googleTaskId': googleTaskId,
      'googleEventId': googleEventId,
    };
  }
}
