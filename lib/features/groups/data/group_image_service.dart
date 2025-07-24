import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GroupImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Validates and returns an image file selected from the gallery or camera
  static Future<File?> pickAndValidateImage(
    BuildContext context, {
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return null;

      // Get file size to check if it's not too large
      final File imageFile = File(image.path);
      final int fileSize = await imageFile.length();

      // Limit file size to 5MB
      if (fileSize > 5 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Image is too large. Please select an image smaller than 5MB.',
              ),
            ),
          );
        }
        return null;
      }

      return imageFile;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
      return null;
    }
  }

  /// Uploads a group image to Firebase Storage and returns the download URL
  static Future<String?> uploadGroupImage(
    File imageFile,
    String groupId,
  ) async {
    try {
      // Create a unique filename with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = 'group_${groupId}_$timestamp';

      // Upload image to Firebase Storage
      final storageRef = _storage.ref().child('group_images/$filename');

      // Add content type metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'groupId': groupId},
      );

      // Upload file
      final uploadTask = storageRef.putFile(imageFile, metadata);

      // Add upload progress listener
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      }, onError: (e) => print('Upload error: $e'));

      // Wait for upload to complete
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading group image: $e');
      return null;
    }
  }
}
