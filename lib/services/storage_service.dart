import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../utils/constants.dart';

class StorageService {
  static const String _categoriesBox = 'categories';
  static const String _itemsBox = 'items';
  static const String _settingsBox = 'settings';
  static const String _familyCodeKey = 'family_code';
  static const String _isInitializedKey = 'is_initialized';

  late Box<Category> _categoriesBoxInstance;
  late Box<Item> _itemsBoxInstance;
  late Box _settingsBoxInstance;

  // Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ItemAdapter());
    }

    // Open boxes
    _categoriesBoxInstance = await Hive.openBox<Category>(_categoriesBox);
    _itemsBoxInstance = await Hive.openBox<Item>(_itemsBox);
    _settingsBoxInstance = await Hive.openBox(_settingsBox);

    // Initialize with default data if first time
    await _initializeDefaultData();
  }

  // Initialize default data
  Future<void> _initializeDefaultData() async {
    final isInitialized = _settingsBoxInstance.get(_isInitializedKey, defaultValue: false);

    if (!isInitialized) {
      // Add default categories
      final categories = AppConstants.getDefaultCategories();
      for (var category in categories) {
        await _categoriesBoxInstance.put(category.id, category);
      }

      // Add default items
      final items = AppConstants.getDefaultItems();
      for (var item in items) {
        await _itemsBoxInstance.put(item.id, item);
      }

      // Mark as initialized
      await _settingsBoxInstance.put(_isInitializedKey, true);
    }
  }

  // Family Code
  Future<void> saveFamilyCode(String code) async {
    await _settingsBoxInstance.put(_familyCodeKey, code);
  }

  String? getFamilyCode() {
    return _settingsBoxInstance.get(_familyCodeKey);
  }

  bool hasFamilyCode() {
    return _settingsBoxInstance.containsKey(_familyCodeKey);
  }

  // Categories
  List<Category> getAllCategories() {
    final categories = _categoriesBoxInstance.values.toList();
    categories.sort((a, b) => a.order.compareTo(b.order));
    return categories;
  }

  Category? getCategory(String id) {
    return _categoriesBoxInstance.get(id);
  }

  Future<void> saveCategory(Category category) async {
    await _categoriesBoxInstance.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await _categoriesBoxInstance.delete(id);
  }

  // Items
  List<Item> getAllItems() {
    return _itemsBoxInstance.values.toList();
  }

  List<Item> getItemsByCategory(String categoryId) {
    final items = _itemsBoxInstance.values
        .where((item) => item.categoryId == categoryId)
        .toList();
    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }

  Item? getItem(String id) {
    return _itemsBoxInstance.get(id);
  }

  Future<void> saveItem(Item item) async {
    await _itemsBoxInstance.put(item.id, item);
  }

  Future<void> deleteItem(String id) async {
    await _itemsBoxInstance.delete(id);
  }

  int getItemsCountInCategory(String categoryId) {
    return _itemsBoxInstance.values
        .where((item) => item.categoryId == categoryId)
        .length;
  }

  // Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    await _categoriesBoxInstance.clear();
    await _itemsBoxInstance.clear();
    await _settingsBoxInstance.clear();
    await _initializeDefaultData();
  }

  // Clear only categories and items without reseeding defaults or touching settings
  Future<void> clearDataWithoutDefaults() async {
    await _categoriesBoxInstance.clear();
    await _itemsBoxInstance.clear();
  }

  // Close boxes
  Future<void> close() async {
    await _categoriesBoxInstance.close();
    await _itemsBoxInstance.close();
    await _settingsBoxInstance.close();
  }
}
