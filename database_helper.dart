import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'recipe_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(
      'recipes_v2.db',
    ); // Changed file name to ensure a clean setup
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // Setting version to 2 for the new relational schema design
    return await openDatabase(path, version: 2, onCreate: _createDB);
  }

  /// WEEK 7 SCHEMA: Relational Tables with Constraints
  Future _createDB(Database db, int version) async {
    // 1. Parent Table: Core Recipes
    await db.execute('''
      CREATE TABLE saved_recipes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        instructions TEXT,
        thumbnailUrl TEXT
      )
    ''');

    // 2. Child Table: Meal Plans (Linked by a Foreign Key)
    // ON DELETE CASCADE means if you delete a recipe, its scheduled meals are cleared too!
    await db.execute('''
      CREATE TABLE meal_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        planned_date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        recipe_id TEXT NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES saved_recipes (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==========================================
  // RECIPE FUNCTIONS (Your Existing Working Code)
  // ==========================================

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

  // ==========================================
  // MEAL PLAN FUNCTIONS (New Week 7 Additions)
  // ==========================================

  /// Inserts a newly scheduled meal slot into the database
  Future<int> insertMealPlan(
    String date,
    String mealType,
    String recipeId,
  ) async {
    final db = await instance.database;
    return await db.insert('meal_plans', {
      'planned_date': date,
      'meal_type': mealType,
      'recipe_id': recipeId,
    });
  }

  /// WEEK 7 ADVANCED REQ: Fetch data using an SQL INNER JOIN
  /// This pulls the calendar data AND matches it with the recipe image/name automatically!
  Future<List<Map<String, dynamic>>> fetchMealPlansWithRecipes() async {
    final db = await instance.database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        meal_plans.id AS mealPlanId,
        meal_plans.planned_date AS date,
        meal_plans.meal_type AS mealType,
        saved_recipes.name AS recipeName,
        saved_recipes.thumbnailUrl AS recipeImage,
        saved_recipes.id AS recipeId
      FROM meal_plans
      INNER JOIN saved_recipes ON meal_plans.recipe_id = saved_recipes.id
      ORDER BY meal_plans.planned_date ASC
    ''');

    return result;
  }

  /// Removes a scheduled meal slot by its unique ID
  Future<int> deleteMealPlan(int mealPlanId) async {
    final db = await instance.database;
    return await db.delete(
      'meal_plans',
      where: 'id = ?',
      whereArgs: [mealPlanId],
    );
  }
}
