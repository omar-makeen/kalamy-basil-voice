// Run this script to clean Firebase duplicates
// Usage: dart cleanup_firebase.dart YOUR_FAMILY_CODE

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';
import 'lib/models/category.dart';
import 'lib/models/item.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Error: Please provide your family code');
    print('Usage: dart cleanup_firebase.dart YOUR_FAMILY_CODE');
    print('Example: dart cleanup_firebase.dart 1234');
    return;
  }

  final familyCode = args[0];
  print('🔧 Cleaning Firebase duplicates for family: $familyCode\n');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  try {
    // Clean Categories
    print('📁 Cleaning categories...');
    final categoriesRef = firestore
        .collection('families')
        .doc(familyCode)
        .collection('categories');

    final categoriesSnapshot = await categoriesRef.get();
    print('   Found ${categoriesSnapshot.docs.length} category documents');

    final categoryMap = <String, Category>{};
    final duplicateCategoryDocs = <String>[];

    for (var doc in categoriesSnapshot.docs) {
      try {
        final category = Category.fromMap(doc.data());

        if (categoryMap.containsKey(category.id)) {
          // Duplicate found
          print('   ❌ Duplicate: ${category.name} (${category.id})');
          duplicateCategoryDocs.add(doc.id);
        } else {
          categoryMap[category.id] = category;
          print('   ✅ Keep: ${category.name}');
        }
      } catch (e) {
        print('   ⚠️  Error parsing document ${doc.id}: $e');
      }
    }

    // Delete duplicate category documents
    for (var docId in duplicateCategoryDocs) {
      await categoriesRef.doc(docId).delete();
      print('   🗑️  Deleted duplicate document: $docId');
    }

    print('   ✅ Categories cleaned: ${categoryMap.length} unique, ${duplicateCategoryDocs.length} duplicates removed\n');

    // Clean Items
    print('📄 Cleaning items...');
    final itemsRef = firestore
        .collection('families')
        .doc(familyCode)
        .collection('items');

    final itemsSnapshot = await itemsRef.get();
    print('   Found ${itemsSnapshot.docs.length} item documents');

    final itemMap = <String, Item>{};
    final duplicateItemDocs = <String>[];

    for (var doc in itemsSnapshot.docs) {
      try {
        final item = Item.fromMap(doc.data());

        if (itemMap.containsKey(item.id)) {
          // Duplicate found
          print('   ❌ Duplicate: ${item.text} (${item.id})');
          duplicateItemDocs.add(doc.id);
        } else {
          itemMap[item.id] = item;
        }
      } catch (e) {
        print('   ⚠️  Error parsing document ${doc.id}: $e');
      }
    }

    // Delete duplicate item documents
    for (var docId in duplicateItemDocs) {
      await itemsRef.doc(docId).delete();
    }

    print('   ✅ Items cleaned: ${itemMap.length} unique, ${duplicateItemDocs.length} duplicates removed\n');

    // Summary
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ Cleanup completed successfully!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Categories: ${categoriesSnapshot.docs.length} → ${categoryMap.length} (removed ${duplicateCategoryDocs.length})');
    print('Items: ${itemsSnapshot.docs.length} → ${itemMap.length} (removed ${duplicateItemDocs.length})');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  } catch (e) {
    print('❌ Error during cleanup: $e');
  }
}
