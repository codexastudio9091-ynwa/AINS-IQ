import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/nilam_entry.dart';
import '../models/app_access.dart';

class ExportService {
  // --- EXPORT TO CSV / EXCEL ---
  static Future<void> shareCsv(
      List<NilamEntry> entries, AppAccessState state) async {
    List<List<dynamic>> rows = [];

    // Header Row
    rows.add([
      'No.',
      'Title',
      'Author',
      'Publisher',
      'Year',
      'Pages',
      'Category',
      'Synopsis',
      'Pengajaran'
    ]);

    // Data Rows
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      rows.add([
        i + 1,
        e.title,
        e.author,
        e.publisher,
        e.year,
        e.pageCount,
        e.category,
        e.synopsis,
        e.pengajaran
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    // PLATFORM CHECK: WEB vs MOBILE
    if (kIsWeb) {
      // Create a virtual file in memory for web browsers to download
      final bytes = Uint8List.fromList(utf8.encode(csvData));
      final xFile =
          XFile.fromData(bytes, mimeType: 'text/csv', name: 'NILAM_Report.csv');
      await Share.shareXFiles([xFile],
          text: 'Here is my NILAM reading log data.');
    } else {
      // Save locally to device storage on mobile
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/NILAM_Report.csv');
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Here is my NILAM reading log data.');
    }
  }

  // --- EXPORT TO PDF ---
  static Future<void> sharePdf(
      List<NilamEntry> entries, AppAccessState state) async {
    final pdf = pw.Document();

    String userName = state.mode == AccessMode.b2cStudent
        ? (state.userEmail ?? 'Student')
        : (state.b2bStudentName ?? 'Student');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
                level: 0,
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Official NILAM Reading Log',
                          style: pw.TextStyle(
                              fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total Books: ${entries.length}',
                          style: const pw.TextStyle(fontSize: 14)),
                    ])),
            pw.SizedBox(height: 10),
            pw.Text('Generated for: $userName',
                style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 20),

            // Build a table for the PDF
            pw.TableHelper.fromTextArray(
              context: context,
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              headerHeight: 25,
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
              },
              headers: ['No.', 'Title', 'Author', 'Pages', 'Category'],
              data: List<List<String>>.generate(
                entries.length,
                (index) => [
                  '${index + 1}',
                  entries[index].title,
                  entries[index].author,
                  entries[index].pageCount.toString(),
                  entries[index].category,
                ],
              ),
            ),
          ];
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();

    // PLATFORM CHECK: WEB vs MOBILE
    if (kIsWeb) {
      // Create a virtual file in memory for web browsers to download
      final xFile = XFile.fromData(pdfBytes,
          mimeType: 'application/pdf', name: 'NILAM_Report.pdf');
      await Share.shareXFiles([xFile],
          text: 'Here is my official NILAM Reading PDF Report.');
    } else {
      // Save locally to device storage on mobile
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/NILAM_Report.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Here is my official NILAM Reading PDF Report.');
    }
  }
}
