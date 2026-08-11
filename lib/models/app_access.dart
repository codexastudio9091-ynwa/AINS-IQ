import 'package:image_picker/image_picker.dart';

enum AccessMode { b2cStudent, b2bSchool }

class AppAccessState {
  final AccessMode mode;
  final String? userEmail;
  final int credits;

  final String? schoolCode;
  final String? schoolName;
  final String? targetSheetId;

  final String? b2bLoginType;
  final String? b2bStudentName;
  final String? b2bStudentClass;
  final String? b2bStudentEmail;

  final String? customApiKey;

  // PERSISTENT STEP 1 FILE
  final XFile? persistentInfoFile;

  const AppAccessState({
    required this.mode,
    this.userEmail,
    this.credits = 0,
    this.schoolCode,
    this.schoolName,
    this.targetSheetId,
    this.b2bLoginType,
    this.b2bStudentName,
    this.b2bStudentClass,
    this.b2bStudentEmail,
    this.customApiKey,
    this.persistentInfoFile,
  });

  factory AppAccessState.initial() =>
      const AppAccessState(mode: AccessMode.b2cStudent, credits: 3);

  AppAccessState copyWith({
    AccessMode? mode,
    String? userEmail,
    int? credits,
    String? schoolCode,
    String? schoolName,
    String? targetSheetId,
    String? b2bLoginType,
    String? b2bStudentName,
    String? b2bStudentClass,
    String? b2bStudentEmail,
    String? customApiKey,
    XFile? persistentInfoFile,
    bool clearInfoFile = false,
  }) {
    return AppAccessState(
      mode: mode ?? this.mode,
      userEmail: userEmail ?? this.userEmail,
      credits: credits ?? this.credits,
      schoolCode: schoolCode ?? this.schoolCode,
      schoolName: schoolName ?? this.schoolName,
      targetSheetId: targetSheetId ?? this.targetSheetId,
      b2bLoginType: b2bLoginType ?? this.b2bLoginType,
      b2bStudentName: b2bStudentName ?? this.b2bStudentName,
      b2bStudentClass: b2bStudentClass ?? this.b2bStudentClass,
      b2bStudentEmail: b2bStudentEmail ?? this.b2bStudentEmail,
      customApiKey: customApiKey ?? this.customApiKey,
      persistentInfoFile: clearInfoFile
          ? null
          : (persistentInfoFile ?? this.persistentInfoFile),
    );
  }
}
