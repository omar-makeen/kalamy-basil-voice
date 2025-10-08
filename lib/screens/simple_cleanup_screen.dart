import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/item.dart';

class SimpleCleanupScreen extends StatefulWidget {
  const SimpleCleanupScreen({super.key});

  @override
  State<SimpleCleanupScreen> createState() => _SimpleCleanupScreenState();
}

class _SimpleCleanupScreenState extends State<SimpleCleanupScreen> {
  final _familyCodeController = TextEditingController(text: '2024');
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _cleanup() async {
    final familyCode = _familyCodeController.text.trim();

    if (familyCode.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter family code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Cleaning...';
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Clean items
      final itemsRef = firestore
          .collection('families')
          .doc(familyCode)
          .collection('items');

      final itemsSnapshot = await itemsRef.get();
      final itemsBefore = itemsSnapshot.docs.length;

      // Use composite key: text + categoryId + order to find TRUE duplicates
      final itemMap = <String, Map<String, dynamic>>{};
      final duplicateItemDocs = <String>[];

      for (var doc in itemsSnapshot.docs) {
        final item = Item.fromMap(doc.data());

        // Create unique key based on content (text + category + order)
        final uniqueKey = '${item.text}|${item.categoryId}|${item.order}';

        if (itemMap.containsKey(uniqueKey)) {
          // This is a duplicate! Keep the newer one
          final existing = itemMap[uniqueKey]!;
          final existingItem = existing['item'] as Item;

          if (item.updatedAt.isAfter(existingItem.updatedAt)) {
            // New item is newer - delete old document, keep new
            duplicateItemDocs.add(existing['docId'] as String);
            itemMap[uniqueKey] = {'item': item, 'docId': doc.id};
          } else {
            // Existing item is newer - delete this document
            duplicateItemDocs.add(doc.id);
          }
        } else {
          itemMap[uniqueKey] = {'item': item, 'docId': doc.id};
        }
      }

      // Delete duplicates
      for (var docId in duplicateItemDocs) {
        await itemsRef.doc(docId).delete();
      }

      // Clean categories
      final categoriesRef = firestore
          .collection('families')
          .doc(familyCode)
          .collection('categories');

      final categoriesSnapshot = await categoriesRef.get();
      final categoriesBefore = categoriesSnapshot.docs.length;

      final categoryMap = <String, Category>{};
      final duplicateCategoryDocs = <String>[];

      for (var doc in categoriesSnapshot.docs) {
        final category = Category.fromMap(doc.data());

        if (categoryMap.containsKey(category.id)) {
          duplicateCategoryDocs.add(doc.id);
        } else {
          categoryMap[category.id] = category;
        }
      }

      for (var docId in duplicateCategoryDocs) {
        await categoriesRef.doc(docId).delete();
      }

      setState(() {
        _statusMessage = '''
✅ تم التنظيف بنجاح!

الفئات:
  قبل: $categoriesBefore
  بعد: ${categoryMap.length}
  تم الحذف: ${duplicateCategoryDocs.length}

العناصر:
  قبل: $itemsBefore
  بعد: ${itemMap.length}
  تم الحذف: ${duplicateItemDocs.length}
''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تنظيف Firebase'),
          backgroundColor: Colors.orange,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _familyCodeController,
                decoration: const InputDecoration(
                  labelText: 'رمز العائلة',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _cleanup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('تنظيف البيانات المكررة', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              if (_statusMessage.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
