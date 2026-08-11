import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nilam_entry.dart';
import '../providers/access_provider.dart';
import '../services/api_service.dart';

class EditEntryScreen extends ConsumerStatefulWidget {
  final NilamEntry entry;

  const EditEntryScreen({super.key, required this.entry});

  @override
  ConsumerState<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends ConsumerState<EditEntryScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _publisherCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _pageCtrl;
  late TextEditingController _synopsisCtrl;
  late TextEditingController _pengajaranCtrl;
  String _selectedCategory = 'Buku';
  bool _isSaving = false;

  final List<String> _categories = [
    "Buku",
    "Artikel",
    "Surat Khabar",
    "Buletin",
    "Carta",
    "Cerpen",
    "Jurnal",
    "Katalog",
    "Komik",
    "Laporan",
    "Majalah",
    "Manual Pengguna",
    "Peta",
    "Poster",
    "Rencana",
    "Risalah/Brosur",
    "Lain-lain"
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.entry.title);
    _authorCtrl = TextEditingController(text: widget.entry.author);
    _publisherCtrl = TextEditingController(text: widget.entry.publisher);
    _yearCtrl = TextEditingController(text: widget.entry.year);
    _pageCtrl = TextEditingController(text: widget.entry.pageCount.toString());
    _synopsisCtrl = TextEditingController(text: widget.entry.synopsis);
    _pengajaranCtrl = TextEditingController(text: widget.entry.pengajaran);

    if (_categories.contains(widget.entry.category)) {
      _selectedCategory = widget.entry.category;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _publisherCtrl.dispose();
    _yearCtrl.dispose();
    _pageCtrl.dispose();
    _synopsisCtrl.dispose();
    _pengajaranCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveToCloud() async {
    setState(() {
      _isSaving = true;
    });

    final accessState = ref.read(accessProvider);

    final updatedEntry = NilamEntry(
      title: _titleCtrl.text.trim(),
      author: _authorCtrl.text.trim(),
      publisher: _publisherCtrl.text.trim(),
      year: _yearCtrl.text.trim(),
      pageCount: int.tryParse(_pageCtrl.text.trim()) ?? 0,
      language: widget.entry.language,
      category: _selectedCategory,
      websiteLink: widget.entry.websiteLink,
      synopsis: _synopsisCtrl.text.trim(),
      pengajaran: _pengajaranCtrl.text.trim(),
    );

    try {
      await ApiService.saveNilamRecord(
          entry: updatedEntry, accessState: accessState);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, updatedEntry);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Edit',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- READER'S HONOR PLEDGE CALLOUT BANNER ---
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[400]!, width: 1.5)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amber[900], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reader\'s Honor Pledge 📖',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'AI helps you log faster, but reading grows your mind! Please ensure you have read this material thoroughly before saving it to your official NILAM records.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _buildField('Title', _titleCtrl),
            _buildField('Author', _authorCtrl),
            _buildField('Publisher', _publisherCtrl),
            Row(
              children: [
                Expanded(child: _buildField('Year', _yearCtrl, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildField('Pages', _pageCtrl, isNumber: true)),
              ],
            ),
            const Text('Category',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              isExpanded: true,
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val!;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildField('Synopsis', _synopsisCtrl, maxLines: 4),
            _buildField('Pengajaran (Moral Value)', _pengajaranCtrl,
                maxLines: 3),
            const SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveToCloud,
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.cloud_upload),
        label: Text(_isSaving ? 'Saving...' : 'Save to Cloud',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
          ),
        ],
      ),
    );
  }
}
