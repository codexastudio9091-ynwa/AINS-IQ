import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_access.dart';
import '../models/nilam_entry.dart';
import '../providers/access_provider.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import 'top_up_modal.dart';
import 'webview_autofill_screen.dart';
import 'upload_screen.dart';
import 'landing_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<NilamEntry> _entries = [];
  bool _isLoadingHistory = true;

  // Floating 10-Second Banner Control
  bool _showReadingReminder = true;
  Timer? _reminderTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
      _startReminderTimer();
    });
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _startReminderTimer() {
    _reminderTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showReadingReminder = false;
        });
      }
    });
  }

  Future<void> _loadHistory() async {
    final state = ref.read(accessProvider);
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final logs = await ApiService.fetchHistory(state);
      if (mounted) {
        setState(() {
          _entries = logs;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to sync cloud data: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _logOut() {
    ref.read(accessProvider.notifier).reset();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
    );
  }

  void _showExportOptions(AppAccessState state) {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Your bookshelf is empty! Add some books first.'),
          backgroundColor: Colors.amber[800]));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Export Reading Logs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Share your reading history with your teacher.',
                  style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 24),
              ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: Icon(Icons.picture_as_pdf, color: Colors.red[900])),
                title: const Text('Export as PDF Document'),
                subtitle: const Text('Best for printing and viewing'),
                onTap: () {
                  Navigator.pop(ctx);
                  ExportService.sharePdf(_entries, state);
                },
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.table_chart, color: Colors.green[900])),
                title: const Text('Export as CSV / Excel'),
                subtitle: const Text('Best for data collection'),
                onTap: () {
                  Navigator.pop(ctx);
                  ExportService.shareCsv(_entries, state);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(accessProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My NILAM Bookshelf',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export Logs',
            onPressed: () => _showExportOptions(accessState),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: _logOut,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: InkWell(
                onTap: () => _handleBadgeTap(accessState),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.amber[400],
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          accessState.mode == AccessMode.b2cStudent
                              ? Icons.stars
                              : Icons.school,
                          color: Colors.blue[950],
                          size: 16),
                      const SizedBox(width: 6),
                      Text(
                        accessState.mode == AccessMode.b2cStudent
                            ? '${accessState.credits} Scans Left'
                            : accessState.schoolCode ?? 'School Mode',
                        style: TextStyle(
                            color: Colors.blue[950],
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- FLOATING 10-SECOND "READ FIRST, LOG FAST" BANNER ---
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 400),
            crossFadeState: _showReadingReminder
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            secondChild: const SizedBox.shrink(),
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[900]!, Colors.blue[800]!],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[400],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.menu_book,
                        color: Colors.blue[950], size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📖 Read First, Log Fast!',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'AINS NILAM AI simplifies your logging process. Remember to read your books thoroughly before logging!',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white70, size: 18),
                    onPressed: () {
                      setState(() {
                        _showReadingReminder = false;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: Colors.blue[900],
              onRefresh: () async {
                await ref.read(accessProvider.notifier).refreshCredits();
                await _loadHistory();
              },
              child: _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? _buildEmptyState()
                      : _buildBookshelfList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startAiScan(accessState),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan Book',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_sync, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text('Cloud Bookshelf Empty',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54)),
              const SizedBox(height: 8),
              Text(
                  'Pull down anytime to sync across your devices\nor tap "Scan Book" below to add your first log!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookshelfList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final item = _entries[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => WebviewAutofillScreen(entry: item)));
            },
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.book, color: Colors.blue[900])),
            title: Text(item.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                  '${item.author}\n${item.category} • ${item.pageCount} Pages',
                  style: const TextStyle(height: 1.3)),
            ),
            trailing: Icon(Icons.send_to_mobile, color: Colors.amber[800]),
          ),
        );
      },
    );
  }

  void _handleBadgeTap(AppAccessState accessState) {
    if (accessState.mode == AccessMode.b2cStudent) {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const TopUpModal());
    }
  }

  Future<void> _startAiScan(AppAccessState accessState) async {
    final NilamEntry? finalSavedEntry = await Navigator.push<NilamEntry>(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );

    if (finalSavedEntry != null && mounted) {
      setState(() {
        _entries.insert(0, finalSavedEntry);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Saved "${finalSavedEntry.title}" to Cloud!'),
          backgroundColor: Colors.green[700]));
    }
  }
}
