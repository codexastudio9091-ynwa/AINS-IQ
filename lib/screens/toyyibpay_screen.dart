import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ToyyibPayScreen extends StatefulWidget {
  final String paymentUrl;
  final String title;

  const ToyyibPayScreen({
    super.key,
    required this.paymentUrl,
    required this.title,
  });

  @override
  State<ToyyibPayScreen> createState() => _ToyyibPayScreenState();
}

class _ToyyibPayScreenState extends State<ToyyibPayScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          // INTERCEPT THE URL BEFORE IT LOADS
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            // Auto-detect when ToyyibPay redirects back to our callback URL
            if (url.contains('status_id=')) {
              if (url.contains('status_id=1')) {
                // Status 1: Payment Success
                _finishPayment(success: true);
              } else {
                // Status 2: Pending, Status 3: Failed/Cancelled
                _finishPayment(success: false);
              }
              // Prevent the webview from trying to render the backend script URL
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _finishPayment({required bool success}) {
    if (!mounted) return;
    Navigator.pop(context, success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Page',
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel Payment',
            onPressed: () => _finishPayment(success: false),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            ),
        ],
      ),
    );
  }
}
