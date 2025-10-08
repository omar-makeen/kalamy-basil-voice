import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/item.dart';

const uuid = Uuid();

class AppConstants {
  // App Colors
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color primaryPink = Color(0xFFFF69B4);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color primaryRed = Color(0xFFF44336);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryYellow = Color(0xFFFFEB3B);
  static const Color primaryIndigo = Color(0xFF3F51B5);

  // Category IDs
  static const String basicNeedsId = 'basic_needs';
  static const String emotionsId = 'emotions';
  static const String placesId = 'places';
  static const String gamesId = 'games';
  static const String tvId = 'tv';
  static const String foodId = 'food';
  static const String peopleId = 'people';
  static const String answersId = 'answers';

  // Default Categories
  static List<Category> getDefaultCategories() {
    return [
      Category(
        id: basicNeedsId,
        name: 'احتياجات أساسية',
        emoji: '🍽️',
        colorValue: primaryBlue.value,
        order: 0,
      ),
      Category(
        id: emotionsId,
        name: 'مشاعر',
        emoji: '😊',
        colorValue: primaryPink.value,
        order: 1,
      ),
      Category(
        id: placesId,
        name: 'أماكن',
        emoji: '🎡',
        colorValue: primaryGreen.value,
        order: 2,
      ),
      Category(
        id: gamesId,
        name: 'ألعاب',
        emoji: '🎮',
        colorValue: primaryPurple.value,
        order: 3,
      ),
      Category(
        id: tvId,
        name: 'تلفزيون وكارتون',
        emoji: '📺',
        colorValue: primaryRed.value,
        order: 4,
      ),
      Category(
        id: foodId,
        name: 'أكل وشرب',
        emoji: '🍕',
        colorValue: primaryOrange.value,
        order: 5,
      ),
      Category(
        id: peopleId,
        name: 'أشخاص',
        emoji: '👨',
        colorValue: primaryYellow.value,
        order: 6,
      ),
      Category(
        id: answersId,
        name: 'إجابات',
        emoji: '✅',
        colorValue: primaryIndigo.value,
        order: 7,
      ),
    ];
  }

  // Default Items
  static List<Item> getDefaultItems() {
    final now = DateTime.now();
    final items = <Item>[];

    // Basic Needs - احتياجات أساسية
    items.addAll([
      _createItem(basicNeedsId, 'عايز آكل', '🍽️', 0, now),
      _createItem(basicNeedsId, 'عايز أشرب', '🥤', 1, now),
      _createItem(basicNeedsId, 'عايز أنام', '😴', 2, now),
      _createItem(basicNeedsId, 'عايز حمام', '🚽', 3, now),
      _createItem(basicNeedsId, 'عايز أستحمى', '🚿', 4, now),
      _createItem(basicNeedsId, 'عايز ألبس', '👕', 5, now),
    ]);

    // Emotions - مشاعر
    items.addAll([
      _createItem(emotionsId, 'مبسوط', '😊', 0, now),
      _createItem(emotionsId, 'زعلان', '😢', 1, now),
      _createItem(emotionsId, 'تعبان', '🤒', 2, now),
      _createItem(emotionsId, 'خايف', '😰', 3, now),
      _createItem(emotionsId, 'زهقان', '😑', 4, now),
      _createItem(emotionsId, 'فرحان', '🥳', 5, now),
    ]);

    // Places - أماكن
    items.addAll([
      _createItem(placesId, 'عايز أروح الملاهي', '🎡', 0, now),
      _createItem(placesId, 'عايز أروح المطعم', '🍕', 1, now),
      _createItem(placesId, 'عايز أروح الحديقة', '🌳', 2, now),
      _createItem(placesId, 'عايز أروح عند جدو', '👴', 3, now),
      _createItem(placesId, 'عايز أروح عند تيتة', '👵', 4, now),
      _createItem(placesId, 'عايز أروح السينما', '🎬', 5, now),
      _createItem(placesId, 'عايز أروح المول', '🏬', 6, now),
      _createItem(placesId, 'عايز أروح البحر', '🏖️', 7, now),
    ]);

    // Games - ألعاب
    items.addAll([
      _createItem(gamesId, 'عايز ألعب موبايل', '📱', 0, now),
      _createItem(gamesId, 'عايز ألعب Xbox', '🎮', 1, now),
      _createItem(gamesId, 'عايز ألعب PlayStation', '🕹️', 2, now),
      _createItem(gamesId, 'عايز ألعب بالعربيات', '🚗', 3, now),
      _createItem(gamesId, 'عايز ألعب كورة', '⚽', 4, now),
      _createItem(gamesId, 'عايز ألعب بالمكعبات', '🧩', 5, now),
      _createItem(gamesId, 'عايز ألعب بالدراجة', '🚲', 6, now),
    ]);

    // TV & Cartoons - تلفزيون وكارتون
    items.addAll([
      _createItem(tvId, 'عايز أتفرج تلفزيون', '📺', 0, now),
      _createItem(tvId, 'عايز أتفرج يوتيوب', '▶️', 1, now),
      _createItem(tvId, 'عايز أتفرج كارتون', '🎬', 2, now),
      _createItem(tvId, 'عايز أسمع أغاني', '🎵', 3, now),
      _createItem(tvId, 'عايز أتفرج فيلم', '🎥', 4, now),
    ]);

    // Food & Drink - أكل وشرب
    items.addAll([
      _createItem(foodId, 'عايز بيتزا', '🍕', 0, now),
      _createItem(foodId, 'عايز برجر', '🍔', 1, now),
      _createItem(foodId, 'عايز أيس كريم', '🍦', 2, now),
      _createItem(foodId, 'عايز شوكولاتة', '🍫', 3, now),
      _createItem(foodId, 'عايز عصير', '🧃', 4, now),
      _createItem(foodId, 'عايز مياه', '💧', 5, now),
      _createItem(foodId, 'عايز فاكهة', '🍎', 6, now),
    ]);

    // People - أشخاص
    items.addAll([
      _createItem(peopleId, 'ماما', '👩', 0, now),
      _createItem(peopleId, 'بابا', '👨', 1, now),
      _createItem(peopleId, 'عايز أكون لوحدي', '🙋', 2, now),
      _createItem(peopleId, 'عايز صاحبي', '👦', 3, now),
      _createItem(peopleId, 'عايز أخويا', '👶', 4, now),
      _createItem(peopleId, 'عايز أختي', '👧', 5, now),
    ]);

    // Answers - إجابات
    items.addAll([
      _createItem(answersId, 'أيوه', '✅', 0, now),
      _createItem(answersId, 'لأ', '❌', 1, now),
      _createItem(answersId, 'مش عارف', '🤷', 2, now),
      _createItem(answersId, 'ساعدني', '🆘', 3, now),
      _createItem(answersId, 'استنى شوية', '⏰', 4, now),
      _createItem(answersId, 'خلاص كفاية', '🛑', 5, now),
    ]);

    return items;
  }

  static Item _createItem(
    String categoryId,
    String text,
    String emoji,
    int order,
    DateTime timestamp,
  ) {
    return Item(
      id: uuid.v4(),
      categoryId: categoryId,
      text: text,
      imageType: 'emoji',
      imageValue: emoji,
      createdAt: timestamp,
      updatedAt: timestamp,
      order: order,
    );
  }

  // Available Emoji Icons for Custom Items
  static const List<String> availableEmojis = [
    '😊', '😢', '😴', '🤒', '😰', '😑', '🥳', '😡',
    '🍽️', '🥤', '🚽', '🚿', '👕', '🛏️', '🧸', '📚',
    '🎡', '🍕', '🌳', '👴', '👵', '🎬', '🏬', '🏖️',
    '📱', '🎮', '🕹️', '🚗', '⚽', '🧩', '🚲', '🎨',
    '📺', '▶️', '🎵', '🎥', '📖', '🎤', '🎧', '🎹',
    '🍔', '🍦', '🍫', '🧃', '💧', '🍎', '🍌', '🥕',
    '👩', '👨', '🙋', '👦', '👧', '👶', '🧑', '👪',
    '✅', '❌', '🤷', '🆘', '⏰', '🛑', '💡', '🔔',
  ];
}
