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
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  notes TEXT NOT NULL DEFAULT '',
  colorHex TEXT,
  userId TEXT,
  updatedAt INTEGER NOT NULL
)
''');

    await db.execute('''
CREATE TABLE project_phases (
  id TEXT PRIMARY KEY,
  projectId TEXT NOT NULL,
  name TEXT NOT NULL,
  orderIndex INTEGER NOT NULL,
  isCompleted INTEGER NOT NULL,
  FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
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
  projectId TEXT,
  phaseId TEXT,
  isZone INTEGER NOT NULL,
  colorHex TEXT,
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
  FOREIGN KEY (parentId) REFERENCES tasks (id) ON DELETE CASCADE,
  FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE SET NULL,
  FOREIGN KEY (phaseId) REFERENCES project_phases (id) ON DELETE SET NULL
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
    await db.execute('CREATE INDEX index_tasks_projectId ON tasks(projectId)');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration to v2 (Projects)
      await db.execute('ALTER TABLE tasks ADD COLUMN projectId TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN phaseId TEXT');
      
      await db.execute('''
CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  colorHex TEXT,
  userId TEXT,
  updatedAt INTEGER NOT NULL
)
''');

      await db.execute('''
CREATE TABLE project_phases (
  id TEXT PRIMARY KEY,
  projectId TEXT NOT NULL,
  name TEXT NOT NULL,
  orderIndex INTEGER NOT NULL,
  isCompleted INTEGER NOT NULL,
  FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
)
''');
      await db.execute('CREATE INDEX index_tasks_projectId ON tasks(projectId)');
    }
    
    if (oldVersion < 3) {
      // Migration to v3 (Task Color)
      await db.execute('ALTER TABLE tasks ADD COLUMN colorHex TEXT');
    }

    if (oldVersion < 4) {
      // Migration to v4 (Project Notes)
      await db.execute("ALTER TABLE projects ADD COLUMN notes TEXT NOT NULL DEFAULT ''");
    }
  }

  Future close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
