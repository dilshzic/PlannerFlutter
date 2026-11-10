import 'package:uuid/uuid.dart';

class Project {
  final String id;
  final String title;
  final String description;
  final String notes; // NEW
  final String? colorHex;
  final String? userId;
  final int updatedAt;

  Project({
    String? id,
    this.title = "",
    this.description = "",
    this.notes = "", // NEW
    this.colorHex,
    this.userId,
    int? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  Project copyWith({
    String? id,
    String? title,
    String? description,
    String? notes,
    String? colorHex,
    String? userId,
    int? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      colorHex: colorHex ?? this.colorHex,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      notes: (map['notes'] as String?) ?? "",
      colorHex: map['colorHex'] as String?,
      userId: map['userId'] as String?,
      updatedAt: map['updatedAt'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'notes': notes,
      'colorHex': colorHex,
      'userId': userId,
      'updatedAt': updatedAt,
    };
  }
}

class ProjectPhase {
  final String id;
  final String projectId;
  final String name;
  final int orderIndex;
  final bool isCompleted;

  ProjectPhase({
    String? id,
    required this.projectId,
    required this.name,
    this.orderIndex = 0,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  ProjectPhase copyWith({
    String? id,
    String? projectId,
    String? name,
    int? orderIndex,
    bool? isCompleted,
  }) {
    return ProjectPhase(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory ProjectPhase.fromMap(Map<String, dynamic> map) {
    return ProjectPhase(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      name: map['name'] as String,
      orderIndex: map['orderIndex'] as int,
      isCompleted: map['isCompleted'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'orderIndex': orderIndex,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }
}
