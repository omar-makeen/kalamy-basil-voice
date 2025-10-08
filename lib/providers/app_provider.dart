import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../models/category.dart';
import '../models/item.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/image_service.dart';
import '../services/firebase_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService;
  final TtsService _ttsService;
  final ImageService _imageService;
  final FirebaseService _firebaseService;

  List<Category> _categories = [];
  List<Item> _items = [];
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isSyncing = false;
  bool _autoSyncEnabled = true;
  bool _realtimeListenersEnabled = true;
  bool _isInitialLoad = false;

  // Stream subscriptions for real-time updates
  StreamSubscription<List<Category>>? _categoriesSubscription;
  StreamSubscription<List<Item>>? _itemsSubscription;

  AppProvider({
    required StorageService storageService,
    required TtsService ttsService,
    required ImageService imageService,
    required FirebaseService firebaseService,
  })  : _storageService = storageService,
        _ttsService = ttsService,
        _imageService = imageService,
        _firebaseService = firebaseService;

  // Getters
  List<Category> get categories => _categories;
  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  bool get isEditMode => _isEditMode;
  bool get isSyncing => _isSyncing;
  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get realtimeListenersEnabled => _realtimeListenersEnabled;

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
    _firebaseService.setFamilyCode(code);

    // Load data from cloud (download only, no upload)
    await loadFromCloud();

    // Start listening to real-time updates
    if (_realtimeListenersEnabled) {
      _startRealtimeListeners();
    }

    notifyListeners();
  }

  /// Load data from Firebase (download only, no upload)
  /// This is optimized for initial login - much faster than full sync
  Future<void> loadFromCloud() async {
    if (_isSyncing) return; // Prevent multiple simultaneous loads

    try {
      _isSyncing = true;
      _isInitialLoad = true; // Flag to prevent duplicate data from listeners
      notifyListeners();

      // Check if Firebase is available
      final isAvailable = await _firebaseService.isFirebaseAvailable();
      if (!isAvailable) {
        print('Firebase is not available, using local data only');
        return;
      }

      print('Loading data from Firebase (download only)...');

      // Download categories and items from Firebase
      final cloudCategories = await _firebaseService.downloadCategories();
      final cloudItems = await _firebaseService.downloadItems();

      print('Downloaded ${cloudCategories.length} categories and ${cloudItems.length} items from Firebase');

      // Save cloud data to local storage
      for (final category in cloudCategories) {
        await _storageService.saveCategory(category);
      }

      for (final item in cloudItems) {
        await _storageService.saveItem(item);
      }

      // Reload data from local storage
      loadData();
      notifyListeners();

      print('Data loaded successfully from Firebase');
      
      // Check for duplicates in loaded data
      checkForDuplicates();
    } catch (e) {
      print('Error loading from cloud: $e');
      // Don't throw - app should continue working with local data
    } finally {
      _isSyncing = false;
      _isInitialLoad = false; // Clear the initial load flag
      notifyListeners();
    }
  }

  /// Clear all local data (for testing or fixing duplicate data issues)
  Future<void> clearLocalData() async {
    try {
      print('Clearing all local data...');
      await _storageService.clearAllData();
      loadData();
      notifyListeners();
      print('Local data cleared successfully');
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  /// Debug method to check for duplicates in local data
  void checkForDuplicates() {
    print('\n🔍 Checking for duplicates in local data...');
    
    // Check categories
    final categoryMap = <String, List<Category>>{};
    for (final category in _categories) {
      final key = '${category.name}|${category.order}';
      categoryMap.putIfAbsent(key, () => []).add(category);
    }
    
    final duplicateCategories = categoryMap.entries.where((e) => e.value.length > 1).toList();
    print('📁 Categories: ${_categories.length} total');
    if (duplicateCategories.isNotEmpty) {
      print('❌ Found ${duplicateCategories.length} duplicate category groups:');
      for (final dup in duplicateCategories) {
        print('  - "${dup.key}" (${dup.value.length} copies)');
        for (final cat in dup.value) {
          print('    ID: ${cat.id}, Updated: ${cat.updatedAt}');
        }
      }
    } else {
      print('✅ No duplicate categories found');
    }
    
    // Check items
    final itemMap = <String, List<Item>>{};
    for (final item in _items) {
      final key = '${item.name}|${item.categoryId}|${item.order}';
      itemMap.putIfAbsent(key, () => []).add(item);
    }
    
    final duplicateItems = itemMap.entries.where((e) => e.value.length > 1).toList();
    print('\n📄 Items: ${_items.length} total');
    if (duplicateItems.isNotEmpty) {
      print('❌ Found ${duplicateItems.length} duplicate item groups:');
      for (final dup in duplicateItems.take(5)) { // Show first 5 groups
        print('  - "${dup.key}" (${dup.value.length} copies)');
        for (final item in dup.value.take(3)) { // Show first 3 items in each group
          print('    ID: ${item.id}, Updated: ${item.updatedAt}');
        }
        if (dup.value.length > 3) print('    ... and ${dup.value.length - 3} more');
      }
      if (duplicateItems.length > 5) {
        print('  ... and ${duplicateItems.length - 5} more duplicate groups');
      }
    } else {
      print('✅ No duplicate items found');
    }
    
    print('\n📊 Summary:');
    print('Local categories: ${_categories.length}');
    print('Local items: ${_items.length}');
    print('Duplicate category groups: ${duplicateCategories.length}');
    print('Duplicate item groups: ${duplicateItems.length}');
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

  // Sync Methods
  void toggleAutoSync() {
    _autoSyncEnabled = !_autoSyncEnabled;
    notifyListeners();
  }

  /// Sync local data with Firebase Cloud (full sync with upload)
  /// Use this for conflict resolution between devices, not for initial load
  Future<void> syncWithCloud() async {
    if (_isSyncing) return; // Prevent multiple simultaneous syncs

    try {
      _isSyncing = true;
      notifyListeners();

      // Check if Firebase is available
      final isAvailable = await _firebaseService.isFirebaseAvailable();
      if (!isAvailable) {
        print('Firebase is not available, skipping sync');
        return;
      }

      // Merge cloud and local data
      final mergedData = await _firebaseService.mergeCloudData(
        localCategories: _categories,
        localItems: _items,
      );

      final mergedCategories = mergedData['categories'] as List<Category>;
      final mergedItems = mergedData['items'] as List<Item>;

      // Save merged data to local storage
      for (final category in mergedCategories) {
        await _storageService.saveCategory(category);
      }

      for (final item in mergedItems) {
        await _storageService.saveItem(item);
      }

      // Upload local data to cloud
      await _firebaseService.syncCategoriesToCloud(mergedCategories);
      await _firebaseService.syncItemsToCloud(mergedItems);

      // Reload data
      loadData();
      notifyListeners();

      print('Sync completed successfully');
    } catch (e) {
      print('Error syncing with cloud: $e');
      // Don't throw - app should continue working offline
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Trigger sync after data changes (if auto-sync is enabled)
  Future<void> _autoSync() async {
    if (_autoSyncEnabled && getFamilyCode() != null) {
      // Run sync in background without waiting
      syncWithCloud().catchError((e) {
        print('Auto-sync failed: $e');
      });
    }
  }

  // Update all CRUD methods to trigger auto-sync
  Future<void> addCategoryWithSync(Category category) async {
    await addCategory(category);
    await _autoSync();
  }

  Future<void> updateCategoryWithSync(Category category) async {
    await updateCategory(category);
    await _autoSync();
  }

  Future<void> deleteCategoryWithSync(String id) async {
    await deleteCategory(id);
    await _autoSync();
  }

  Future<void> addItemWithSync(Item item) async {
    await addItem(item);
    await _autoSync();
  }

  Future<void> updateItemWithSync(Item item) async {
    await updateItem(item);
    await _autoSync();
  }

  Future<void> deleteItemWithSync(String id) async {
    await deleteItem(id);
    await _autoSync();
  }

  // Real-time Listeners
  void _startRealtimeListeners() {
    if (getFamilyCode() == null) return;

    try {
      print('Starting real-time listeners for family: ${getFamilyCode()}');

      // Listen to category changes
      _categoriesSubscription = _firebaseService.listenToCategories().listen(
        (cloudCategories) {
          print('Received ${cloudCategories.length} categories from Firebase');
          _handleCategoriesUpdate(cloudCategories);
        },
        onError: (error) {
          print('Error listening to categories: $error');
        },
      );

      // Listen to item changes
      _itemsSubscription = _firebaseService.listenToItems().listen(
        (cloudItems) {
          print('Received ${cloudItems.length} items from Firebase');
          _handleItemsUpdate(cloudItems);
        },
        onError: (error) {
          print('Error listening to items: $error');
        },
      );
    } catch (e) {
      print('Error starting real-time listeners: $e');
    }
  }

  void _stopRealtimeListeners() {
    _categoriesSubscription?.cancel();
    _itemsSubscription?.cancel();
    _categoriesSubscription = null;
    _itemsSubscription = null;
    print('Real-time listeners stopped');
  }

  void toggleRealtimeListeners() {
    _realtimeListenersEnabled = !_realtimeListenersEnabled;
    if (_realtimeListenersEnabled && getFamilyCode() != null) {
      _startRealtimeListeners();
    } else {
      _stopRealtimeListeners();
    }
    notifyListeners();
  }

  // Handle real-time updates from Firebase
  Future<void> _handleCategoriesUpdate(List<Category> cloudCategories) async {
    try {
      // Skip if this is the initial load to prevent duplicate data
      if (_isInitialLoad) {
        print('Skipping categories update during initial load');
        return;
      }

      // Skip if we already have the same number of categories (likely initial data)
      if (_categories.length == cloudCategories.length) {
        print('Skipping categories update - same count as current data');
        return;
      }

      print('Processing ${cloudCategories.length} categories from real-time update');
      
      // Save all cloud categories to local storage
      for (final category in cloudCategories) {
        await _storageService.saveCategory(category);
      }

      // Reload local data
      loadData();
      notifyListeners();
    } catch (e) {
      print('Error handling categories update: $e');
    }
  }

  Future<void> _handleItemsUpdate(List<Item> cloudItems) async {
    try {
      // Skip if this is the initial load to prevent duplicate data
      if (_isInitialLoad) {
        print('Skipping items update during initial load');
        return;
      }

      // Skip if we already have the same number of items (likely initial data)
      if (_items.length == cloudItems.length) {
        print('Skipping items update - same count as current data');
        return;
      }

      print('Processing ${cloudItems.length} items from real-time update');
      
      // Save all cloud items to local storage
      for (final item in cloudItems) {
        await _storageService.saveItem(item);
      }

      // Reload local data
      loadData();
      notifyListeners();
    } catch (e) {
      print('Error handling items update: $e');
    }
  }

  // Dispose
  @override
  void dispose() {
    _stopRealtimeListeners();
    _ttsService.dispose();
    super.dispose();
  }
}
