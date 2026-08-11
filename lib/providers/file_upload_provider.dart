import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_access.dart';
import '../models/nilam_entry.dart';
import '../services/api_service.dart';
import '../services/file_extractor_service.dart';

class FileUploadState {
  final ExtractedFile? selectedFile;
  final ExtractedFile? selectedInfoFile;
  final bool isLoading;
  final String? errorMessage;
  final NilamEntry? extractedEntry;
  final bool isSaved;

  const FileUploadState({
    this.selectedFile,
    this.selectedInfoFile,
    this.isLoading = false,
    this.errorMessage,
    this.extractedEntry,
    this.isSaved = false,
  });

  FileUploadState copyWith({
    ExtractedFile? selectedFile,
    ExtractedFile? selectedInfoFile,
    bool? isLoading,
    String? errorMessage,
    NilamEntry? extractedEntry,
    bool? isSaved,
    bool clearSelectedFile = false,
    bool clearSelectedInfoFile = false,
    bool clearError = false,
    bool clearEntry = false,
  }) {
    return FileUploadState(
      selectedFile:
          clearSelectedFile ? null : (selectedFile ?? this.selectedFile),
      selectedInfoFile: clearSelectedInfoFile
          ? null
          : (selectedInfoFile ?? this.selectedInfoFile),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      extractedEntry:
          clearEntry ? null : (extractedEntry ?? this.extractedEntry),
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class FileUploadNotifier extends StateNotifier<FileUploadState> {
  FileUploadNotifier() : super(const FileUploadState());

  // 1. Pick Primary Reading Material File (Book cover, PDF, Poster)
  Future<void> selectFile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final file = await FileExtractorService.pickAndExtractFile();
      if (file != null) {
        state = state.copyWith(
          selectedFile: file,
          isLoading: false,
          clearEntry: true,
          isSaved: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to select file: $e',
      );
    }
  }

  // Remove Primary File
  void removePrimaryFile() {
    state = state.copyWith(
      clearSelectedFile: true,
      clearEntry: true,
      isSaved: false,
      clearError: true,
    );
  }

  // 2. Pick Optional Info Screenshot (Teacher notes, Kategori/Tajuk prefill)
  Future<void> selectInfoFile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final file = await FileExtractorService.pickAndExtractFile();
      if (file != null) {
        state = state.copyWith(
          selectedInfoFile: file,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to select info screenshot: $e',
      );
    }
  }

  // Remove Info Screenshot
  void removeInfoFile() {
    state = state.copyWith(
      clearSelectedInfoFile: true,
      clearError: true,
    );
  }

  // 3. Send file(s) to Gemini AI via Google Apps Script Backend Router
  Future<void> analyzeWithAi(AppAccessState accessState) async {
    if (state.selectedFile == null) {
      state = state.copyWith(
        errorMessage: 'Please select a material document first.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearEntry: true,
      isSaved: false,
    );

    try {
      final NilamEntry entry = await ApiService.analyzeDocument(
        primaryFile: state.selectedFile!,
        infoFile: state.selectedInfoFile,
        accessState: accessState,
      );

      state = state.copyWith(
        isLoading: false,
        extractedEntry: entry,
        isSaved: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // 4. Mark as Saved (Called after saving to Hive Bookshelf)
  void markSaved(NilamEntry confirmedEntry) {
    state = state.copyWith(
      isSaved: true,
      extractedEntry: confirmedEntry,
    );
  }

  // 5. Clear form to scan another book
  void resetForNextMaterial() {
    state = const FileUploadState();
  }
}

final fileUploadProvider =
    StateNotifierProvider<FileUploadNotifier, FileUploadState>((ref) {
  return FileUploadNotifier();
});
