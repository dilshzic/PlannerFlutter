import 'package:uuid/uuid.dart';

class ScratchpadNote {
  final String id;
  final String title;
  final String content;
  final int createdAt;
  final int updatedAt;
  final String? userId;
  final String? projectId;
  final bool isDeleted;
  final bool isArchived;

  ScratchpadNote({
    String? id,
    this.title = "",
    this.content = "",
    int? createdAt,
    int? updatedAt,
    this.userId,
    this.projectId,
    this.isDeleted = false,
    this.isArchived = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  static const Object _sentinel = Object();

  ScratchpadNote copyWith({
    String? id,
    String? title,
    String? content,
    int? createdAt,
    int? updatedAt,
    Object? userId = _sentinel,
    Object? projectId = _sentinel,
    bool? isDeleted,
    bool? isArchived,
    bool clearProjectId = false,
  }) {
    return ScratchpadNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: identical(userId, _sentinel) ? this.userId : userId as String?,
      projectId: clearProjectId
          ? null
          : (identical(projectId, _sentinel) ? this.projectId : projectId as String?),
      isDeleted: isDeleted ?? this.isDeleted,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  factory ScratchpadNote.fromMap(Map<String, dynamic> map) {
    return ScratchpadNote(
      id: map['id']?.toString() ?? const Uuid().v4(),
      title: map['title']?.toString() ?? "",
      content: map['content']?.toString() ?? "",
      createdAt: map['createdAt'] as int?,
      updatedAt: map['updatedAt'] as int?,
      userId: map['userId']?.toString(),
      projectId: map['projectId']?.toString(),
      isDeleted: map['isDeleted'] == true || map['isDeleted'] == 1,
      isArchived: map['isArchived'] == true || map['isArchived'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userId': userId,
      'projectId': projectId,
      'isDeleted': isDeleted,
      'isArchived': isArchived,
    };
  }
}
