import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_access.dart';
import '../models/nilam_entry.dart';

class ApiService {
  static const String webAppUrl =
      'https://script.google.com/macros/s/AKfycbz4MRDIJstHOHlquC0_NyADvQRGqzIA4Jj_HRSFUK1ZeYze629_kHqb88JPKB5kxrOX/exec';

  static Future<NilamEntry> analyzeDocument({
    required dynamic primaryFile,
    dynamic infoFile,
    required AppAccessState accessState,
  }) async {
    final primaryPayload = await _extractFilePayload(primaryFile);

    Map<String, String>? infoPayload;
    if (infoFile != null) {
      infoPayload = await _extractFilePayload(infoFile);
    }

    final resultJson = await analyzeNilam(
      docBase64: primaryPayload['base64']!,
      docMime: primaryPayload['mime']!,
      infoBase64: infoPayload?['base64'],
      infoMime: infoPayload?['mime'],
      accessMode: accessState.mode.name,
      schoolCode: accessState.schoolCode,
      userApiKey: accessState.customApiKey,
      userEmail: accessState.userEmail,
    );

    return NilamEntry.fromJson(resultJson);
  }

  static Future<List<NilamEntry>> fetchHistory(AppAccessState state) async {
    String url = '$webAppUrl?action=getHistory&mode=${state.mode.name}';

    if (state.mode == AccessMode.b2cStudent) {
      url += '&email=${Uri.encodeComponent(state.userEmail ?? '')}';
    } else {
      url += '&sheetId=${Uri.encodeComponent(state.targetSheetId ?? '')}';
    }

    var response = await http.get(Uri.parse(url));

    if (response.statusCode >= 300 && response.statusCode < 400) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        response = await http.get(Uri.parse(redirectUrl));
      }
    }

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        final List data = jsonResponse['data'] ?? [];
        return data.map((e) => NilamEntry.fromJson(e)).toList();
      } else {
        throw Exception(
            jsonResponse['error'] ?? 'Failed to load cloud history.');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  static Future<Map<String, String>> _extractFilePayload(
      dynamic fileObj) async {
    if (fileObj == null) {
      throw Exception('No file selected.');
    }

    try {
      final b64 = fileObj.base64Data;
      final mime = fileObj.mimeType;
      if (b64 is String &&
          b64.isNotEmpty &&
          mime is String &&
          mime.isNotEmpty) {
        return {'base64': b64, 'mime': mime};
      }
    } catch (_) {}

    try {
      final List<int>? bytes = await _tryGetBytes(fileObj);
      if (bytes != null && bytes.isNotEmpty) {
        return {
          'base64': base64Encode(bytes),
          'mime': _getMimeType(_tryGetFileName(fileObj))
        };
      }
    } catch (_) {}

    if (!kIsWeb) {
      try {
        File? extractedFile = _tryGetFile(fileObj);
        if (extractedFile != null) {
          final bytes = await extractedFile.readAsBytes();
          return {
            'base64': base64Encode(bytes),
            'mime': _getMimeType(extractedFile.path)
          };
        }
      } catch (_) {}
    }
    throw Exception('Unsupported file format.');
  }

  static File? _tryGetFile(dynamic obj) {
    if (kIsWeb) {
      return null;
    }
    if (obj is File) {
      return obj;
    }
    try {
      if (obj.path is String) {
        return File(obj.path);
      }
    } catch (_) {}

    return null;
  }

  static Future<List<int>?> _tryGetBytes(dynamic obj) async {
    try {
      if (obj.bytes is List<int>) {
        return obj.bytes;
      }
    } catch (_) {}

    try {
      final b = await obj.readAsBytes();
      if (b is List<int>) {
        return b;
      }
    } catch (_) {}

    return null;
  }

  static String _tryGetFileName(dynamic obj) {
    try {
      final n = obj.name;
      if (n is String && n.isNotEmpty) {
        return n;
      }
    } catch (_) {}

    try {
      final n = obj.path;
      if (n is String && n.isNotEmpty) {
        return n;
      }
    } catch (_) {}

    return 'image.jpg';
  }

  static Future<Map<String, dynamic>> analyzeNilam({
    required String docBase64,
    required String docMime,
    String? infoBase64,
    String? infoMime,
    required String accessMode,
    String? schoolCode,
    String? userApiKey,
    String? userEmail,
  }) async {
    final payload = {
      'action': 'analyze_nilam',
      'accessMode': accessMode,
      'schoolCode': schoolCode,
      'userApiKey': userApiKey,
      'userEmail': userEmail,
      'fileData': docBase64,
      'mimeType': docMime,
    };

    if (infoBase64 != null) {
      payload['infoFileData'] = infoBase64;
    }
    if (infoMime != null) {
      payload['infoMimeType'] = infoMime;
    }

    // FIX 1: Changed application/json to text/plain to bypass Chrome CORS Preflight
    var response = await http.post(Uri.parse(webAppUrl),
        headers: {'Content-Type': 'text/plain'}, body: jsonEncode(payload));

    if (response.statusCode >= 300 && response.statusCode < 400) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        response = await http.get(Uri.parse(redirectUrl));
      }
    }

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        return jsonResponse['data'];
      }
      throw Exception(jsonResponse['error']);
    }

    throw Exception('Server error: ${response.statusCode}');
  }

  static Future<void> saveNilamRecord({
    required NilamEntry entry,
    required AppAccessState accessState,
  }) async {
    final payload = {
      'action': 'save_nilam_record',
      'accessMode': accessState.mode.name,
      'schoolCode': accessState.schoolCode,
      'userEmail': accessState.userEmail,
      'b2bStudentName': accessState.b2bStudentName,
      'b2bStudentClass': accessState.b2bStudentClass,
      'b2bStudentEmail': accessState.b2bStudentEmail,
      'entry': entry.toJson(),
    };

    // FIX 1: Changed application/json to text/plain to bypass Chrome CORS Preflight
    var response = await http.post(Uri.parse(webAppUrl),
        headers: {'Content-Type': 'text/plain'}, body: jsonEncode(payload));

    if (response.statusCode >= 300 && response.statusCode < 400) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        response = await http.get(Uri.parse(redirectUrl));
      }
    }

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] != true) {
        throw Exception(jsonResponse['error']);
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> validateSchoolCode(String code) async {
    var response = await http.get(Uri.parse(
        '$webAppUrl?action=validateSchoolCode&code=${Uri.encodeComponent(code)}'));

    if (response.statusCode >= 300 && response.statusCode < 400) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        response = await http.get(Uri.parse(redirectUrl));
      }
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> loginB2cUser(String email) async {
    var response = await http.get(Uri.parse(
        '$webAppUrl?action=loginB2cUser&email=${Uri.encodeComponent(email)}'));

    if (response.statusCode >= 300 && response.statusCode < 400) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        response = await http.get(Uri.parse(redirectUrl));
      }
    }

    return jsonDecode(response.body);
  }

  static String _getMimeType(String pathOrName) {
    if (pathOrName.toLowerCase().endsWith('.png')) {
      return 'image/png';
    }
    if (pathOrName.toLowerCase().endsWith('.pdf')) {
      return 'application/pdf';
    }
    return 'image/jpeg';
  }
}
