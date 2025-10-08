import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String emoji;

  @HiveField(3)
  final int colorValue;

  @HiveField(4)
  final int order;

  Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.order,
  });

  Category copyWith({
    String? id,
    String? name,
    String? emoji,
    int? colorValue,
    int? order,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'colorValue': colorValue,
      'order': order,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '',
      colorValue: map['colorValue'] ?? 0,
      order: map['order'] ?? 0,
    );
  }
}
