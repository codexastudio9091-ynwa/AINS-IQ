import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_access.dart';
import '../models/nilam_entry.dart';
import '../providers/access_provider.dart';
import '../services/api_service.dart';
import 'edit_entry_screen.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  XFile? _primaryFile;
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(accessProvider);
    final persistentInfoFile = accessState.persistentInfoFile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('NILAM Material Upload',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFileSelectorCard(
              title: 'Step 1: Material Info (Persisted)',
              subtitle: 'Instruction screenshot (Stays saved until cleared)',
              selectedFile: persistentInfoFile,
              onPick: () => _pickImage(isPrimary: false),
              onClear: () {
                ref.read(accessProvider.notifier).setInfoFile(null);
              },
            ),
            const SizedBox(height: 16),
            _buildFileSelectorCard(
              title: 'Step 2: Material Document (Required)',
              subtitle: 'Upload book cover, poster, or PDF for this scan',
              selectedFile: _primaryFile,
              onPick: () => _pickImage(isPrimary: true),
              onClear: () {
                setState(() {
                  _primaryFile = null;
                });
              },
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: (_primaryFile == null || _isAnalyzing)
                  ? null
                  : () => _startAiAnalysis(accessState),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(
                  _isAnalyzing
                      ? 'Extracting with AI Engine...'
                      : 'Analyze with AI Engine',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectorCard(
      {required String title,
      required String subtitle,
      required XFile? selectedFile,
      required VoidCallback onPick,
      required VoidCallback onClear}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[300]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 12),
          if (selectedFile == null)
            OutlinedButton.icon(
                onPressed: onPick,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[900],
                    side: BorderSide(color: Colors.blue[900]!)),
                icon: const Icon(Icons.upload_file),
                label: const Text('Select File / Camera'))
          else
            Row(children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(selectedFile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Clear saved file',
              )
            ]),
        ],
      ),
    );
  }

  Future<void> _pickImage({required bool isPrimary}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      if (isPrimary) {
        setState(() {
          _primaryFile = pickedFile;
        });
      } else {
        // Save Step 1 file globally so it persists across uploads!
        ref.read(accessProvider.notifier).setInfoFile(pickedFile);
      }
    }
  }

  Future<void> _startAiAnalysis(AppAccessState accessState) async {
    if (accessState.mode == AccessMode.b2cStudent && accessState.credits <= 0) {
      _showFriendlyErrorDialog(
          title: 'Out of Scans',
          message:
              'You have 0 AI scans remaining. Please return to your bookshelf and tap your badge to top up!',
          icon: Icons.offline_bolt,
          iconColor: Colors.amber[800]!);
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Passes the persistent info file automatically!
      final NilamEntry aiResult = await ApiService.analyzeDocument(
          primaryFile: _primaryFile!,
          infoFile: accessState.persistentInfoFile,
          accessState: accessState);

      if (accessState.mode == AccessMode.b2cStudent) {
        ref.read(accessProvider.notifier).decrementCredit();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isAnalyzing = false;
      });

      final NilamEntry? finalSavedEntry = await Navigator.push<NilamEntry>(
        context,
        MaterialPageRoute(builder: (_) => EditEntryScreen(entry: aiResult)),
      );

      if (!mounted) {
        return;
      }
      Navigator.pop(context, finalSavedEntry);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAnalyzing = false;
      });
      _handleScanError(e.toString());
    }
  }

  void _handleScanError(String rawError) {
    String title = 'Scan Unsuccessful';
    String message = 'System Error: $rawError';
    IconData icon = Icons.error_outline;
    Color iconColor = Colors.redAccent;

    final String lowerError = rawError.toLowerCase();

    if (lowerError.contains('credit') || lowerError.contains('insufficient')) {
      title = 'Insufficient Credits';
      message =
          'You do not have enough AI scan credits to complete this action.';
      icon = Icons.stars;
      iconColor = Colors.amber[800]!;
    } else if (lowerError.contains('socket') ||
        lowerError.contains('network') ||
        lowerError.contains('timeout')) {
      title = 'Connection Timeout';
      message =
          'We couldn\'t connect to the AI server. Please check your internet connection.';
      icon = Icons.wifi_off;
      iconColor = Colors.orange[800]!;
    } else if (lowerError.contains('500') || lowerError.contains('503')) {
      title = 'AI Server Busy';
      message =
          'Our AI engine is handling a high volume of requests right now. Please wait and try again!';
      icon = Icons.cloud_off;
      iconColor = Colors.blueGrey;
    }

    _showFriendlyErrorDialog(
        title: title, message: message, icon: icon, iconColor: iconColor);
  }

  void _showFriendlyErrorDialog(
      {required String title,
      required String message,
      required IconData icon,
      required Color iconColor}) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Row(children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)))
                ]),
                content:
                    Text(message, style: TextStyle(color: Colors.grey[800])),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      child: const Text('GOT IT',
                          style: TextStyle(fontWeight: FontWeight.bold)))
                ]));
  }
}
