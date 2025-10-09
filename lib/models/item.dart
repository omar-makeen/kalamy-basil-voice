import 'package:hive/hive.dart';

part 'item.g.dart';

@HiveType(typeId: 1)
class Item {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final String? customSpeechText;

  @HiveField(4)
  final String imageType; // 'emoji', 'local', 'network'

  @HiveField(5)
  final String imageValue; // emoji character, local path, or network URL

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final int order;

  @HiveField(9)
  final String? customAudioPath; // Path to recorded audio file

  Item({
    required this.id,
    required this.categoryId,
    required this.text,
    this.customSpeechText,
    required this.imageType,
    required this.imageValue,
    required this.createdAt,
    required this.updatedAt,
    required this.order,
    this.customAudioPath,
  });

  Item copyWith({
    String? id,
    String? categoryId,
    String? text,
    String? customSpeechText,
    String? imageType,
    String? imageValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? order,
    String? customAudioPath,
  }) {
    return Item(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      text: text ?? this.text,
      customSpeechText: customSpeechText ?? this.customSpeechText,
      imageType: imageType ?? this.imageType,
      imageValue: imageValue ?? this.imageValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      order: order ?? this.order,
      customAudioPath: customAudioPath ?? this.customAudioPath,
    );
  }

  String get speechText => customSpeechText ?? text;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'text': text,
      'customSpeechText': customSpeechText,
      'imageType': imageType,
      'imageValue': imageValue,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'order': order,
      'customAudioPath': customAudioPath,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      text: map['text'] ?? '',
      customSpeechText: map['customSpeechText'],
      imageType: map['imageType'] ?? 'emoji',
      imageValue: map['imageValue'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      order: map['order'] ?? 0,
      customAudioPath: map['customAudioPath'],
    );
  }
}
