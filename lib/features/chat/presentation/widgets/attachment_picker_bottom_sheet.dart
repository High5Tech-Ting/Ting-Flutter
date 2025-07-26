import 'package:flutter/material.dart';
import '../../../../shared/theme.dart';

class AttachmentPickerBottomSheet extends StatelessWidget {
  final VoidCallback onPickImageFromGallery;
  final VoidCallback onPickImageFromCamera;
  final VoidCallback onPickVideoFromGallery;
  final VoidCallback onPickVideoFromCamera;
  final VoidCallback onPickDocument;

  const AttachmentPickerBottomSheet({
    super.key,
    required this.onPickImageFromGallery,
    required this.onPickImageFromCamera,
    required this.onPickVideoFromGallery,
    required this.onPickVideoFromCamera,
    required this.onPickDocument,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppTheme.primary),
            title: const Text('Photo from Gallery'),
            onTap: () {
              Navigator.pop(context);
              onPickImageFromGallery();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
            title: const Text('Take a Photo'),
            onTap: () {
              Navigator.pop(context);
              onPickImageFromCamera();
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: AppTheme.primary),
            title: const Text('Video from Gallery'),
            onTap: () {
              Navigator.pop(context);
              onPickVideoFromGallery();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.video_camera_back,
              color: AppTheme.primary,
            ),
            title: const Text('Record Video'),
            onTap: () {
              Navigator.pop(context);
              onPickVideoFromCamera();
            },
          ),
          ListTile(
            leading: const Icon(Icons.description, color: AppTheme.primary),
            title: const Text('Document'),
            onTap: () {
              Navigator.pop(context);
              onPickDocument();
            },
          ),
          ListTile(
            leading: const Icon(Icons.close, color: Colors.grey),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
