import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/category.dart';
import 'category_screen.dart';
import 'add_edit_category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isEditMode = false;

  void _toggleEditMode() {
    setState(() => _isEditMode = !_isEditMode);
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'تأكيد الحذف',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'هل أنت متأكد من حذف قسم "${category.name}"؟\nسيتم حذف جميع العناصر بداخله.',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(
                'حذف',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AppProvider>().deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4A90E2),
          elevation: 0,
          title: Text(
            'كلامي - عالم باسل',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _isEditMode ? Icons.check : Icons.settings,
                color: Colors.white,
              ),
              onPressed: _toggleEditMode,
            ),
          ],
        ),
        body: SafeArea(
          child: Consumer<AppProvider>(
            builder: (context, appProvider, _) {
              final categories = appProvider.categories;

              if (categories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📂', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد أقسام بعد',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          color: const Color(0xFF7F8C8D),
                        ),
                      ),
                      if (_isEditMode) ...[
                        const SizedBox(height: 8),
                        Text(
                          'اضغط على + لإضافة قسم',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: const Color(0xFF95A5A6),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              if (_isEditMode) {
                // Reorderable list in edit mode
                return ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final items = List<Category>.from(categories);
                    final item = items.removeAt(oldIndex);
                    items.insert(newIndex, item);
                    await appProvider.reorderCategories(items);
                  },
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryCardEditable(
                      key: ValueKey(category.id),
                      category: category,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditCategoryScreen(
                              category: category,
                            ),
                          ),
                        );
                      },
                      onDelete: () => _deleteCategory(category),
                    );
                  },
                );
              } else {
                // Normal grid view
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryCard(category: category);
                  },
                );
              }
            },
          ),
        ),
        floatingActionButton: _isEditMode
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddEditCategoryScreen(),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF27AE60),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'إضافة قسم',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final itemCount = appProvider.getItemsCountInCategory(category.id);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(category.colorValue).withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Color(category.colorValue).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(category.colorValue).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                category.name,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),

            // Item Count
            Text(
              '$itemCount عنصر',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: const Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCardEditable extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCardEditable({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final itemCount = appProvider.getItemsCountInCategory(category.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(category.colorValue).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(category.colorValue).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle, color: Color(0xFF95A5A6)),
            const SizedBox(width: 12),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          category.name,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
        subtitle: Text(
          '$itemCount عنصر',
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: const Color(0xFF7F8C8D),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
