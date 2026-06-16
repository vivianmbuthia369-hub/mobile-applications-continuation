import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Handles the kIsWeb flag environment check
import 'package:sqflite/sqflite.dart'; // Required to override the database factory
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Handles virtual web storage
import 'database_helper.dart';
import 'recipe_model.dart';
import 'api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Route the database factory safely if running inside a web browser engine
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe & Meal Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MainNavigationShell(),
    );
  }
}

// Shell wrapper to handle Tab switching smoothly
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DiscoverDashboardScreen(),
    const SavedReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepOrange,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Discover API',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Saved Reports',
          ),
        ],
      ),
    );
  }
}

// TAB 1: Complete Cloud Search & Interactive Discovery Engine
class DiscoverDashboardScreen extends StatefulWidget {
  const DiscoverDashboardScreen({super.key});

  @override
  State<DiscoverDashboardScreen> createState() =>
      _DiscoverDashboardScreenState();
}

class _DiscoverDashboardScreenState extends State<DiscoverDashboardScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Recipe> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _localSavedCount = 0;

  @override
  void initState() {
    super.initState();
    _updateLocalCounter();
  }

  Future<void> _updateLocalCounter() async {
    final saved = await DatabaseHelper.instance.fetchSavedRecipes();
    setState(() {
      _localSavedCount = saved.length;
    });
  }

  Future<void> _handleSearch([String? quickQuery]) async {
    final searchTerms = quickQuery ?? _searchController.text.trim();
    if (searchTerms.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await _apiService.searchRecipes(searchTerms);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showRecipeDetails(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                controller: scrollController,
                children: [
                  if (recipe.thumbnailUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        recipe.thumbnailUrl,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 15),
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    recipe.category,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const Divider(height: 30),
                  const Text(
                    'Preparation Instructions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recipe.instructions,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveRecipe(Recipe recipe) async {
    await DatabaseHelper.instance.insertRecipe(recipe);
    _updateLocalCounter();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${recipe.name}" saved to SQLite database module.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Culinary Portal'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Row of Analytical Status Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text(
                            'SQLite Bookmarks',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '$_localSavedCount Recipes',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text(
                            'API Node Gateway',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Connected',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Input Form Control Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Query by recipe name...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleSearch(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(55, 55),
                  ),
                  child: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick Category Filter Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    ['Chicken', 'Beef', 'Dessert', 'Seafood', 'Vegetarian'].map(
                      (cat) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ActionChip(
                            label: Text(cat),
                            onPressed: () {
                              _searchController.text = cat;
                              _handleSearch(cat);
                            },
                          ),
                        );
                      },
                    ).toList(),
              ),
            ),
            const Divider(height: 25),

            // Dynamic Server Response Grid List View Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _searchResults.isEmpty
                  ? const Center(
                      child: Text(
                        'Enter parameters or select a classification tag above.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final recipe = _searchResults[index];
                        return Card(
                          child: ListTile(
                            onTap: () => _showRecipeDetails(recipe),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                recipe.thumbnailUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              recipe.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(recipe.category),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.bookmark_add,
                                color: Colors.deepOrange,
                              ),
                              onPressed: () => _saveRecipe(recipe),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// TAB 2: SQLite Local Offline Reporting Dashboard Module
class SavedReportsScreen extends StatefulWidget {
  const SavedReportsScreen({super.key});

  @override
  State<SavedReportsScreen> createState() => _SavedReportsScreenState();
}

class _SavedReportsScreenState extends State<SavedReportsScreen> {
  List<Recipe> _localRecipes = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final data = await DatabaseHelper.instance.fetchSavedRecipes();
    setState(() {
      _localRecipes = data;
    });
  }

  Future<void> _deleteRecipe(String id) async {
    await DatabaseHelper.instance.deleteRecipe(id);
    _loadSavedData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Local Dataset Report'),
        backgroundColor: Colors.orange,
      ),
      body: _localRecipes.isEmpty
          ? const Center(
              child: Text('No offline records found in SQLite schema.'),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: _localRecipes.length,
                itemBuilder: (context, index) {
                  final item = _localRecipes[index];
                  return Card(
                    color: Colors.grey.shade50,
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          item.thumbnailUrl,
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Classification: ${item.category}'),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _deleteRecipe(item.id),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
