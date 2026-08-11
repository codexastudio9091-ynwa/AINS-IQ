import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/local_db_service.dart';
import 'screens/landing_screen.dart';
import 'screens/history_screen.dart'; // <-- Added import
import 'providers/access_provider.dart'; // <-- Added import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDbService.init(); // <-- Initialize local Hive DB

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Changed to ConsumerWidget to read Riverpod states
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the access state
    final accessState = ref.watch(accessProvider);

    return MaterialApp(
      title: 'AINS IQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Automatically route user based on saved session
      home: (accessState.userEmail != null || accessState.schoolCode != null)
          ? const HistoryScreen()
          : const LandingScreen(),
    );
  }
}
