import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io' show File, Directory, Platform;
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

  /// Mobile download to external storage (Downloads) on Android, app documents on iOS
  static Future<String?> _downloadOnMobile(
    List<int> pdfBytes,
    String fileName, {
    required bool openFile,
  }) async {
    try {
      Directory? directory;
      
      // On Android, try to save to Downloads folder
      if (Platform.isAndroid) {
        try {
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            print('Using external storage directory: ${directory.path}');
          }
        } catch (e) {
          print('Could not access external storage: $e');
        }
      }
      
      // Fallback to app documents directory
      directory ??= await getApplicationDocumentsDirectory();
      
      final file = File('${directory.path}/$fileName');
      
      // Write PDF to file
      await file.writeAsBytes(pdfBytes);
      
      print('PDF saved to: ${file.path}');
      print('File exists: ${await file.exists()}');
      print('File size: ${await file.length()} bytes');
      
      // Open file if requested
      if (openFile) {
        try {
          final result = await OpenFilex.open(file.path, type: 'application/pdf');
          print('PDF opened with result: ${result.type}');
          
          // If opening failed, show where file was saved
          if (result.type != ResultType.done) {
            print('Warning: PDF viewer may not be available: ${result.message}');
            print('PDF saved at: ${file.path}');
          }
        } catch (e) {
          print('Error opening PDF with OpenFilex: $e');
          print('PDF saved at: ${file.path}');
          // Don't rethrow - file was saved successfully even if we can't open it
        }
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




