import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _geminiApiKey = 'GEMINI_API_KEY';

  /// Saves the BYOK Gemini API Key to client device state storage
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKey, apiKey.trim());
  }

  /// Retrieves the saved API Key, returning null if none is configured
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiApiKey);
  }

  /// Clears the API Key from local storage
  static Future<void> removeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geminiApiKey);
  }
}
