import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_access.dart';
import '../services/api_service.dart';

class AccessNotifier extends StateNotifier<AppAccessState> {
  AccessNotifier() : super(AppAccessState.initial()) {
    _loadSavedSession();
  }

  // --- NEW: LOAD SAVED SESSION ON STARTUP ---
  Future<void> _loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? modeString = prefs.getString('access_mode');

    if (modeString == 'b2c') {
      final email = prefs.getString('user_email');
      final credits = prefs.getInt('user_credits') ?? 0;
      if (email != null && email.isNotEmpty) {
        setB2cMode(email: email, credits: credits);
      }
    } else if (modeString == 'b2b') {
      final schoolCode = prefs.getString('school_code');
      if (schoolCode != null && schoolCode.isNotEmpty) {
        setB2bMode(
          schoolCode: schoolCode,
          schoolName: prefs.getString('school_name') ?? '',
          targetSheetId: prefs.getString('target_sheet_id') ?? '',
          loginType: prefs.getString('b2b_login_type') ?? '',
          studentName: prefs.getString('b2b_student_name'),
          studentClass: prefs.getString('b2b_student_class'),
          studentEmail: prefs.getString('b2b_student_email'),
        );
      }
    } else if (modeString == 'byok') {
      final apiKey = prefs.getString('custom_api_key');
      if (apiKey != null && apiKey.isNotEmpty) {
        setPowerUserMode(apiKey: apiKey);
      }
    }
  }

  // --- LOGIN METHODS (NOW SAVES TO PREFS) ---
  void setB2cMode({required String email, required int credits}) {
    state = state.copyWith(
        mode: AccessMode.b2cStudent, userEmail: email, credits: credits);
    _saveToPrefs('b2c', email: email, credits: credits);
  }

  void setB2bMode({
    required String schoolCode,
    required String schoolName,
    required String targetSheetId,
    required String loginType,
    String? studentName,
    String? studentClass,
    String? studentEmail,
  }) {
    state = state.copyWith(
      mode: AccessMode.b2bSchool,
      schoolCode: schoolCode,
      schoolName: schoolName,
      targetSheetId: targetSheetId,
      b2bLoginType: loginType,
      b2bStudentName: studentName,
      b2bStudentClass: studentClass,
      b2bStudentEmail: studentEmail,
    );
    _saveToPrefs(
      'b2b',
      schoolCode: schoolCode,
      schoolName: schoolName,
      targetSheetId: targetSheetId,
      loginType: loginType,
      studentName: studentName,
      studentClass: studentClass,
      studentEmail: studentEmail,
    );
  }

  void setPowerUserMode({required String apiKey}) {
    state = state.copyWith(
      mode: AccessMode.b2cStudent,
      userEmail: 'Power User (BYOK)',
      credits: 9999, // Give them unlimited local UI credits
      customApiKey: apiKey, // The API Service will prioritize this key!
    );
    _saveToPrefs('byok', customApiKey: apiKey);
  }

  // --- HELPER TO SAVE TO PREFS ---
  Future<void> _saveToPrefs(String mode,
      {String? email,
      int? credits,
      String? customApiKey,
      String? schoolCode,
      String? schoolName,
      String? targetSheetId,
      String? loginType,
      String? studentName,
      String? studentClass,
      String? studentEmail}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_mode', mode);
    if (email != null) await prefs.setString('user_email', email);
    if (credits != null) await prefs.setInt('user_credits', credits);
    if (customApiKey != null) {
      await prefs.setString('custom_api_key', customApiKey);
    }
    if (schoolCode != null) await prefs.setString('school_code', schoolCode);
    if (schoolName != null) await prefs.setString('school_name', schoolName);
    if (targetSheetId != null) {
      await prefs.setString('target_sheet_id', targetSheetId);
    }
    if (loginType != null) await prefs.setString('b2b_login_type', loginType);
    if (studentName != null) {
      await prefs.setString('b2b_student_name', studentName);
    }
    if (studentClass != null) {
      await prefs.setString('b2b_student_class', studentClass);
    }
    if (studentEmail != null) {
      await prefs.setString('b2b_student_email', studentEmail);
    }
  }

  // PERSISTENT FILE METHODS
  void setInfoFile(XFile? file) {
    state =
        state.copyWith(persistentInfoFile: file, clearInfoFile: file == null);
  }

  // --- CREDIT SYNCING ---
  void addCredits(int amount) {
    final newTotal = state.credits + amount;
    state = state.copyWith(credits: newTotal);
    _updatePrefsCredits(newTotal);
  }

  void decrementCredit() {
    if (state.credits > 0) {
      final newTotal = state.credits - 1;
      state = state.copyWith(credits: newTotal);
      _updatePrefsCredits(newTotal);
    }
  }

  Future<void> _updatePrefsCredits(int newCredits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_credits', newCredits);
  }

  Future<bool> refreshCredits() async {
    if (state.mode != AccessMode.b2cStudent ||
        state.userEmail == null ||
        state.customApiKey != null) return false;
    try {
      final res = await ApiService.loginB2cUser(state.userEmail!);
      if (res['success'] == true && res['data'] != null) {
        final newCredits =
            int.tryParse(res['data']['credits'].toString()) ?? state.credits;
        state = state.copyWith(credits: newCredits);
        _updatePrefsCredits(newCredits);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // --- NEW: LOGOUT & CLEAR SESSION ---
  Future<void> logout() async {
    state = AppAccessState.initial();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void reset() {
    logout();
  }
}

final accessProvider = StateNotifierProvider<AccessNotifier, AppAccessState>(
    (ref) => AccessNotifier());
