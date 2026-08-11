import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

class ApiKeyNotifier extends StateNotifier<AsyncValue<String?>> {
  ApiKeyNotifier() : super(const AsyncValue.loading()) {
    _loadApiKey();
  }

  // Load key from device storage on startup
  Future<void> _loadApiKey() async {
    try {
      final key = await LocalStorageService.getApiKey();
      state = AsyncValue.data(key);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Save key and update app state
  Future<void> saveKey(String newKey) async {
    state = const AsyncValue.loading();
    try {
      await LocalStorageService.saveApiKey(newKey);
      state = AsyncValue.data(newKey);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Remove key from device
  Future<void> clearKey() async {
    state = const AsyncValue.loading();
    try {
      await LocalStorageService.removeApiKey();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Global Provider exposed to the UI
final apiKeyProvider =
    StateNotifierProvider<ApiKeyNotifier, AsyncValue<String?>>((ref) {
  return ApiKeyNotifier();
});
