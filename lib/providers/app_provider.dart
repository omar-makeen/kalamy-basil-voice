import 'package:flutter/material.dart';
import 'dart:io';
import '../models/category.dart';
import '../models/item.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/image_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService;
  final TtsService _ttsService;
  final ImageService _imageService;

  List<Category> _categories = [];
  List<Item> _items = [];
  bool _isLoading = false;
  bool _isEditMode = false;

  AppProvider({
    required StorageService storageService,
    required TtsService ttsService,
    required ImageService imageService,
  })  : _storageService = storageService,
        _ttsService = ttsService,
        _imageService = imageService;

  // Getters
  List<Category> get categories => _categories;
  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  bool get isEditMode => _isEditMode;

  // Initialize
  Future<void> init() async {
    _isLoading = true;

    await _storageService.init();
    await _ttsService.init();

    loadData();

    _isLoading = false;
  }

  // Load data from storage
  void loadData() {
    _categories = _storageService.getAllCategories();
    _items = _storageService.getAllItems();
  }

  // Family Code
  bool hasFamilyCode() {
    return _storageService.hasFamilyCode();
  }

  String? getFamilyCode() {
    return _storageService.getFamilyCode();
  }

  Future<void> saveFamilyCode(String code) async {
    await _storageService.saveFamilyCode(code);
    notifyListeners();
  }

  // Categories
  Category? getCategoryById(String id) {
    return _storageService.getCategory(id);
  }

  int getItemsCountInCategory(String categoryId) {
    return _items.where((item) => item.categoryId == categoryId).length;
  }

  Future<void> addCategory(Category category) async {
    await _storageService.saveCategory(category);
    loadData();
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    await _storageService.saveCategory(category);
    loadData();
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    // Delete all items in this category first
    final itemsToDelete = _items.where((item) => item.categoryId == id).toList();
    for (var item in itemsToDelete) {
      await deleteItem(item.id);
    }

    await _storageService.deleteCategory(id);
    loadData();
    notifyListeners();
  }

  Future<void> reorderCategories(List<Category> reorderedCategories) async {
    for (int i = 0; i < reorderedCategories.length; i++) {
      final updatedCategory = reorderedCategories[i].copyWith(order: i);
      await _storageService.saveCategory(updatedCategory);
    }
    loadData();
    notifyListeners();
  }

  // Items
  List<Item> getItemsByCategory(String categoryId) {
    final items = _items.where((item) => item.categoryId == categoryId).toList();
    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }

  Item? getItemById(String id) {
    return _storageService.getItem(id);
  }

  Future<void> addItem(Item item) async {
    await _storageService.saveItem(item);
    loadData();
  }

  Future<void> updateItem(Item item) async {
    await _storageService.saveItem(item);
    loadData();
  }

  Future<void> deleteItem(String id) async {
    // Get item to check if it has a local image
    final item = getItemById(id);
    if (item != null && item.imageType == 'local') {
      await _imageService.deleteImage(item.imageValue);
    }

    await _storageService.deleteItem(id);
    loadData();
    notifyListeners();
  }

  Future<void> reorderItems(List<Item> reorderedItems) async {
    for (int i = 0; i < reorderedItems.length; i++) {
      final updatedItem = reorderedItems[i].copyWith(order: i);
      await _storageService.saveItem(updatedItem);
    }
    loadData();
    notifyListeners();
  }

  // Text-to-Speech
  Future<void> speak(String text) async {
    await _ttsService.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
  }

  // Image Picking
  Future<File?> pickImageFromCamera() async {
    return await _imageService.pickImageFromCamera();
  }

  Future<File?> pickImageFromGallery() async {
    return await _imageService.pickImageFromGallery();
  }

  // Edit Mode
  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  void setEditMode(bool value) {
    _isEditMode = value;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
