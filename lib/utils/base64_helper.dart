import 'dart:convert';
import 'dart:typed_data';

class Base64Helper {
  /// Converts raw Uint8List file bytes into a clean Base64 encoded string.
  static String encodeBytes(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Estimates the payload size in Megabytes (MB) to prevent exceeding
  /// Google Apps Script POST limits (~10MB max per request).
  static double estimateSizeInMb(Uint8List bytes) {
    final int sizeInBytes = bytes.lengthInBytes;
    return sizeInBytes / (1024 * 1024);
  }

  /// Returns the appropriate MIME type for the Gemini API based on file extension.
  static String getMimeType(String extension) {
    final cleanExt = extension.toLowerCase().replaceAll('.', '');
    switch (cleanExt) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'docx':
      case 'doc':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
