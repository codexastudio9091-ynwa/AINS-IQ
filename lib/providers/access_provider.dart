import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_access.dart';
import '../services/api_service.dart';

class AccessNotifier extends StateNotifier<AppAccessState> {
  AccessNotifier() : super(AppAccessState.initial());

  void setB2cMode({required String email, required int credits}) {
    state = state.copyWith(
        mode: AccessMode.b2cStudent, userEmail: email, credits: credits);
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
  }

  // NEW: BYOK POWER USER MODE
  void setPowerUserMode({required String apiKey}) {
    state = state.copyWith(
      mode: AccessMode.b2cStudent,
      userEmail: 'Power User (BYOK)',
      credits: 9999, // Give them unlimited local UI credits
      customApiKey: apiKey, // The API Service will prioritize this key!
    );
  }

  // PERSISTENT FILE METHODS
  void setInfoFile(XFile? file) {
    state =
        state.copyWith(persistentInfoFile: file, clearInfoFile: file == null);
  }

  void addCredits(int amount) =>
      state = state.copyWith(credits: state.credits + amount);
  void decrementCredit() {
    if (state.credits > 0) state = state.copyWith(credits: state.credits - 1);
  }

  Future<bool> refreshCredits() async {
    if (state.mode != AccessMode.b2cStudent ||
        state.userEmail == null ||
        state.customApiKey != null) return false;
    try {
      final res = await ApiService.loginB2cUser(state.userEmail!);
      if (res['success'] == true && res['data'] != null) {
        state = state.copyWith(
            credits: int.tryParse(res['data']['credits'].toString()) ??
                state.credits);
        return true;
      }
    } catch (_) {}
    return false;
  }

  void reset() => state = AppAccessState.initial();
}

final accessProvider = StateNotifierProvider<AccessNotifier, AppAccessState>(
    (ref) => AccessNotifier());
