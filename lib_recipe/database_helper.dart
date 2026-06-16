import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'recipe_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recipes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE saved_recipes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        instructions TEXT,
        thumbnailUrl TEXT
      )
    ''');
  }

  Future<int> insertRecipe(Recipe recipe) async {
    final db = await instance.database;
    return await db.insert(
      'saved_recipes',
      recipe.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Recipe>> fetchSavedRecipes() async {
    final db = await instance.database;
    final result = await db.query('saved_recipes');
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  Future<int> deleteRecipe(String id) async {
    final db = await instance.database;
    return await db.delete('saved_recipes', where: 'id = ?', whereArgs: [id]);
  }
}
