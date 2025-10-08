import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/item.dart';

/// Utility class to clean up duplicate data in Firebase
class FirebaseCleanup {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Remove all duplicate items and categories for a family
  Future<Map<String, dynamic>> cleanupFamily(String familyCode) async {
    print('Starting cleanup for family: $familyCode');

    final results = {
      'categoriesBefore': 0,
      'categoriesAfter': 0,
      'categoriesRemoved': 0,
      'itemsBefore': 0,
      'itemsAfter': 0,
      'itemsRemoved': 0,
    };

    try {
      // Clean categories
      final categoriesRef = _firestore
          .collection('families')
          .doc(familyCode)
          .collection('categories');

      final categoriesSnapshot = await categoriesRef.get();
      results['categoriesBefore'] = categoriesSnapshot.docs.length;

      // Find duplicates by ID
      final categoryMap = <String, Category>{};
      final duplicateCategoryDocs = <QueryDocumentSnapshot>[];

      for (var doc in categoriesSnapshot.docs) {
        final category = Category.fromMap(doc.data());

        if (categoryMap.containsKey(category.id)) {
          // Duplicate found
          print('Duplicate category found: ${category.name} (${category.id})');
          duplicateCategoryDocs.add(doc);
        } else {
          categoryMap[category.id] = category;
        }
      }

      // Delete duplicate category documents
      for (var doc in duplicateCategoryDocs) {
        await doc.reference.delete();
        print('Deleted duplicate category document');
      }

      results['categoriesRemoved'] = duplicateCategoryDocs.length;
      results['categoriesAfter'] = categoryMap.length;

      // Clean items
      final itemsRef = _firestore
          .collection('families')
          .doc(familyCode)
          .collection('items');

      final itemsSnapshot = await itemsRef.get();
      results['itemsBefore'] = itemsSnapshot.docs.length;

      // Find duplicates by ID
      final itemMap = <String, Item>{};
      final duplicateItemDocs = <QueryDocumentSnapshot>[];

      for (var doc in itemsSnapshot.docs) {
        final item = Item.fromMap(doc.data());

        if (itemMap.containsKey(item.id)) {
          // Duplicate found
          print('Duplicate item found: ${item.text} (${item.id})');
          duplicateItemDocs.add(doc);
        } else {
          itemMap[item.id] = item;
        }
      }

      // Delete duplicate item documents
      for (var doc in duplicateItemDocs) {
        await doc.reference.delete();
        print('Deleted duplicate item document');
      }

      results['itemsRemoved'] = duplicateItemDocs.length;
      results['itemsAfter'] = itemMap.length;

      print('Cleanup completed!');
      print('Categories: ${results['categoriesBefore']} -> ${results['categoriesAfter']} (removed ${results['categoriesRemoved']})');
      print('Items: ${results['itemsBefore']} -> ${results['itemsAfter']} (removed ${results['itemsRemoved']})');

      return results;
    } catch (e) {
      print('Error during cleanup: $e');
      rethrow;
    }
  }

  /// Ensure all items and categories use document ID = item/category ID
  Future<void> normalizeDocumentIds(String familyCode) async {
    print('Normalizing document IDs for family: $familyCode');

    try {
      // Normalize categories
      final categoriesRef = _firestore
          .collection('families')
          .doc(familyCode)
          .collection('categories');

      final categoriesSnapshot = await categoriesRef.get();

      for (var doc in categoriesSnapshot.docs) {
        final category = Category.fromMap(doc.data());

        // If document ID doesn't match category ID, fix it
        if (doc.id != category.id) {
          print('Fixing category document ID: ${doc.id} -> ${category.id}');

          // Create new document with correct ID
          await categoriesRef.doc(category.id).set(category.toMap());

          // Delete old document
          await doc.reference.delete();
        }
      }

      // Normalize items
      final itemsRef = _firestore
          .collection('families')
          .doc(familyCode)
          .collection('items');

      final itemsSnapshot = await itemsRef.get();

      for (var doc in itemsSnapshot.docs) {
        final item = Item.fromMap(doc.data());

        // If document ID doesn't match item ID, fix it
        if (doc.id != item.id) {
          print('Fixing item document ID: ${doc.id} -> ${item.id}');

          // Create new document with correct ID
          await itemsRef.doc(item.id).set(item.toMap());

          // Delete old document
          await doc.reference.delete();
        }
      }

      print('Document ID normalization completed!');
    } catch (e) {
      print('Error during normalization: $e');
      rethrow;
    }
  }

  /// Get statistics for a family
  Future<Map<String, dynamic>> getFamilyStats(String familyCode) async {
    try {
      final categoriesSnapshot = await _firestore
          .collection('families')
          .doc(familyCode)
          .collection('categories')
          .get();

      final itemsSnapshot = await _firestore
          .collection('families')
          .doc(familyCode)
          .collection('items')
          .get();

      return {
        'totalCategories': categoriesSnapshot.docs.length,
        'totalItems': itemsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting stats: $e');
      rethrow;
    }
  }
}
