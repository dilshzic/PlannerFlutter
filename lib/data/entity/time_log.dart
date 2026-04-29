import 'package:uuid/uuid.dart';

class TimeLog {
  final String id;
  final String taskId;
  final String startTime;
  final int blocksEarned;
  final String status;
  final String dateLogged;

  TimeLog({
    String? id,
    required this.taskId,
    required this.startTime,
    this.blocksEarned = 1,
    this.status = "COMPLETED",
    required this.dateLogged,
  }) : id = id ?? const Uuid().v4();

  factory TimeLog.fromMap(Map<String, dynamic> map) {
    return TimeLog(
      id: map['id'] as String,
      taskId: map['taskId'] as String,
      startTime: map['startTime'] as String,
      blocksEarned: map['blocksEarned'] as int,
      status: map['status'] as String,
      dateLogged: map['dateLogged'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'startTime': startTime,
      'blocksEarned': blocksEarned,
      'status': status,
      'dateLogged': dateLogged,
    };
  }
}
