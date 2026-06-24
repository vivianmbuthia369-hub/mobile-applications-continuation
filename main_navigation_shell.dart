import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'recipe_model.dart';
import 'api_service.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  List<Recipe> _recipes = [];
  List<Recipe> _apiRecipes = [];
  bool _isLoadingApi = false;

  // Week 7: Relational database dataset replacing the old local array
  List<Map<String, dynamic>> _persistedMealPlans = [];

  String _selectedDate =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _instructionsController = TextEditingController();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _refreshData();
    _loadDiscoverRecipes();
  }

  // Week 7 Relational Sync: Pulls both recipes and our relational INNER JOIN query payload
  void _refreshData() async {
    final recipeData = await DatabaseHelper.instance.fetchSavedRecipes();
    final mealPlanData = await DatabaseHelper.instance
        .fetchMealPlansWithRecipes();

    if (!mounted) return;
    setState(() {
      _recipes = recipeData;
      _persistedMealPlans = mealPlanData;
    });
  }

  void _loadDiscoverRecipes() async {
    setState(() => _isLoadingApi = true);
    final apiData = await _apiService.fetchRandomRecipes();
    if (!mounted) return;
    setState(() {
      _apiRecipes = apiData;
      _isLoadingApi = false;
    });
  }

  void _showAddRecipeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Recipe',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Recipe Name'),
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: _instructionsController,
              decoration: const InputDecoration(labelText: 'Instructions'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  final newRecipe = Recipe(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _nameController.text,
                    category: _categoryController.text.isEmpty
                        ? 'General'
                        : _categoryController.text,
                    instructions: _instructionsController.text,
                  );
                  await DatabaseHelper.instance.insertRecipe(newRecipe);
                  if (!context.mounted) return;
                  _nameController.clear();
                  _categoryController.clear();
                  _instructionsController.clear();

                  Navigator.pop(context);
                  _refreshData();
                }
              },
              child: const Text('Save Recipe'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// WEEK 7 TASK: Save relational meal scheduling records persistently
  void _showAddMealPlanDialog() {
    String selectedMealType = 'Breakfast';
    Recipe? selectedRecipe = _recipes.isNotEmpty ? _recipes.first : null;

    if (selectedRecipe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one recipe first!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule Meal Slot',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: selectedMealType,
                items: ['Breakfast', 'Lunch', 'Dinner']
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (val) =>
                    setModalState(() => selectedMealType = val!),
                decoration: const InputDecoration(labelText: 'Time Slot'),
              ),
              DropdownButtonFormField<Recipe>(
                initialValue: selectedRecipe,
                items: _recipes
                    .map(
                      (r) => DropdownMenuItem<Recipe>(
                        value: r,
                        child: Text(r.name),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setModalState(() => selectedRecipe = val),
                decoration: const InputDecoration(labelText: 'Select Recipe'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (selectedRecipe != null) {
                    // Save structurally linked fields using Foreign Key parameters
                    await DatabaseHelper.instance.insertMealPlan(
                      _selectedDate,
                      selectedMealType,
                      selectedRecipe!.id,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _refreshData(); // Triggers re-fetch across INNER JOIN query pipeline
                  }
                },
                child: const Text('Confirm Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Week 7 Filter: Extracts matches for selected date from database view models
    final displayMeals = _persistedMealPlans
        .where((plan) => plan['date'] == _selectedDate)
        .toList();

    final List<Widget> screens = [
      // View 1: Recipe Book
      _recipes.isEmpty
          ? const Center(child: Text('Your recipe collection is empty.'))
          : ListView.builder(
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.deepOrange,
                      child: Icon(Icons.restaurant, color: Colors.white),
                    ),
                    title: Text(
                      recipe.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      recipe.instructions.isEmpty
                          ? 'No instructions.'
                          : recipe.instructions,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          recipe.category,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 5),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            await DatabaseHelper.instance.deleteRecipe(
                              recipe.id,
                            );
                            _refreshData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

      // View 2: Organized Meal Calendar & API Metrics View
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.deepOrange.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Schedule for: $_selectedDate',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.calendar_today,
                      color: Colors.deepOrange,
                    ),
                    label: const Text(
                      'Change Date',
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                ],
              ),
            ),

            // Dashboard Metrics Panel Block
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                color: Colors.green.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_done, color: Colors.green),
                      Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'API Node Gateway',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            'Connected & Active',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              key: ValueKey('scheduled_title'),
              child: Text(
                'Scheduled Menu Items',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            displayMeals.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Center(
                      child: Text('No meals structured for this date.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayMeals.length,
                    itemBuilder: (context, index) {
                      final plan = displayMeals[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.wb_twilight,
                            color: Colors.amber,
                          ),
                          title: Text(
                            plan['mealType'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          subtitle: Text(
                            plan['recipeName'] ?? 'Unknown Linked Recipe',
                            style: const TextStyle(fontSize: 15),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.grey,
                            ),
                            onPressed: () async {
                              await DatabaseHelper.instance.deleteMealPlan(
                                plan['mealPlanId'],
                              );
                              _refreshData();
                            },
                          ),
                        ),
                      );
                    },
                  ),

            const Divider(height: 30),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                'Discover Recipes (Live API Feed)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            _isLoadingApi
                ? const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepOrange,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _apiRecipes.take(5).length,
                    itemBuilder: (context, index) {
                      final apiRecipe = _apiRecipes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: apiRecipe.thumbnailUrl.isNotEmpty
                              ? Image.network(
                                  apiRecipe.thumbnailUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.cloud_download,
                                  color: Colors.grey,
                                ),
                          title: Text(
                            apiRecipe.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            apiRecipe.category,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepOrange,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Recipe Book'),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        onPressed: () async {
          if (_currentIndex == 0) {
            _showAddRecipeDialog();
          } else {
            _showAddMealPlanDialog();
          }
          await Future.delayed(const Duration(milliseconds: 500));
          _refreshData();
        },
        child: Icon(_currentIndex == 0 ? Icons.add : Icons.edit_calendar),
      ), // This closes FloatingActionButton
    ); // This closes Scaffold
  }
}
