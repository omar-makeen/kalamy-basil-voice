import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../models/category.dart';
import '../models/item.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/image_service.dart';
import '../services/firebase_service.dart';
import '../services/audio_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService;
  final TtsService _ttsService;
  final ImageService _imageService;
  final FirebaseService _firebaseService;
  final AudioService _audioService;

  List<Category> _categories = [];
  List<Item> _items = [];
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isSyncing = false;
  bool _autoSyncEnabled = true;
  bool _realtimeListenersEnabled = true;
  bool _isInitialLoad = false;
  bool _isDeleting = false; // Flag to prevent real-time listeners from overriding deletions

  // Stream subscriptions for real-time updates
  StreamSubscription<List<Category>>? _categoriesSubscription;
  StreamSubscription<List<Item>>? _itemsSubscription;

  AppProvider({
    required StorageService storageService,
    required TtsService ttsService,
    required ImageService imageService,
    required FirebaseService firebaseService,
    required AudioService audioService,
  })  : _storageService = storageService,
        _ttsService = ttsService,
        _imageService = imageService,
        _firebaseService = firebaseService,
        _audioService = audioService;

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

    // Set family code in Firebase service if it exists
    final familyCode = getFamilyCode();
    if (familyCode != null) {
      _firebaseService.setFamilyCode(familyCode);

      // Start real-time listeners if enabled
      if (_realtimeListenersEnabled) {
        _startRealtimeListeners();
      }
    }

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

      // Clear existing local data first without reseeding defaults
      print('Clearing local storage before loading from Firebase...');
      await _storageService.clearDataWithoutDefaults();

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
      await _storageService.clearDataWithoutDefaults();
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
          print('    ID: ${cat.id}, Name: ${cat.name}');
        }
      }
    } else {
      print('✅ No duplicate categories found');
    }
    
    // Check items
    final itemMap = <String, List<Item>>{};
    for (final item in _items) {
      final key = '${item.text}|${item.categoryId}|${item.order}';
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
    // Push ordering to Firestore so other devices reflect changes
    try {
      final toSync = [
        for (int i = 0; i < reorderedCategories.length; i++)
          reorderedCategories[i].copyWith(order: i)
      ];
      await _firebaseService.updateCategoriesOrder(toSync);
    } catch (_) {}
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
    _isDeleting = true; // Set flag to prevent real-time listener interference
    
    // Get item to check if it has a local image
    final item = getItemById(id);
    if (item != null && item.imageType == 'local') {
      await _imageService.deleteImage(item.imageValue);
    }

    await _storageService.deleteItem(id);
    loadData();
    notifyListeners();
    
    // Clear flag after a short delay to allow Firebase sync to complete
    Future.delayed(const Duration(seconds: 2), () {
      _isDeleting = false;
    });
  }

  Future<void> reorderItems(List<Item> reorderedItems) async {
    // Save new order locally first
    final updated = <Item>[];
    for (int i = 0; i < reorderedItems.length; i++) {
      final updatedItem = reorderedItems[i].copyWith(order: i);
      updated.add(updatedItem);
      await _storageService.saveItem(updatedItem);
    }
    // Sync ordering to Firestore (best-effort)
    try {
      await _firebaseService.updateItemsOrder(updated);
    } catch (_) {}
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
    try {
      // Save to local storage
      await _storageService.saveCategory(category);
      
      // Upload to Firebase
      await _firebaseService.uploadCategory(category);
      
      loadData();
      notifyListeners();
      
      print('Category added successfully to both local and Firebase');
    } catch (e) {
      print('Error adding category with sync: $e');
      rethrow;
    }
  }

  Future<void> updateCategoryWithSync(Category category) async {
    try {
      // Save to local storage
      await _storageService.saveCategory(category);
      
      // Upload to Firebase
      await _firebaseService.uploadCategory(category);
      
      loadData();
      notifyListeners();
      
      print('Category updated successfully to both local and Firebase');
    } catch (e) {
      print('Error updating category with sync: $e');
      rethrow;
    }
  }

  Future<void> deleteCategoryWithSync(String id) async {
    _isDeleting = true; // Set flag to prevent real-time listener interference
    
    try {
      // Delete all items in this category first
      final itemsToDelete = _items.where((item) => item.categoryId == id).toList();
      for (var item in itemsToDelete) {
        await _storageService.deleteItem(item.id);
        await _firebaseService.deleteItem(item.id);
      }

      // Delete category from local storage
      await _storageService.deleteCategory(id);
      
      // Delete category from Firebase
      await _firebaseService.deleteCategory(id);
      
      loadData();
      notifyListeners();
      
      print('Category deleted successfully from both local and Firebase');
    } catch (e) {
      print('Error deleting category with sync: $e');
    } finally {
      // Clear flag after a short delay to allow Firebase sync to complete
      Future.delayed(const Duration(seconds: 2), () {
        _isDeleting = false;
      });
    }
  }

  Future<void> addItemWithSync(Item item) async {
    try {
      // Save to local storage
      await _storageService.saveItem(item);
      
      // Upload to Firebase
      await _firebaseService.uploadItem(item);
      
      loadData();
      notifyListeners();
      
      print('Item added successfully to both local and Firebase');
    } catch (e) {
      print('Error adding item with sync: $e');
      rethrow;
    }
  }

  Future<void> updateItemWithSync(Item item) async {
    try {
      // Save to local storage
      await _storageService.saveItem(item);
      
      // Upload to Firebase
      await _firebaseService.uploadItem(item);
      
      loadData();
      notifyListeners();
      
      print('Item updated successfully to both local and Firebase');
    } catch (e) {
      print('Error updating item with sync: $e');
      rethrow;
    }
  }

  Future<void> deleteItemWithSync(String id) async {
    _isDeleting = true; // Set flag to prevent real-time listener interference
    
    try {
      // Get item to check if it has a local image
      final item = getItemById(id);
      if (item != null && item.imageType == 'local') {
        await _imageService.deleteImage(item.imageValue);
      }

      // Delete from local storage
      await _storageService.deleteItem(id);
      
      // Delete from Firebase
      await _firebaseService.deleteItem(id);
      
      loadData();
      notifyListeners();
      
      print('Item deleted successfully from both local and Firebase');
    } catch (e) {
      print('Error deleting item with sync: $e');
    } finally {
      // Clear flag after a short delay to allow Firebase sync to complete
      Future.delayed(const Duration(seconds: 2), () {
        _isDeleting = false;
      });
    }
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

      print('Processing ${cloudCategories.length} categories from real-time update');

      // Get current local categories
      final localCategories = _storageService.getAllCategories();
      final cloudCategoryIds = cloudCategories.map((cat) => cat.id).toSet();

      // Delete categories that exist locally but not in cloud (were deleted elsewhere)
      for (final localCategory in localCategories) {
        if (!cloudCategoryIds.contains(localCategory.id)) {
          print('Deleting category ${localCategory.id} - not in cloud');
          await _storageService.deleteCategory(localCategory.id);
        }
      }

      // Update/add all cloud categories - Hive will replace by ID (no duplicates)
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

      // Skip if we're currently deleting items to prevent interference
      if (_isDeleting) {
        print('Skipping items update - deletion in progress');
        return;
      }

      print('Processing ${cloudItems.length} items from real-time update');

      // Get current local items
      final localItems = _storageService.getAllItems();
      final cloudItemIds = cloudItems.map((item) => item.id).toSet();

      // Delete items that exist locally but not in cloud (were deleted elsewhere)
      for (final localItem in localItems) {
        if (!cloudItemIds.contains(localItem.id)) {
          print('Deleting item ${localItem.id} - not in cloud');
          await _storageService.deleteItem(localItem.id);
        }
      }

      // Update/add all cloud items - Hive will replace by ID (no duplicates)
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

  // Audio Recording & Playback Methods
  AudioService get audioService => _audioService;

  bool get isRecording => _audioService.isRecording;
  bool get isPlayingAudio => _audioService.isPlaying;

  Future<String?> startRecording() async {
    return await _audioService.startRecording();
  }

  Future<String?> stopRecording() async {
    return await _audioService.stopRecording();
  }

  Future<void> cancelRecording() async {
    await _audioService.cancelRecording();
  }

  Future<void> playAudio(String path) async {
    await _audioService.playAudio(path);
  }

  Future<void> stopAudio() async {
    await _audioService.stopAudio();
  }

  Future<String?> uploadAudio(String localPath, String itemId) async {
    final familyCode = getFamilyCode();
    if (familyCode == null) return null;
    return await _audioService.uploadAudio(localPath, itemId, familyCode);
  }

  Future<String?> downloadAudio(String downloadUrl, String itemId) async {
    return await _audioService.downloadAudio(downloadUrl, itemId);
  }

  Future<void> deleteAudio(String? localPath, String itemId) async {
    final familyCode = getFamilyCode();

    // Delete local audio if path is provided
    if (localPath != null) {
      await _audioService.deleteLocalAudio(localPath);
    }

    // Delete Firebase audio if family code exists
    if (familyCode != null) {
      await _audioService.deleteFirebaseAudio(itemId, familyCode);
    }
  }

  // Dispose
  @override
  void dispose() {
    _stopRealtimeListeners();
    _ttsService.dispose();
    _audioService.dispose();
    super.dispose();
  }
}
