import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AttachmentService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Pick image from gallery or camera
  static Future<File?> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print('Error picking image: $e');
    }
    return null;
  }

  /// Pick video from gallery or camera
  static Future<File?> pickVideo(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 1),
      );

      if (video != null) {
        return File(video.path);
      }
    } catch (e) {
      print('Error picking video: $e');
    }
    return null;
  }

  /// Pick document
  static Future<AttachmentFile?> pickDocument(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'rtf',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'zip',
          'rar',
          '7z',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        PlatformFile file = result.files.first;

        // Check file size (limit to 10MB)
        final fileSizeInMB = (file.size) / (1024 * 1024);
        if (fileSizeInMB > 10) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        }

        return AttachmentFile(
          file: File(file.path!),
          fileName: file.name,
          fileType: 'document',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return null;
  }

  /// Upload file to Firebase Storage
  static Future<String?> uploadFile({
    required File file,
    required String fileName,
    required String fileType,
    required String folderPath,
    Map<String, String>? customMetadata,
  }) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = '${folderPath}/${timestamp}_$fileName';

      final storageRef = _storage.ref().child(filename);

      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(fileType, fileName),
        customMetadata: customMetadata ?? {},
      );

      final uploadTask = storageRef.putFile(file, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Get content type based on file type and name (public method)
  static String getContentType(String fileType, String fileName) {
    return _getContentType(fileType, fileName);
  }

  /// Get content type based on file type and name
  static String _getContentType(String fileType, String fileName) {
    switch (fileType) {
      case 'image':
        return 'image/jpeg';
      case 'video':
        return 'video/mp4';
      case 'document':
        final extension = fileName.toLowerCase();
        if (extension.endsWith('.pdf')) return 'application/pdf';
        if (extension.endsWith('.doc')) return 'application/msword';
        if (extension.endsWith('.docx')) {
          return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        }
        if (extension.endsWith('.txt')) return 'text/plain';
        if (extension.endsWith('.rtf')) return 'application/rtf';
        if (extension.endsWith('.xls')) return 'application/vnd.ms-excel';
        if (extension.endsWith('.xlsx')) {
          return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        }
        if (extension.endsWith('.ppt')) {
          return 'application/vnd.ms-powerpoint';
        }
        if (extension.endsWith('.pptx')) {
          return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
        }
        if (extension.endsWith('.zip')) return 'application/zip';
        if (extension.endsWith('.rar')) return 'application/vnd.rar';
        if (extension.endsWith('.7z')) return 'application/x-7z-compressed';
        return 'application/octet-stream';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get file type color for UI
  static Color getFileTypeColor(String? fileType) {
    switch (fileType) {
      case 'image':
        return Colors.blue;
      case 'video':
        return Colors.purple;
      case 'document':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get file type icon for UI
  static IconData getFileTypeIcon(String? fileType) {
    switch (fileType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'document':
        return Icons.insert_drive_file;
      default:
        return Icons.attach_file;
    }
  }

  /// Get file size text for UI
  static String getFileSizeText(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) {
      return '${bytes} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// Model class for attachment files
class AttachmentFile {
  final File file;
  final String fileName;
  final String fileType;

  AttachmentFile({
    required this.file,
    required this.fileName,
    required this.fileType,
  });
}
