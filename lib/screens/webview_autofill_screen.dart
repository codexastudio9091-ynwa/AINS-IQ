import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/nilam_entry.dart';

class WebviewAutofillScreen extends StatefulWidget {
  final NilamEntry entry;
  final String portalUrl;

  const WebviewAutofillScreen({
    super.key,
    required this.entry,
    this.portalUrl = 'https://ains.moe.gov.my/',
  });

  @override
  State<WebviewAutofillScreen> createState() => _WebviewAutofillScreenState();
}

class _WebviewAutofillScreenState extends State<WebviewAutofillScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 1. Show the KPM Maintenance Warning on Load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showKpmMaintenanceWarning();
    });

    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.portalUrl));
    }
  }

  void _showKpmMaintenanceWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('AINS System Update',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'The KPM AINS Portal is undergoing upgrades from 10 Aug to 24 Aug 2026.\n\nAuto-fill may fail during this time. If it fails, tap the "Manual Copy" icon in the top right to copy your AI data!',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _injectAutofillScript() async {
    final title = _escapeJs(widget.entry.title);
    final author = _escapeJs(widget.entry.author);
    final publisher = _escapeJs(widget.entry.publisher);
    final year = _escapeJs(widget.entry.year);
    final synopsis = _escapeJs(widget.entry.synopsis);
    final pengajaran = _escapeJs(widget.entry.pengajaran);

    final String jsCode = '''
      (function() {
        function setVal(selectors, val) {
          for (let s of selectors) {
            let el = document.querySelector(s);
            if (el) {
              el.value = val;
              el.dispatchEvent(new Event('input', { bubbles: true }));
              el.dispatchEvent(new Event('change', { bubbles: true }));
              return true;
            }
          }
          return false;
        }

        let success = false;
        if (setVal(['input[name*="tajuk"]', 'input[id*="tajuk"]', 'input[placeholder*="Tajuk"]', 'input[name*="title"]'], '$title')) success = true;
        if (setVal(['input[name*="pengarang"]', 'input[id*="pengarang"]', 'input[placeholder*="Pengarang"]', 'input[name*="author"]'], '$author')) success = true;
        setVal(['input[name*="penerbit"]', 'input[id*="penerbit"]', 'input[placeholder*="Penerbit"]', 'input[name*="publisher"]'], '$publisher');
        setVal(['input[name*="tahun"]', 'input[id*="tahun"]', 'input[placeholder*="Tahun"]', 'input[name*="year"]'], '$year');
        if (setVal(['textarea[name*="sinopsis"]', 'textarea[id*="sinopsis"]', 'textarea[placeholder*="Sinopsis"]'], '$synopsis')) success = true;
        if (setVal(['textarea[name*="pengajaran"]', 'textarea[id*="pengajaran"]', 'textarea[placeholder*="Pengajaran"]'], '$pengajaran')) success = true;
        
        return success.toString();
      })();
    ''';

    try {
      final Object result =
          await _controller.runJavaScriptReturningResult(jsCode);
      if (!mounted) return;

      if (result.toString() == '"true"' || result.toString() == 'true') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('AI data injected!'),
            backgroundColor: Colors.green[700]));
      } else {
        // Automatically pop up the manual copy sheet if JS fails
        _showManualCopySheet();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Portal changed! Use manual copy instead.'),
            backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (!mounted) return;
      _showManualCopySheet();
    }
  }

  String _escapeJs(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('\'', '\\\'')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '');
  }

  void _showManualCopySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10)),
            ),
            const Text('Manual Copy Assistant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(child: _buildWebAssistantView(context)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebAssistantView(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NILAM Portal Auto-Fill',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Manual Copy',
            onPressed: _showManualCopySheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Portal',
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _injectAutofillScript,
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Auto-Fill AI Data',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildWebAssistantView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Extracted Book Metadata (Tap to Copy)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildCopyTile('Title', widget.entry.title),
          _buildCopyTile('Author', widget.entry.author),
          _buildCopyTile('Publisher', widget.entry.publisher),
          _buildCopyTile('Year', widget.entry.year),
          _buildCopyTile('Pages & Category',
              '${widget.entry.pageCount} Pages (${widget.entry.category})'),
          _buildCopyTile('Synopsis', widget.entry.synopsis),
          _buildCopyTile('Pengajaran', widget.entry.pengajaran),
        ],
      ),
    );
  }

  Widget _buildCopyTile(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold)),
        subtitle: Text(value.isEmpty ? 'N/A' : value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        trailing: IconButton(
          icon: const Icon(Icons.copy, color: Color(0xFF0D47A1)),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Copied "$label" to clipboard!'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.blue[900]),
            );
          },
        ),
      ),
    );
  }
}
