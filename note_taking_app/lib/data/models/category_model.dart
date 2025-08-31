import '../../domain/entities/category.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String color;
  final String createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    required this.color,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'created_at': createdAt,
    };
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      icon: icon,
      color: color,
      createdAt: DateTime.parse(createdAt),
    );
  }

  static CategoryModel fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
      color: category.color,
      createdAt: category.createdAt.toIso8601String(),
    );
  }
}
