import 'dart:convert';
import 'package:http/http.dart' as http;
import 'recipe_model.dart';

class ApiService {
  static const String connectionString =
      "https://www.themealdb.com/api/json/v1/1/search.php?s=";

  Future<List<Recipe>> searchRecipes(String query) async {
    final Uri url = Uri.parse('$connectionString$query');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['meals'] == null) {
          return [];
        }

        final List<dynamic> mealsList = data['meals'];
        return mealsList.map((mealJson) => Recipe.fromMap(mealJson)).toList();
      } else {
        throw Exception('Server error status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
