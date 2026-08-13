import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WebPromoBanner extends StatefulWidget {
  const WebPromoBanner({super.key});

  // 🔴 CHANGE THIS TO 'true' ONCE YOUR PLAY STORE APP IS LIVE!
  static const bool isMobileAppLive = false;

  // Paste your Google Play Store URL here once live
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ainsiq.app';

  // 🔴 CONTACT PAGE FOR BETA TESTERS
  static const String contactUrl =
      'https://codexa-studio-web.vercel.app/contact';

  @override
  State<WebPromoBanner> createState() => _WebPromoBannerState();
}

class _WebPromoBannerState extends State<WebPromoBanner> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Auto-scroll the carousel every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only display on Web browser
    if (!kIsWeb) return const SizedBox.shrink();

    // Fixed height for the banner container
    return Container(
      height: 90,
      margin: const EdgeInsets.all(12),
      child: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildBetaPromoBanner(),
          _buildAppStatusBanner(),
        ],
      ),
    );
  }

  // ==========================================
  // SLIDE 1: THE BETA TESTER PROMO
  // ==========================================
  Widget _buildBetaPromoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF9800)], // Fiery Orange
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🔥 NAK 50 KREDIT PERCUMA? (Terhad!)',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jadi Beta Tester Android App kami dan claim 50 Kredit terus ke akaun anda.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _launchUrl(WebPromoBanner.contactUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFE65100),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text(
              'Claim Sini',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SLIDE 2: THE ORIGINAL APP STATUS BANNER
  // ==========================================
  Widget _buildAppStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: WebPromoBanner.isMobileAppLive
              ? const [Color(0xFF0D47A1), Color(0xFF1976D2)] // Deep Navy
              : const [Color(0xFF2E7D32), Color(0xFF43A047)], // Fresh Green
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              WebPromoBanner.isMobileAppLive
                  ? Icons.get_app_rounded
                  : Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  WebPromoBanner.isMobileAppLive
                      ? '📱 AINS IQ is now live on Google Play!'
                      : '⚡ AINS IQ Mobile App Coming Soon!',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  WebPromoBanner.isMobileAppLive
                      ? 'Download the native Android app for camera OCR scanning & offline drafts.'
                      : 'Enjoy web scanning now! The official mobile apps will be available soon.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (WebPromoBanner.isMobileAppLive) ...[
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _launchUrl(WebPromoBanner.playStoreUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[500],
                foregroundColor: Colors.black87,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.shop, size: 18),
              label: const Text(
                'Play Store',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
