import 'package:narwhal/data/database/app_database.dart';
import 'package:flutter_core_entities/category.dart';
import 'package:sqflite/sqflite.dart';

class CategoryRepository {
  final AppDatabase _appDatabase = AppDatabase.instance;

  Future<int> insertCategory(Category category) async {
    final db = await _appDatabase.database;
    return await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Category>> getAllCategories() async {
    final db = await _appDatabase.database;
    final maps = await db.query('categories');
    return maps.map((map) => Category.fromMap(map)).toList();
  }
}
