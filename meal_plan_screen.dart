import 'package:flutter/material.dart';
import 'database_helper.dart';

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key}); // Add this line

  @override
  Widget build(BuildContext context) {
    // ... rest of your code
    return Scaffold(
      appBar: AppBar(title: Text("My Weekly Meal Plan")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.fetchMealPlansWithRecipes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final plans = snapshot.data!;
          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return ListTile(
                title: Text(plan['recipeName']),
                subtitle: Text("${plan['mealType']} on ${plan['date']}"),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteMealPlan(
                      plan['mealPlanId'],
                    );
                    // Refresh the screen after deletion
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
