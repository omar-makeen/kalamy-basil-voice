import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/firebase_cleanup.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _cleanup = FirebaseCleanup();
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic>? _stats;

  Future<void> _loadStats() async {
    final appProvider = context.read<AppProvider>();
    final familyCode = appProvider.getFamilyCode();

    if (familyCode == null) {
      setState(() {
        _statusMessage = 'No family code set';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading statistics...';
    });

    try {
      final stats = await _cleanup.getFamilyStats(familyCode);
      setState(() {
        _stats = stats;
        _statusMessage = 'Statistics loaded';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupDuplicates() async {
    final appProvider = context.read<AppProvider>();
    final familyCode = appProvider.getFamilyCode();

    if (familyCode == null) {
      setState(() {
        _statusMessage = 'No family code set';
      });
      return;
    }

    // Confirm with user
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تنظيف البيانات المكررة'),
          content: const Text(
            'هل تريد حذف جميع البيانات المكررة من Firebase؟\n\n'
            'سيتم الاحتفاظ بنسخة واحدة فقط من كل عنصر.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تنظيف'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Cleaning up duplicates...';
    });

    try {
      final results = await _cleanup.cleanupFamily(familyCode);

      setState(() {
        _statusMessage = '''
✅ Cleanup completed!

Categories:
  Before: ${results['categoriesBefore']}
  After: ${results['categoriesAfter']}
  Removed: ${results['categoriesRemoved']}

Items:
  Before: ${results['itemsBefore']}
  After: ${results['itemsAfter']}
  Removed: ${results['itemsRemoved']}
''';
        _isLoading = false;
      });

      // Reload stats
      await _loadStats();

      // Sync app data
      if (mounted) {
        await appProvider.syncWithCloud();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _normalizeIds() async {
    final appProvider = context.read<AppProvider>();
    final familyCode = appProvider.getFamilyCode();

    if (familyCode == null) {
      setState(() {
        _statusMessage = 'No family code set';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Normalizing document IDs...';
    });

    try {
      await _cleanup.normalizeDocumentIds(familyCode);

      setState(() {
        _statusMessage = '✅ Document IDs normalized!';
        _isLoading = false;
      });

      // Reload stats
      await _loadStats();

      // Sync app data
      if (mounted) {
        await appProvider.syncWithCloud();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final familyCode = appProvider.getFamilyCode();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('أدوات التصحيح'),
          backgroundColor: const Color(0xFF4A90E2),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Family Code Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'معلومات العائلة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('رمز العائلة: ${familyCode ?? "غير محدد"}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Statistics
              if (_stats != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إحصائيات Firebase',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('إجمالي الفئات: ${_stats!['totalCategories']}'),
                        Text('إجمالي العناصر: ${_stats!['totalItems']}'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Actions
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadStats,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث الإحصائيات'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 8),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _cleanupDuplicates,
                icon: const Icon(Icons.cleaning_services),
                label: const Text('تنظيف البيانات المكررة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 8),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _normalizeIds,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('تطبيع معرفات المستندات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),

              // Status Message
              if (_statusMessage.isNotEmpty)
                Card(
                  color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            if (_isLoading) const SizedBox(width: 8),
                            const Text(
                              'الحالة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
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
