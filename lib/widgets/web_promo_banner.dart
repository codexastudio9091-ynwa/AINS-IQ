import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WebPromoBanner extends StatelessWidget {
  const WebPromoBanner({super.key});

  // 🔴 CHANGE THIS TO 'true' ONCE YOUR PLAY STORE APP IS LIVE!
  static const bool isMobileAppLive = false;

  // Paste your Google Play Store URL here once live
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ainsiq.app';

  @override
  Widget build(BuildContext context) {
    // Only display on Web browser
    if (!kIsWeb) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: isMobileAppLive
              ? [
                  Color(0xFF0D47A1),
                  Color(0xFF1976D2)
                ] // Deep Navy to Royal Blue
              : [Color(0xFF2E7D32), Color(0xFF43A047)], // Fresh Green Gradient
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
            child: const Icon(
              isMobileAppLive
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  isMobileAppLive
                      ? '📱 AINS IQ is now live on Google Play!'
                      : '⚡ AINS IQ Mobile App Coming Soon!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isMobileAppLive
                      ? 'Download the native Android app for camera OCR scanning & offline drafts.'
                      : 'Enjoy web scanning now! The official mobile apps will be available soon in your play stores.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isMobileAppLive) ...[
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(playStoreUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[500],
                foregroundColor: Colors.black87,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.shop, size: 18),
              label: const Text(
                'Get on Play Store',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
