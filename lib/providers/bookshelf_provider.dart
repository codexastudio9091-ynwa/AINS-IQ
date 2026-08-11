import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nilam_entry.dart';
import '../services/local_db_service.dart';

class BookshelfNotifier extends StateNotifier<List<NilamEntry>> {
  BookshelfNotifier() : super([]) {
    loadBooks();
  }

  // Load saved books from Hive box
  void loadBooks() {
    final box = LocalDbService.booksBox;
    final List<NilamEntry> loaded = [];
    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item != null && item is Map) {
        loaded.add(NilamEntry.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    state = loaded.reversed.toList(); // Display newest scans first
  }

  // Add a new scanned book
  Future<void> addBook(NilamEntry entry) async {
    final box = LocalDbService.booksBox;
    await box.add(entry.toJson());
    loadBooks();
  }

  // Update existing book details
  Future<void> updateBook(NilamEntry updatedEntry) async {
    final box = LocalDbService.booksBox;
    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item != null && item is Map) {
        final existing = NilamEntry.fromJson(Map<String, dynamic>.from(item));
        if (existing.title == updatedEntry.title ||
            (existing.title == updatedEntry.title &&
                existing.author == updatedEntry.author)) {
          await box.putAt(i, updatedEntry.toJson());
          break;
        }
      }
    }
    loadBooks();
  }

  // MARK A BOOK AS COMPLETED IN LOCAL STORAGE
  Future<void> markCompleted(NilamEntry entry) async {
    final box = LocalDbService.booksBox;
    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item != null && item is Map) {
        final existing = NilamEntry.fromJson(Map<String, dynamic>.from(item));
        if (existing.title == entry.title && existing.author == entry.author) {
          final completedEntry =
              existing.copyWith(status: NilamStatus.completed);
          await box.putAt(i, completedEntry.toJson());
          break;
        }
      }
    }
    loadBooks();
  }

  // Delete a book from local storage
  Future<void> deleteBook(NilamEntry entry) async {
    final box = LocalDbService.booksBox;
    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item != null && item is Map) {
        final existing = NilamEntry.fromJson(Map<String, dynamic>.from(item));
        if (existing.title == entry.title && existing.author == entry.author) {
          await box.deleteAt(i);
          break;
        }
      }
    }
    loadBooks();
  }
}

final bookshelfProvider =
    StateNotifierProvider<BookshelfNotifier, List<NilamEntry>>((ref) {
  return BookshelfNotifier();
});
