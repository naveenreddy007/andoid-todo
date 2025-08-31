import '../../domain/entities/tag.dart';

class TagModel {
  final String id;
  final String name;
  final String color;
  final String createdAt;

  const TagModel({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': color, 'created_at': createdAt};
  }

  Tag toEntity() {
    return Tag(
      id: id,
      name: name,
      color: color,
      createdAt: DateTime.parse(createdAt),
    );
  }

  static TagModel fromEntity(Tag tag) {
    return TagModel(
      id: tag.id,
      name: tag.name,
      color: tag.color,
      createdAt: tag.createdAt.toIso8601String(),
    );
  }
}
