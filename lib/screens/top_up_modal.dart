import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../providers/access_provider.dart';
import '../services/api_service.dart';
import 'toyyibpay_screen.dart';

class TopUpModal extends ConsumerStatefulWidget {
  const TopUpModal({super.key});

  @override
  ConsumerState<TopUpModal> createState() => _TopUpModalState();
}

class _TopUpModalState extends ConsumerState<TopUpModal> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(accessProvider);
    final String userEmail = accessState.userEmail ?? 'Not Logged In';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Up AI Scan Credits',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Account: $userEmail',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${accessState.credits} Scans Left',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // PACKAGE 1: Starter Bundle (RM 5.00 -> 20 Scans)
          _buildPackageCard(
            title: 'Starter NILAM Bundle',
            scans: '20 AI Scans',
            price: 'RM 5.00',
            unitPrice: 'RM 0.25 / scan',
            badgeText: null,
            badgeColor: null,
            borderColor: Colors.grey[300]!,
            buttonColor: Colors.blue[800]!,
            onTap: () => _handlePurchase(amount: 20, priceRm: 5.00),
          ),
          const SizedBox(height: 14),

          // PACKAGE 2: Value Bundle (RM 10.00 -> 50 Scans)
          _buildPackageCard(
            title: 'Anugerah Value Bundle',
            scans: '50 AI Scans',
            price: 'RM 10.00',
            unitPrice: 'RM 0.20 / scan',
            badgeText: 'BEST VALUE',
            badgeColor: Colors.amber[800],
            borderColor: Colors.amber[700]!,
            buttonColor: Colors.amber[800]!,
            onTap: () => _handlePurchase(amount: 50, priceRm: 10.00),
          ),
          const SizedBox(height: 20),

          Text(
            'Paid credits never expire and roll over permanently. Free daily scans reset to 3 every morning at midnight.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required String title,
    required String scans,
    required String price,
    required String unitPrice,
    String? badgeText,
    Color? badgeColor,
    required Color borderColor,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: badgeText != null ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scans,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue[900],
                  ),
                ),
                Text(
                  unitPrice,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isProcessing ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase({
    required int amount,
    required double priceRm,
  }) async {
    final accessState = ref.read(accessProvider);
    final email = accessState.userEmail;

    if (email == null || email.isEmpty) {
      if (!mounted) return;
      _showAlertDialog(
        title: 'Login Required',
        message:
            'Please log in with your student email first to purchase credits.',
      );
      return;
    }

    setState(() => _isProcessing = true);
    debugPrint(
        '[TopUpModal] Initializing Purchase for $email -> $amount Scans (RM $priceRm)');

    try {
      final uri = Uri.parse(
        '${ApiService.webAppUrl}?action=createToyyibPayBill&email=${Uri.encodeComponent(email)}&amount=$amount&priceRm=$priceRm',
      );

      var response = await http.get(uri);
      debugPrint('[TopUpModal] Response Status: ${response.statusCode}');

      if (response.statusCode >= 300 && response.statusCode < 400) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          debugPrint('[TopUpModal] Following redirect to: $redirectUrl');
          response = await http.get(Uri.parse(redirectUrl));
        }
      }

      debugPrint('[TopUpModal] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true &&
            jsonResponse['paymentUrl'] != null) {
          final String paymentUrl = jsonResponse['paymentUrl'];

          if (!mounted) return;

          // PLATFORM CHECK: WEB vs MOBILE
          if (kIsWeb) {
            // Open FPX banking securely in a new browser tab
            final Uri paymentUri = Uri.parse(paymentUrl);
            if (await canLaunchUrl(paymentUri)) {
              await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Payment page opened in a new tab. Pull down on your bookshelf to refresh your credit balance once paid!',
                  ),
                  backgroundColor: Colors.blue[800],
                  duration: const Duration(seconds: 4),
                ),
              );
            } else {
              throw Exception('Could not open payment tab in browser.');
            }
          } else {
            // Open In-App FPX Checkout WebView on Mobile
            final bool? paymentSuccess = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => ToyyibPayScreen(
                  paymentUrl: paymentUrl,
                  title: 'FPX Online Banking (RM $priceRm)',
                ),
              ),
            );

            debugPrint(
                '[TopUpModal] WebView returned paymentSuccess: $paymentSuccess');

            if (paymentSuccess == true) {
              ref.read(accessProvider.notifier).addCredits(amount);
              if (!mounted) return;

              // Close the TopUpModal sheet first
              Navigator.pop(context);

              // Show the Creative Success Celebration Dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => Dialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Celebratory Animated Icon Badge
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.amber[400]!, Colors.amber[700]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          '🎉 Top-Up Successful!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          'Awesome! +$amount AI Scans have been credited to your account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Let\'s Scan Books! 🚀',
                              style: TextStyle(
                                fontSize: 16,
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
        } else {
          throw Exception(
            jsonResponse['error'] ?? 'Could not create payment bill.',
          );
        }
      } else {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[TopUpModal ERROR] $e');
      if (!mounted) return;
      _showAlertDialog(
        title: 'Payment Error',
        message: 'Could not connect to payment server:\n\n$e',
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showAlertDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
