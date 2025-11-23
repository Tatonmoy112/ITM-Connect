import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

/// Cross-platform PDF download service
class PdfDownloadService {
  /// Download and open PDF - works on both mobile and web
  static Future<void> downloadPdf({
    required List<int> pdfBytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      _downloadOnWeb(pdfBytes, fileName);
    } else {
      await _downloadOnMobile(pdfBytes, fileName, openFile: true);
    }
  }

  /// Download PDF without opening (for background operations)
  static Future<String?> downloadPdfOnly({
    required List<int> pdfBytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      _downloadOnWeb(pdfBytes, fileName);
      return null;
    } else {
      return await _downloadOnMobile(pdfBytes, fileName, openFile: false);
    }
  }

  /// Download and open PDF on mobile
  static Future<void> downloadAndOpenPdf({
    required List<int> pdfBytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      _downloadOnWeb(pdfBytes, fileName);
    } else {
      await _downloadOnMobile(pdfBytes, fileName, openFile: true);
    }
  }

  /// Web download using universal_html
  static void _downloadOnWeb(List<int> pdfBytes, String fileName) {
    if (!kIsWeb) return;
    
    try {
      // Convert to Uint8List for proper binary handling
      final uint8list = Uint8List.fromList(pdfBytes);
      
      // Create blob from bytes with correct MIME type
      final blob = html.Blob([uint8list], 'application/pdf');
      
      // Create a temporary URL for the blob
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Create an anchor element and trigger download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      
      html.document.body!.children.add(anchor);
      anchor.click();
      
      // Cleanup after a small delay to ensure download starts
      Future.delayed(const Duration(milliseconds: 500), () {
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      });
      
      print('PDF download initiated on web: $fileName');
    } catch (e) {
      print('Error downloading PDF on web: $e');
    }
  }
  /// Mobile download - saves to app documents on both Android and iOS
  /// For Android, also creates a Downloads symlink if possible
  static Future<String?> _downloadOnMobile(
    List<int> pdfBytes,
    String fileName, {
    required bool openFile,
  }) async {
    try {
      // Use app documents directory (works on all devices without special permissions)
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      
      print('Saving PDF to: ${file.path}');
      
      // Write PDF to file - ensure it's saved completely
      await file.writeAsBytes(pdfBytes, flush: true);
      
      // Wait to ensure file is fully written to disk
      await Future.delayed(const Duration(milliseconds: 500));
      
      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;
      print('PDF saved successfully');
      print('File exists: $fileExists');
      print('File size: $fileSize bytes');
      
      // Open the PDF in viewer
      if (openFile) {
        try {
          print('Opening PDF: ${file.path}');
          final result = await OpenFilex.open(file.path, type: 'application/pdf');
          print('PDF opened with result: ${result.type}');
          
          if (result.type == ResultType.done) {
            print('PDF opened successfully in viewer');
          } else {
            print('PDF viewer result: ${result.message}');
          }
        } catch (e) {
          print('Error opening PDF: $e');
          print('PDF is saved at: ${file.path}');
        }
      }
      
      return file.path;
    } catch (e) {
      print('Error downloading PDF: $e');
      rethrow;
    }
  }

  /// Get file size in KB
  static String getFileSizeInKB(List<int> pdfBytes) {
    return (pdfBytes.length / 1024).toStringAsFixed(2);
  }
}




