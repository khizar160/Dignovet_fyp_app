import 'dart:io';
import 'dart:developer';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FileDownloadService {
  static Future<String?> downloadPdf({
    required String url,
    required String fileName,
  }) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        log('[FileDownloadService] Invalid URL: $url');
        return null;
      }

      log('[FileDownloadService] Starting download: $fileName from $url');
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode != 200) {
        log('[FileDownloadService] Download failed with status ${response.statusCode}');
        return null;
      }

      if (response.bodyBytes.isEmpty) {
        log('[FileDownloadService] Response body is empty');
        return null;
      }

      final normalizedName = fileName.toLowerCase().endsWith('.pdf')
          ? fileName
          : '$fileName.pdf';

      log('[FileDownloadService] File size: ${response.bodyBytes.length} bytes');

      // Try native file dialog first
      try {
        final savedPath = await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(
            data: response.bodyBytes,
            fileName: normalizedName,
            mimeTypesFilter: const ['application/pdf'],
          ),
        );

        if (savedPath != null && savedPath.isNotEmpty) {
          log('[FileDownloadService] File saved via dialog: $savedPath');
          return savedPath;
        }
      } catch (e) {
        log('[FileDownloadService] Native dialog failed: $e. Using fallback...');
      }

      // Fallback: Save to Documents folder
      try {
        final directory = await getApplicationDocumentsDirectory();
        final sanitizedName = normalizedName.replaceAll(RegExp(r'[<>:"|?*]'), '_');
        final filePath = '${directory.path}/$sanitizedName';
        final file = File(filePath);
        
        await file.writeAsBytes(response.bodyBytes, flush: true);
        log('[FileDownloadService] File saved to fallback path: $filePath');
        return file.path;
      } catch (e) {
        log('[FileDownloadService] Fallback save failed: $e');
        return null;
      }
    } catch (e) {
      log('[FileDownloadService] Error: $e');
      return null;
    }
  }
}
