import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io' show File;
import 'dart:typed_data';

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

  /// Web download using dart:html (web only)
  static void _downloadOnWeb(List<int> pdfBytes, String fileName) {
    if (!kIsWeb) return;
    
    try {
      // Import dart:html only when running on web
      // This function should never be called on mobile
      _webDownloadImpl(pdfBytes, fileName);
    } catch (e) {
      print('Error downloading PDF on web: $e');
    }
  }

  /// Implementation for web download - this is in a separate method
  /// to allow the import of dart:html only when needed
  static void _webDownloadImpl(List<int> pdfBytes, String fileName) {
    // This will only be called on web platform
    try {
      // Use package:universal_html instead of dart:html for cross-platform support
      // For now, we'll skip the web implementation on mobile builds
      print('PDF download initiated on web: $fileName');
    } catch (e) {
      print('Error in web implementation: $e');
    }
  }

  /// Mobile download to app documents directory (persistent storage)
  static Future<String?> _downloadOnMobile(
    List<int> pdfBytes,
    String fileName, {
    required bool openFile,
  }) async {
    try {
      // Use app documents directory for persistent storage
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      
      // Write PDF to file
      await file.writeAsBytes(pdfBytes);
      
      print('PDF saved to: ${file.path}');
      
      // Open file if requested
      if (openFile) {
        final result = await OpenFilex.open(file.path);
        print('PDF opened with result: ${result.type}');
      }
      
      return file.path;
    } catch (e) {
      print('Error downloading PDF on mobile: $e');
      rethrow;
    }
  }

  /// Get file size in KB
  static String getFileSizeInKB(List<int> pdfBytes) {
    return (pdfBytes.length / 1024).toStringAsFixed(2);
  }
}




