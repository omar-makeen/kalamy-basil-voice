import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/category.dart';
import '../models/item.dart';

/// Service for syncing data with Firebase
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? _familyCode;

  /// Initialize the service with family code
  void setFamilyCode(String familyCode) {
    _familyCode = familyCode;
  }

  /// Get reference to categories collection
  CollectionReference<Map<String, dynamic>> get _categoriesCollection {
    if (_familyCode == null) {
      throw Exception('Family code not set. Call setFamilyCode() first.');
    }
    return _firestore
        .collection('families')
        .doc(_familyCode)
        .collection('categories');
  }

  /// Get reference to items collection
  CollectionReference<Map<String, dynamic>> get _itemsCollection {
    if (_familyCode == null) {
      throw Exception('Family code not set. Call setFamilyCode() first.');
    }
    return _firestore.collection('families').doc(_familyCode).collection('items');
  }

  // ==================== CATEGORY SYNC ====================

  /// Upload a category to Firestore
  Future<void> uploadCategory(Category category) async {
    try {
      await _categoriesCollection.doc(category.id).set(category.toMap());
    } catch (e) {
      print('Error uploading category: $e');
      rethrow;
    }
  }

  /// Download all categories from Firestore
  Future<List<Category>> downloadCategories() async {
    try {
      final snapshot = await _categoriesCollection.get();
      return snapshot.docs
          .map((doc) => Category.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      print('Error downloading categories: $e');
      rethrow;
    }
  }

  /// Delete a category from Firestore
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoriesCollection.doc(categoryId).delete();
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  /// Listen to category changes in real-time
  Stream<List<Category>> listenToCategories() {
    return _categoriesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Category.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    });
  }

  // ==================== ITEM SYNC ====================

  /// Upload an item to Firestore
  Future<void> uploadItem(Item item) async {
    try {
      // If item has a local image, upload it to Storage first
      if (item.imageType == 'local' && item.imageValue.startsWith('/')) {
        final imageUrl = await uploadImage(item.imageValue, item.id);
        final updatedItem = item.copyWith(
          imageType: 'network',
          imageValue: imageUrl,
        );
        await _itemsCollection.doc(updatedItem.id).set(updatedItem.toMap());
      } else {
        await _itemsCollection.doc(item.id).set(item.toMap());
      }
    } catch (e) {
      print('Error uploading item: $e');
      rethrow;
    }
  }

  /// Download all items from Firestore
  Future<List<Item>> downloadItems() async {
    try {
      final snapshot = await _itemsCollection.get();
      return snapshot.docs
          .map((doc) => Item.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      print('Error downloading items: $e');
      rethrow;
    }
  }

  /// Download items for a specific category
  Future<List<Item>> downloadItemsByCategory(String categoryId) async {
    try {
      final snapshot = await _itemsCollection
          .where('categoryId', isEqualTo: categoryId)
          .get();
      return snapshot.docs
          .map((doc) => Item.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      print('Error downloading items by category: $e');
      rethrow;
    }
  }

  /// Delete an item from Firestore
  Future<void> deleteItem(String itemId) async {
    try {
      // Get the item first to check if it has a storage image
      final doc = await _itemsCollection.doc(itemId).get();
      if (doc.exists) {
        final item = Item.fromMap(doc.data()!);
        // If item has a network image from our storage, delete it
        if (item.imageType == 'network' &&
            item.imageValue.contains('firebasestorage.googleapis.com')) {
          try {
            await deleteImage(itemId);
          } catch (e) {
            print('Error deleting image from storage: $e');
            // Continue with item deletion even if image deletion fails
          }
        }
      }
      await _itemsCollection.doc(itemId).delete();
    } catch (e) {
      print('Error deleting item: $e');
      rethrow;
    }
  }

  /// Listen to item changes in real-time
  Stream<List<Item>> listenToItems() {
    return _itemsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Item.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    });
  }

  /// Listen to items for a specific category
  Stream<List<Item>> listenToItemsByCategory(String categoryId) {
    return _itemsCollection
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Item.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    });
  }

  // ==================== IMAGE STORAGE ====================

  /// Upload an image to Firebase Storage
  Future<String> uploadImage(String localPath, String itemId) async {
    try {
      final file = File(localPath);
      final fileName = '${itemId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage
          .ref()
          .child('families')
          .child(_familyCode!)
          .child('images')
          .child(fileName);

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  /// Delete an image from Firebase Storage
  Future<void> deleteImage(String itemId) async {
    try {
      // List all files for this item
      final listRef = _storage
          .ref()
          .child('families')
          .child(_familyCode!)
          .child('images');

      final result = await listRef.listAll();
      for (var item in result.items) {
        if (item.name.startsWith(itemId)) {
          await item.delete();
        }
      }
    } catch (e) {
      print('Error deleting image: $e');
      rethrow;
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sync all local categories to Firebase
  Future<void> syncCategoriesToCloud(List<Category> categories) async {
    try {
      for (final category in categories) {
        await uploadCategory(category);
      }
    } catch (e) {
      print('Error syncing categories to cloud: $e');
      rethrow;
    }
  }

  /// Sync all local items to Firebase
  Future<void> syncItemsToCloud(List<Item> items) async {
    try {
      for (final item in items) {
        await uploadItem(item);
      }
    } catch (e) {
      print('Error syncing items to cloud: $e');
      rethrow;
    }
  }

  /// Merge cloud data with local data (conflict resolution)
  /// Returns merged categories and items
  Future<Map<String, dynamic>> mergeCloudData({
    required List<Category> localCategories,
    required List<Item> localItems,
  }) async {
    try {
      final cloudCategories = await downloadCategories();
      final cloudItems = await downloadItems();

      // Merge categories (cloud takes precedence if updatedAt is newer)
      final Map<String, Category> categoryMap = {};

      // Add local categories
      for (final cat in localCategories) {
        categoryMap[cat.id] = cat;
      }

      // Merge with cloud categories (cloud wins if same ID)
      for (final cloudCat in cloudCategories) {
        final localCat = categoryMap[cloudCat.id];
        if (localCat == null) {
          // New category from cloud
          categoryMap[cloudCat.id] = cloudCat;
        } else {
          // Use cloud version (in real app, compare timestamps)
          categoryMap[cloudCat.id] = cloudCat;
        }
      }

      // Merge items (cloud takes precedence if updatedAt is newer)
      final Map<String, Item> itemMap = {};

      // Add local items
      for (final item in localItems) {
        itemMap[item.id] = item;
      }

      // Merge with cloud items
      for (final cloudItem in cloudItems) {
        final localItem = itemMap[cloudItem.id];
        if (localItem == null) {
          // New item from cloud
          itemMap[cloudItem.id] = cloudItem;
        } else {
          // Compare timestamps - newer one wins
          if (cloudItem.updatedAt.isAfter(localItem.updatedAt)) {
            itemMap[cloudItem.id] = cloudItem;
          }
          // else keep local version
        }
      }

      return {
        'categories': categoryMap.values.toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
        'items': itemMap.values.toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
      };
    } catch (e) {
      print('Error merging cloud data: $e');
      rethrow;
    }
  }

  /// Check if Firebase is available
  Future<bool> isFirebaseAvailable() async {
    try {
      await _firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      print('Firebase not available: $e');
      return false;
    }
  }
}
