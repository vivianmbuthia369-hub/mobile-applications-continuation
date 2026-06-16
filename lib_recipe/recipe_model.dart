class Recipe {
  final String id;
  final String name;
  final String category;
  final String instructions;
  final String thumbnailUrl;

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.instructions,
    required this.thumbnailUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'instructions': instructions,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id']?.toString() ?? map['idMeal']?.toString() ?? '',
      name: map['name'] ?? map['strMeal'] ?? '',
      category: map['category'] ?? map['strCategory'] ?? 'General',
      instructions: map['instructions'] ?? map['strInstructions'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? map['strMealThumb'] ?? '',
    );
  }
}
