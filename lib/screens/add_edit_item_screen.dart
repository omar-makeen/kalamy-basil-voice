import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class AddEditItemScreen extends StatefulWidget {
  final Category category;
  final Item? item; // Null for add, non-null for edit

  const AddEditItemScreen({
    super.key,
    required this.category,
    this.item,
  });

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _speechController = TextEditingController();
  final _uuid = const Uuid();

  String _imageType = 'emoji'; // 'emoji', 'local', 'network'
  String _imageValue = '😊';
  File? _selectedFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _textController.text = widget.item!.text;
      _speechController.text = widget.item!.customSpeechText ?? '';
      _imageType = widget.item!.imageType;
      _imageValue = widget.item!.imageValue;
      if (_imageType == 'local') {
        _selectedFile = File(_imageValue);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _speechController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    final appProvider = context.read<AppProvider>();
    final file = await appProvider.pickImageFromCamera();

    if (file != null) {
      setState(() {
        _imageType = 'local';
        _imageValue = file.path;
        _selectedFile = file;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final appProvider = context.read<AppProvider>();
    final file = await appProvider.pickImageFromGallery();

    if (file != null) {
      setState(() {
        _imageType = 'local';
        _imageValue = file.path;
        _selectedFile = file;
      });
    }
  }

  void _selectEmoji(String emoji) {
    setState(() {
      _imageType = 'emoji';
      _imageValue = emoji;
      _selectedFile = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final appProvider = context.read<AppProvider>();
    final now = DateTime.now();

    // Calculate order
    int order = 0;
    if (widget.item != null) {
      order = widget.item!.order;
    } else {
      final items = appProvider.getItemsByCategory(widget.category.id);
      order = items.isEmpty ? 0 : items.length;
    }

    final item = Item(
      id: widget.item?.id ?? _uuid.v4(),
      categoryId: widget.category.id,
      text: _textController.text.trim(),
      customSpeechText: _speechController.text.trim().isEmpty
          ? null
          : _speechController.text.trim(),
      imageType: _imageType,
      imageValue: _imageValue,
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
      order: order,
    );

    if (widget.item != null) {
      await appProvider.updateItemWithSync(item);
    } else {
      await appProvider.addItemWithSync(item);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FF),
        appBar: AppBar(
          backgroundColor: Color(widget.category.colorValue),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEdit ? 'تعديل عنصر' : 'إضافة عنصر جديد',
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
              // Text Input
              _SectionTitle(title: 'النص'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _textController,
                style: GoogleFonts.cairo(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'مثلاً: عايز أروح حديقة الحيوان',
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
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال النص';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Image Selection
              _SectionTitle(title: 'الصورة'),
              const SizedBox(height: 12),

              // Preview
              Center(
                child: Container(
                  width: 120,
                  height: 120,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _buildImagePreview(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Image source buttons
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceButton(
                      icon: Icons.camera_alt,
                      label: 'كاميرا',
                      onTap: _pickImageFromCamera,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImageSourceButton(
                      icon: Icons.photo_library,
                      label: 'الاستوديو',
                      onTap: _pickImageFromGallery,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Emoji Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أو اختر أيقونة:',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
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
                        final isSelected =
                            _imageType == 'emoji' && _imageValue == emoji;

                        return GestureDetector(
                          onTap: () => _selectEmoji(emoji),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(widget.category.colorValue)
                                      .withOpacity(0.2)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: Color(widget.category.colorValue),
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
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Custom Speech Text (Optional)
              _SectionTitle(title: 'نص النطق المخصص (اختياري)'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _speechController,
                style: GoogleFonts.cairo(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'إذا كنت تريد نطق نص مختلف',
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
                maxLines: 2,
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

  Widget _buildImagePreview() {
    if (_imageType == 'emoji') {
      return Center(
        child: Text(
          _imageValue,
          style: const TextStyle(fontSize: 60),
        ),
      );
    } else if (_imageType == 'local' && _selectedFile != null) {
      return Image.file(
        _selectedFile!,
        fit: BoxFit.cover,
      );
    } else {
      return const Center(
        child: Icon(
          Icons.image,
          size: 60,
          color: Color(0xFFBDC3C7),
        ),
      );
    }
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

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE0E6ED),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF4A90E2)),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
