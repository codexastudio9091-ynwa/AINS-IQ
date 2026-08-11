import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_key_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _keyController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiKeyState = ref.watch(apiKeyProvider);
    final apiKeyNotifier = ref.read(apiKeyProvider.notifier);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Configuration (BYOK)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To keep developer overhead at RM 0.00, connect your free Google AI Studio token sequence. This key is saved locally on your device and never stored on our servers[cite: 1].',
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Card showing Current Key Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      apiKeyState.value != null && apiKeyState.value!.isNotEmpty
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      color: apiKeyState.value != null &&
                              apiKeyState.value!.isNotEmpty
                          ? Colors.green
                          : Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            apiKeyState.value != null &&
                                    apiKeyState.value!.isNotEmpty
                                ? 'Key Connected (${apiKeyState.value!.substring(0, 4)}...)'
                                : 'No API Key Configured',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (apiKeyState.value != null &&
                        apiKeyState.value!.isNotEmpty)
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          apiKeyNotifier.clearKey();
                          _keyController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('API Key removed.')),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Input TextField
            TextField(
              controller: _keyController,
              obscureText: true, // Hides sensitive token characters
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 16),

            // Save Button
            ElevatedButton(
              onPressed: () {
                final inputKey = _keyController.text.trim();
                if (inputKey.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid API key.')),
                  );
                  return;
                }
                apiKeyNotifier.saveKey(inputKey);
                _keyController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Gemini API Key saved locally!')),
                );
              },
              child: const Text('Save API Key'),
            ),
          ],
        ),
      ),
    );
  }
}
