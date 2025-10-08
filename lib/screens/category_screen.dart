import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../providers/app_provider.dart';
import 'add_edit_item_screen.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;

  const CategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool _showEncouragement = false;

  Future<void> _handleItemTap(Item item) async {
    final appProvider = context.read<AppProvider>();

    // Speak the text
    await appProvider.speak(item.speechText);

    // Show encouragement message
    setState(() => _showEncouragement = true);

    // Hide after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _showEncouragement = false);
    }
  }

  void _toggleEditMode() {
    final appProvider = context.read<AppProvider>();
    appProvider.toggleEditMode();
  }

  Future<void> _deleteItem(Item item) async {
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
            'هل أنت متأكد من حذف "${item.text}"؟',
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
      await context.read<AppProvider>().deleteItem(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FF),
        appBar: AppBar(
          backgroundColor: Color(widget.category.colorValue),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Turn off edit mode when leaving
              context.read<AppProvider>().setEditMode(false);
              Navigator.pop(context);
            },
          ),
          title: Text(
            widget.category.name,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            Consumer<AppProvider>(
              builder: (context, appProvider, _) {
                return IconButton(
                  icon: Icon(
                    appProvider.isEditMode ? Icons.check : Icons.settings,
                    color: Colors.white,
                  ),
                  onPressed: _toggleEditMode,
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Consumer<AppProvider>(
              builder: (context, appProvider, _) {
                final items = appProvider.getItemsByCategory(widget.category.id);

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '📭',
                          style: const TextStyle(fontSize: 60),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد عناصر بعد',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            color: const Color(0xFF7F8C8D),
                          ),
                        ),
                        if (appProvider.isEditMode) ...[
                          const SizedBox(height: 8),
                          Text(
                            'اضغط على + لإضافة عنصر',
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

                if (appProvider.isEditMode) {
                  // Reorderable list in edit mode
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final reorderedItems = List<Item>.from(items);
                      final item = reorderedItems.removeAt(oldIndex);
                      reorderedItems.insert(newIndex, item);
                      await appProvider.reorderItems(reorderedItems);
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ItemCard(
                        key: ValueKey(item.id),
                        item: item,
                        categoryColor: Color(widget.category.colorValue),
                        isEditMode: appProvider.isEditMode,
                        onTap: () => _handleItemTap(item),
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditItemScreen(
                                category: widget.category,
                                item: item,
                              ),
                            ),
                          );
                        },
                        onDelete: () => _deleteItem(item),
                      );
                    },
                  );
                } else {
                  // Grid view in normal mode
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ItemCard(
                        item: item,
                        categoryColor: Color(widget.category.colorValue),
                        isEditMode: appProvider.isEditMode,
                        onTap: () => _handleItemTap(item),
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditItemScreen(
                                category: widget.category,
                                item: item,
                              ),
                            ),
                          );
                        },
                        onDelete: () => _deleteItem(item),
                      );
                    },
                  );
                }
              },
            ),

            // Encouragement Overlay
            if (_showEncouragement)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 60)),
                          const SizedBox(height: 16),
                          Text(
                            'أحسنت!',
                            style: GoogleFonts.cairo(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF27AE60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: Consumer<AppProvider>(
          builder: (context, appProvider, _) {
            if (!appProvider.isEditMode) return const SizedBox.shrink();

            return FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditItemScreen(
                      category: widget.category,
                    ),
                  ),
                );
              },
              backgroundColor: const Color(0xFF27AE60),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'إضافة عنصر',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  final Color categoryColor;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    super.key,
    required this.item,
    required this.categoryColor,
    required this.isEditMode,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildImage() {
    if (item.imageType == 'emoji') {
      return Text(
        item.imageValue,
        style: const TextStyle(fontSize: 60),
      );
    } else if (item.imageType == 'local') {
      final file = File(item.imageValue);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // network image
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          item.imageValue,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEditMode) {
      // List tile view for edit mode with reordering
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
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
                  color: const Color(0xFFF5F9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _buildImageSmall(),
                ),
              ),
            ],
          ),
          title: Text(
            item.text,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

    // Grid card view for normal mode
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildImage(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  item.text,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSmall() {
    if (item.imageType == 'emoji') {
      return Text(
        item.imageValue,
        style: const TextStyle(fontSize: 32),
      );
    } else if (item.imageType == 'local') {
      final file = File(item.imageValue);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          item.imageValue,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    }
  }
}

class _EditButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EditButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
