import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:open_file/open_file.dart';

class DocumentDownloadService {
  static final Dio _dio = Dio();

  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Check Android version
      var androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        // For Android 13+ (API 33+)
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          return status.isGranted;
        }
        return true;
      } else if (androidInfo.version.sdkInt >= 30) {
        // For Android 11-12 (API 30-32)
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          return status.isGranted;
        }
        return true;
      } else {
        // For Android 10 and below
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          return status.isGranted;
        }
        return true;
      }
    }
    return true;
  }

  static Future<String?> downloadDocument({
    required String url,
    required String fileName,
    required BuildContext context,
    Function(double)? onProgress,
    bool autoOpen = false,
  }) async {
    try {
      // Request storage permission
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to download files'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }

      // Get the downloads directory
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        // Try to get the Downloads directory
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          // Fallback to external storage directory
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // For iOS, use the app's documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception('Could not access storage directory');
      }

      // Create Ting folder in Downloads
      final tingFolder = Directory('${downloadsDir.path}/Ting');
      if (!await tingFolder.exists()) {
        await tingFolder.create(recursive: true);
      }

      final filePath = '${tingFolder.path}/$fileName';

      // Check if file already exists
      if (await File(filePath).exists()) {
        debugPrint('File already exists: $filePath');

        // Show user feedback that file already exists
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File already downloaded: $fileName'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Auto-open the existing file if requested
        if (autoOpen) {
          await openDownloadedFile(filePath);
        }

        return filePath;
      } else {
        // File doesn't exist, proceed with download
        debugPrint('Downloading file: $fileName');

        await _dio.download(
          url,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1 && onProgress != null) {
              onProgress(received / total);
            }
          },
        );

        // Auto-open the downloaded file if requested
        if (autoOpen) {
          await openDownloadedFile(filePath);
        }

        return filePath;
      }
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  /// Opens a downloaded file using the default application
  static Future<void> openDownloadedFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      debugPrint('File open result: ${result.message}');

      if (result.type != ResultType.done) {
        debugPrint('Failed to open file: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  /// Check if a document already exists in the downloads folder
  static Future<bool> isDocumentAlreadyDownloaded(String fileName) async {
    try {
      // Get the downloads directory
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) {
        return false;
      }

      final tingFolder = Directory('${downloadsDir.path}/Ting');
      final filePath = '${tingFolder.path}/$fileName';

      return await File(filePath).exists();
    } catch (e) {
      debugPrint('Error checking if file exists: $e');
      return false;
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
