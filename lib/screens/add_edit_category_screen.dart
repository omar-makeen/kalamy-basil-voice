import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category; // Null for add, non-null for edit

  const AddEditCategoryScreen({
    super.key,
    this.category,
  });

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _uuid = const Uuid();

  String _selectedEmoji = '😊';
  int _selectedColorValue = AppConstants.primaryBlue.value;
  bool _isLoading = false;

  // Available colors
  final List<Color> _availableColors = [
    AppConstants.primaryBlue,
    AppConstants.primaryPink,
    AppConstants.primaryGreen,
    AppConstants.primaryPurple,
    AppConstants.primaryRed,
    AppConstants.primaryOrange,
    AppConstants.primaryYellow,
    AppConstants.primaryIndigo,
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF009688), // Teal
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF795548), // Brown
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedEmoji = widget.category!.emoji;
      _selectedColorValue = widget.category!.colorValue;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final appProvider = context.read<AppProvider>();

    // Calculate order
    int order = 0;
    if (widget.category != null) {
      order = widget.category!.order;
    } else {
      final categories = appProvider.categories;
      order = categories.isEmpty ? 0 : categories.length;
    }

    final category = Category(
      id: widget.category?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      emoji: _selectedEmoji,
      colorValue: _selectedColorValue,
      order: order,
    );

    if (widget.category != null) {
      await appProvider.updateCategoryWithSync(category);
    } else {
      await appProvider.addCategoryWithSync(category);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FF),
        appBar: AppBar(
          backgroundColor: Color(_selectedColorValue),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEdit ? 'تعديل قسم' : 'إضافة قسم جديد',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Name Input
              _SectionTitle(title: 'اسم القسم'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.cairo(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'مثلاً: أنشطة',
                  hintStyle: GoogleFonts.cairo(
                    color: const Color(0xFFBDC3C7),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم القسم';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Emoji Selection
              _SectionTitle(title: 'الأيقونة'),
              const SizedBox(height: 12),

              // Preview
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _selectedEmoji,
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Emoji Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: AppConstants.availableEmojis.length,
                  itemBuilder: (context, index) {
                    final emoji = AppConstants.availableEmojis[index];
                    final isSelected = _selectedEmoji == emoji;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmoji = emoji),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(_selectedColorValue).withOpacity(0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: Color(_selectedColorValue),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Color Selection
              _SectionTitle(title: 'اللون'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableColors.map((color) {
                    final isSelected = _selectedColorValue == color.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorValue = color.value),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: Colors.black,
                                  width: 3,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 30,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'حفظ',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2C3E50),
      ),
    );
  }
}
