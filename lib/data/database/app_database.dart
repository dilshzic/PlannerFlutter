import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('planner.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  colorHex TEXT NOT NULL,
  iconName TEXT,
  userId TEXT
)
''');

    await db.execute('''
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  categoryId TEXT NOT NULL,
  priority INTEGER NOT NULL,
  parentId TEXT,
  isZone INTEGER NOT NULL,
  scheduledDate INTEGER,
  startDateTime INTEGER,
  endDateTime INTEGER,
  completedDate INTEGER,
  deadline INTEGER,
  durationMinutes INTEGER NOT NULL,
  recurrenceRule TEXT,
  lastGeneratedDate TEXT,
  isCompleted INTEGER NOT NULL,
  estimatedBlocks INTEGER NOT NULL,
  totalBlocksSpent INTEGER NOT NULL,
  userId TEXT,
  updatedAt INTEGER NOT NULL,
  FOREIGN KEY (parentId) REFERENCES tasks (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE time_logs (
  id TEXT PRIMARY KEY,
  taskId TEXT NOT NULL,
  startTime TEXT NOT NULL,
  blocksEarned INTEGER NOT NULL,
  status TEXT NOT NULL,
  dateLogged TEXT NOT NULL,
  FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE
)
''');

    await db.execute('CREATE INDEX index_tasks_parentId ON tasks(parentId)');
  }

  Future close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
