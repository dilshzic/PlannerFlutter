import 'package:planner/data/database/app_database.dart';
import 'package:planner/data/entity/task.dart';
import 'package:planner/data/entity/time_log.dart';
import 'package:planner/data/firestore_service.dart';
import 'package:sqflite/sqflite.dart';

class TaskRepository {
  final AppDatabase _appDatabase = AppDatabase.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<int> insertTask(Task task) async {
    final db = await _appDatabase.database;
    final id = await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await _firestoreService.saveTask(task);
    return id;
  }

  Future<int> updateTask(Task task) async {
    final db = await _appDatabase.database;
    final id = await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
    await _firestoreService.saveTask(task);
    return id;
  }

  Future<int> deleteTask(String id) async {
    final db = await _appDatabase.database;
    final count = await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    await _firestoreService.deleteTask(id);
    return count;
  }

  Future<Task?> getTaskById(String id) async {
    final db = await _appDatabase.database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> getAllTasks() async {
    final db = await _appDatabase.database;
    final maps = await db.query('tasks', orderBy: 'updatedAt DESC');
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> insertTimeLog(TimeLog log) async {
    final db = await _appDatabase.database;
    return await db.insert('time_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getSubtasks(String parentId) async {
    final db = await _appDatabase.database;
    final maps = await db.query('tasks', where: 'parentId = ?', whereArgs: [parentId]);
    return maps.map((map) => Task.fromMap(map)).toList();
  }
}
