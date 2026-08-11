import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../utils/base64_helper.dart';

class ExtractedFile {
  final String fileName;
  final String fileExtension;
  final String mimeType;
  final String base64Data;
  final double sizeInMb;

  ExtractedFile({
    required this.fileName,
    required this.fileExtension,
    required this.mimeType,
    required this.base64Data,
    required this.sizeInMb,
  });
}

class FileExtractorService {
  /// Opens OS native file picker for PDF, DOCX, PNG, and JPEG.
  /// Returns an [ExtractedFile] ready for Google Apps Script transmission.
  static Future<ExtractedFile?> pickAndExtractFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'png', 'jpg', 'jpeg'],
        withData: true, // Crucial for Web & Mobile memory extraction
      );

      if (result == null || result.files.isEmpty) {
        return null; // User canceled the picker
      }

      final PlatformFile file = result.files.first;

      // Ensure file bytes are available
      if (file.bytes == null) {
        throw Exception('Could not read file bytes into memory.');
      }

      final Uint8List bytes = file.bytes!;
      final String extension = file.extension ?? 'unknown';
      final double sizeMb = Base64Helper.estimateSizeInMb(bytes);

      // Guardrail: Alert if file is too large for serverless transfer
      if (sizeMb > 8.0) {
        throw Exception(
            'File size (${sizeMb.toStringAsFixed(1)}MB) exceeds 8MB limit for processing.');
      }

      final String base64String = Base64Helper.encodeBytes(bytes);
      final String mimeType = Base64Helper.getMimeType(extension);

      return ExtractedFile(
        fileName: file.name,
        fileExtension: extension,
        mimeType: mimeType,
        base64Data: base64String,
        sizeInMb: sizeMb,
      );
    } catch (e) {
      throw Exception('File extraction failed: $e');
    }
  }
}
