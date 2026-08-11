import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/access_provider.dart';
import '../services/api_service.dart';
import '../widgets/web_promo_banner.dart'; // <-- Imported the new banner widget
import 'history_screen.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // --- WEB PROMO BANNER (Only visible on web) ---
            const WebPromoBanner(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- HEADER & NEW LOGO ---
                    Center(
                      child: Image.asset(
                        'assets/logo_transparent.png',
                        height: 110,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon if logo image fails to load
                          return const Icon(Icons.auto_stories,
                              size: 80, color: Color(0xFF0D47A1));
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AINS IQ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D47A1),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- APP SHORT DESCRIPTION ---
                    Text(
                      'Empowering students, parents, and teachers with AI-driven NILAM reading logs. Scan books, extract details instantly, and sync your reading journey to the cloud.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey[700], height: 1.5),
                    ),
                    const SizedBox(height: 40),

                    // --- OPTION 1: STUDENT / PARENT (B2C) ---
                    _buildOptionCard(
                      title: 'Student / Parent Login',
                      subtitle: 'Personal account with AI Scan Credits',
                      icon: Icons.person,
                      color: Colors.blue[800]!,
                      onTap: () => _showB2cLoginDialog(context),
                    ),
                    const SizedBox(height: 16),

                    // --- OPTION 2: SCHOOL LOGIN (B2B) ---
                    _buildOptionCard(
                      title: 'School Portal Login',
                      subtitle: 'Log in using an official School Code',
                      icon: Icons.school,
                      color: Colors.amber[800]!,
                      onTap: () => _showB2bLoginDialog(context),
                    ),
                    const SizedBox(height: 16),

                    // --- OPTION 3: POWER USER (BYOK) ---
                    _buildOptionCard(
                      title: 'Power User (BYOK)',
                      subtitle: 'Bring Your Own Key for unlimited scans',
                      icon: Icons.key,
                      color: Colors.blueGrey[800]!,
                      onTap: () => _showByokDialog(context),
                    ),
                  ],
                ),
              ),
            ),

            // --- DISCLAIMER & COPYRIGHT FOOTER ---
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  Text(
                    'Disclaimer: This application is an independent AI utility tool to assist with reading logs. It is not officially affiliated with, endorsed, or sponsored by the Ministry of Education Malaysia (KPM).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey[600], height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2026 AINS IQ. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI Component for the 3 Option Cards
  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900])),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  // --- POWER USER (BYOK) LOGIN DIALOG ---
  void _showByokDialog(BuildContext context) {
    final TextEditingController keyCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Power User (BYOK)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter your own Google Gemini API Key. This allows you to perform unlimited AI scans without consuming the app\'s B2C credits.',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 16),
            TextField(
              controller: keyCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Gemini API Key',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.password)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[900],
                foregroundColor: Colors.white),
            onPressed: () {
              final apiKey = keyCtrl.text.trim();
              if (apiKey.isEmpty) return;

              Navigator.pop(ctx);
              ref
                  .read(accessProvider.notifier)
                  .setPowerUserMode(apiKey: apiKey);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
            child: const Text('Enter Bookshelf'),
          ),
        ],
      ),
    );
  }

  // --- B2C (STUDENT) LOGIN DIALOG ---
  void _showB2cLoginDialog(BuildContext context) {
    final TextEditingController emailCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Student / Parent Login',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter your email to access your personal cloud bookshelf and AI credits.',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;

              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                final res = await ApiService.loginB2cUser(email);
                if (res['success'] == true && res['data'] != null) {
                  ref.read(accessProvider.notifier).setB2cMode(
                        email: res['data']['email'],
                        credits:
                            int.tryParse(res['data']['credits'].toString()) ??
                                0,
                      );
                  if (mounted) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen()));
                  }
                } else {
                  throw Exception(res['error'] ?? 'Login failed');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  // --- B2B (SCHOOL) LOGIN DIALOG ---
  void _showB2bLoginDialog(BuildContext context) {
    final TextEditingController codeCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('School Portal',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the School Code provided by your teacher.',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'School Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[800],
                foregroundColor: Colors.white),
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;

              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                final res = await ApiService.validateSchoolCode(code);
                if (res['success'] == true) {
                  if (mounted) {
                    _showStudentIdentityDialog(res['schoolName'],
                        res['sheetId'], res['loginType'], code);
                  }
                } else {
                  throw Exception(res['error'] ?? 'Invalid code');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Verify Code'),
          ),
        ],
      ),
    );
  }

  // --- B2B STEP 2: STUDENT IDENTITY ---
  void _showStudentIdentityDialog(
      String schoolName, String sheetId, String loginType, String code) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController classCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Welcome to $schoolName',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter your student details to continue.',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 16),
            if (loginType == 'EMAIL') ...[
              TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'School Email', border: OutlineInputBorder())),
            ] else ...[
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Full Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: classCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Class (e.g. 3 Amanah)',
                      border: OutlineInputBorder())),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white),
            onPressed: () {
              if (loginType == 'EMAIL' && emailCtrl.text.isEmpty) return;
              if (loginType != 'EMAIL' &&
                  (nameCtrl.text.isEmpty || classCtrl.text.isEmpty)) return;

              Navigator.pop(ctx);
              ref.read(accessProvider.notifier).setB2bMode(
                    schoolCode: code,
                    schoolName: schoolName,
                    targetSheetId: sheetId,
                    loginType: loginType,
                    studentName: nameCtrl.text.trim(),
                    studentClass: classCtrl.text.trim(),
                    studentEmail: emailCtrl.text.trim(),
                  );
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
            child: const Text('Enter Bookshelf'),
          ),
        ],
      ),
    );
  }
}
