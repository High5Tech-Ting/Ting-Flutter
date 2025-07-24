import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:ting/shared/theme.dart';

class ProfileAvatar extends StatefulWidget {
  final double size;
  final VoidCallback? onEditPressed;
  final bool isEditable;

  const ProfileAvatar({
    super.key,
    required this.size,
    this.onEditPressed,
    this.isEditable = true,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? currentUser;
  String? profilePictureUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      currentUser = _auth.currentUser;

      if (currentUser != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            profilePictureUrl = userDoc.data()?['profilePictureUrl'];
            isLoading = false;
          });
        } else {
          await _firestore.collection('users').doc(currentUser!.uid).set({
            'email': currentUser!.email,
            'displayName': currentUser!.displayName,
            'profilePictureUrl': currentUser!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            profilePictureUrl = currentUser!.photoURL;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user: ${e.toString()}');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleImageUpload(BuildContext context) async {
    try {
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to update profile picture'),
          ),
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() {
        isLoading = true;
      });

      // Get file size to check if it's not too large
      final File imageFile = File(image.path);
      final int fileSize = await imageFile.length();

      // Limit file size to 5MB (adjust as needed)
      if (fileSize > 5 * 1024 * 1024) {
        setState(() {
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Image is too large. Please select an image smaller than 5MB.',
              ),
            ),
          );
        }
        return;
      }

      // Create a unique filename with timestamp to avoid conflicts
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = '${currentUser!.uid}_$timestamp';

      // Upload image to Firebase Storage with metadata
      final storageRef = _storage.ref().child('profile_pictures/$filename');

      // Add content type metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': currentUser!.uid},
      );

      // Upload with retry logic
      UploadTask? uploadTask;
      try {
        uploadTask = storageRef.putFile(imageFile, metadata);

        // Add status listener
        uploadTask.snapshotEvents.listen(
          (TaskSnapshot snapshot) {
            print(
              'Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}',
            );
          },
          onError: (error) {
            print('Upload error: $error');
          },
        );

        // Wait for upload to complete
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'profilePictureUrl': downloadUrl,
        });

        // Update Firebase Auth user profile
        await currentUser!.updatePhotoURL(downloadUrl);

        await _loadUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
            ),
          );
        }
      } catch (uploadError) {
        print('Upload specific error: $uploadError');
        // Cancel the upload if it's still in progress
        if (uploadTask != null) {
          uploadTask.cancel();
        }
        throw uploadError; // Rethrow to be caught by outer catch block
      }
    } catch (e) {
      print('Error uploading image: ${e.toString()}');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString().split('\n')[0]}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipOval(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : profilePictureUrl != null
                ? CachedNetworkImage(
                    imageUrl: profilePictureUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => _buildDefaultAvatar(),
                  )
                : _buildDefaultAvatar(),
          ),
        ),
        if (widget.isEditable && currentUser != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: widget.onEditPressed ?? () => _handleImageUpload(context),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    final String? displayName =
        currentUser?.displayName ?? currentUser?.email?.split('@').first;
    final String initial = displayName != null && displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    return Container(
      color: Colors.blue.shade200,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size / 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
