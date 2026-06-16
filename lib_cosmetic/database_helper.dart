import 'package:sqflite/sqflite.dart'; // <-- This core import fixes all the red errors!
import 'package:path/path.dart';
import 'cosmetic_model.dart';

class DatabaseHelper {
  // Create a single, shared instance (Singleton pattern) of DatabaseHelper
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Internal reference to the SQLite database
  static Database? _database;

  DatabaseHelper._init();

  // Getter to access the database connection safely
  Future<Database> get database async {
    if (_database != null) return _database!;

    // Initialize the database if it doesn't exist yet
    _database = await _initDB('cosmetics.db');
    return _database!;
  }

  // Opens the local database file path on the storage system
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // SQL command that executes to create the structural schema table
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cosmetics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL
      )
    ''');
  }

  // 1. CREATE: Inserts a new cosmetic item row into the table
  Future<int> createProduct(CosmeticProduct product) async {
    final db = await instance.database;
    return await db.insert('cosmetics', product.toMap());
  }

  // 2. READ ALL: Fetches all rows from the table in alphabetical order
  Future<List<CosmeticProduct>> readAllProducts() async {
    final db = await instance.database;
    final result = await db.query('cosmetics', orderBy: 'name ASC');

    // Converts the raw List of Maps back into a List of Dart objects
    return result.map((json) => CosmeticProduct.fromMap(json)).toList();
  }

  // 3. UPDATE: Modifies the property fields of an existing row
  Future<int> updateProduct(CosmeticProduct product) async {
    final db = await instance.database;

    return await db.update(
      'cosmetics',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // 4. DELETE: Removes a specific row completely using its primary ID
  Future<int> deleteProduct(int id) async {
    final db = await instance.database;

    return await db.delete('cosmetics', where: 'id = ?', whereArgs: [id]);
  }

  // 5. SEARCH: Uses a wildcard query to live-filter names or brands
  Future<List<CosmeticProduct>> searchProducts(String query) async {
    final db = await instance.database;

    final result = await db.query(
      'cosmetics',
      where: 'name LIKE ? OR brand LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );

    return result.map((json) => CosmeticProduct.fromMap(json)).toList();
  }
}
