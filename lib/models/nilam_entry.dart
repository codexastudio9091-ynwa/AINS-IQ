enum NilamStatus { pending, completed }

class NilamEntry {
  final String? id;
  final String title;
  final String author;
  final String publisher;
  final String year;
  final int pageCount;
  final String language;
  final String category;
  final String websiteLink;
  final String synopsis;
  final String pengajaran;
  final NilamStatus status;
  final DateTime timestamp;

  NilamEntry({
    this.id,
    required this.title,
    required this.author,
    required this.publisher,
    required this.year,
    required this.pageCount,
    required this.language,
    required this.category,
    required this.websiteLink,
    required this.synopsis,
    required this.pengajaran,
    this.status = NilamStatus.pending,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  NilamEntry copyWith({
    String? id,
    String? title,
    String? author,
    String? publisher,
    String? year,
    int? pageCount,
    String? language,
    String? category,
    String? websiteLink,
    String? synopsis,
    String? pengajaran,
    NilamStatus? status,
    DateTime? timestamp,
  }) {
    return NilamEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      year: year ?? this.year,
      pageCount: pageCount ?? this.pageCount,
      language: language ?? this.language,
      category: category ?? this.category,
      websiteLink: websiteLink ?? this.websiteLink,
      synopsis: synopsis ?? this.synopsis,
      pengajaran: pengajaran ?? this.pengajaran,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory NilamEntry.fromJson(Map<String, dynamic> json) {
    return NilamEntry(
      id: json['id']?.toString(),
      title: json['title'] ?? 'Unknown Title',
      author: json['author'] ?? 'Unknown Author',
      publisher: json['publisher'] ?? 'Unknown Publisher',
      year: json['year']?.toString() ?? 'Unknown',
      pageCount: json['pageCount'] is int
          ? json['pageCount']
          : int.tryParse(json['pageCount']?.toString() ?? '0') ?? 0,
      language: json['language'] ?? 'Malay',
      category: json['category'] ?? 'Buku',
      websiteLink: json['websiteLink'] ?? '',
      synopsis: json['synopsis'] ?? '',
      pengajaran: json['pengajaran'] ?? '',
      status: json['status'] == 'completed'
          ? NilamStatus.completed
          : NilamStatus.pending,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'publisher': publisher,
      'year': year,
      'pageCount': pageCount,
      'language': language,
      'category': category,
      'websiteLink': websiteLink,
      'synopsis': synopsis,
      'pengajaran': pengajaran,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
