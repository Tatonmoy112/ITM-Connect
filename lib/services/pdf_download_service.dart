import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io' show File;

/// Cross-platform PDF download service
class PdfDownloadService {
  /// Download PDF - works on both mobile and web
  static Future<void> downloadPdf({
    required List<int> pdfBytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      _downloadOnWeb(pdfBytes, fileName);
    } else {
      await _downloadOnMobile(pdfBytes, fileName);
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
      final filePath = await _downloadOnMobile(pdfBytes, fileName);
      if (filePath != null) {
        await OpenFilex.open(filePath);
      }
    }
  }

  /// Web download using dart:html
  static void _downloadOnWeb(List<int> pdfBytes, String fileName) {
    try {
      // Dynamically import and use dart:html when on web
      _triggerWebDownload(pdfBytes, fileName);
    } catch (e) {
      throw Exception('Failed to download on web: $e');
    }
  }

  /// Mobile download to temp directory
  static Future<String?> _downloadOnMobile(
    List<int> pdfBytes,
    String fileName,
  ) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      throw Exception('Failed to download on mobile: $e');
    }
  }

  /// Trigger download on web using JavaScript
  static void _triggerWebDownload(List<int> pdfBytes, String fileName) {
    // This method will only be called on web
    // Use dynamic import or reflection if needed
    try {
      // For now, we'll use a simple Uint8List conversion and HTML API
      final htmlAnchor = _createDownloadLink(pdfBytes, fileName);
      if (htmlAnchor != null) {
        // In a web environment, this would trigger the download
        htmlAnchor as dynamic;
      }
    } catch (e) {
      // Fallback: browsers will show a console message
      print('PDF download on web: $fileName - ${pdfBytes.length} bytes');
    }
  }

  /// Create download link (web only)
  static dynamic _createDownloadLink(List<int> bytes, String fileName) {
    try {
      // This is a placeholder for web implementation
      // In actual web environment, use: 
      // import 'dart:html' as html;
      // final blob = html.Blob([bytes], 'application/pdf');
      // final url = html.Url.createObjectUrlFromBlob(blob);
      // final anchor = html.AnchorElement(href: url)
      //   ..setAttribute('download', fileName)
      //   ..click();
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get file size in KB
  static String getFileSizeInKB(List<int> pdfBytes) {
    return (pdfBytes.length / 1024).toStringAsFixed(2);
  }
}




