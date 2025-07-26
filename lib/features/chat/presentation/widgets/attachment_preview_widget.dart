import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../shared/services/attachment_service.dart';

class AttachmentPreviewWidget extends StatelessWidget {
  final File file;
  final String fileType;
  final String fileName;
  final VoidCallback onRemove;

  const AttachmentPreviewWidget({
    super.key,
    required this.file,
    required this.fileType,
    required this.fileName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildFilePreview(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileType.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AttachmentService.getFileTypeColor(fileType),
                  ),
                ),
                Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (fileType == 'document')
                  Text(
                    AttachmentService.getFileSizeText(file),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    if (fileType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(file, width: 60, height: 60, fit: BoxFit.cover),
      );
    } else {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AttachmentService.getFileTypeColor(fileType),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          AttachmentService.getFileTypeIcon(fileType),
          color: Colors.white,
          size: 30,
        ),
      );
    }
  }
}
