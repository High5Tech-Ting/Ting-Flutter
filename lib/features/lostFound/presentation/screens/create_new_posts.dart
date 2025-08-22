import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ting/shared/widgets/primary_button.dart';
import 'package:uuid/uuid.dart';
import 'package:ting/shared/theme.dart';

class CreateNewPosts extends StatefulWidget {
  const CreateNewPosts({super.key});

  @override
  State<CreateNewPosts> createState() => _CreateNewPostsState();
}

class _CreateNewPostsState extends State<CreateNewPosts> {
  final TextEditingController _postController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  String _selectedType = 'lost'; // 'lost' or 'found'
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _createPost() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to post')),
      );
      return;
    }

    if (_postController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add text or an image to your post'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user data
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data();
      final userName =
          userData?['displayName'] ?? currentUser.email ?? 'Anonymous';
      final userPhotoUrl = userData?['photoURL'];

      String? imageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        final String uuid = const Uuid().v4();
        final String filename =
            'forum_posts/${currentUser.uid}_${timestamp}_$uuid';

        // Upload to Firebase Storage
        final storageRef = _storage.ref().child(filename);

        // Add content type metadata
        final SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': currentUser.uid},
        );

        final uploadTask = storageRef.putFile(_selectedImage!, metadata);

        // Get download URL after upload completes
        final TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Create post document
      await _firestore.collection('lost_found_items').add({
        'userId': currentUser.uid,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'text': _postController.text.trim(),
        'textLowerCase': _postController.text.trim().toLowerCase(),
        'imageUrl': imageUrl,
        'type': _selectedType,
        'status': 'open',
        'comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add new lost or found item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selection
            const Text(
              'Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.search, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        const Text('Lost Item'),
                      ],
                    ),
                    value: 'lost',
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text('Found Item'),
                      ],
                    ),
                    value: 'found',
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _postController,
              maxLines: 8,
              minLines: 6,
              decoration: InputDecoration(
                hintText: _selectedType == 'lost'
                    ? "Describe the item you lost..."
                    : "Describe the item you found...",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
            ),

            // Image preview
            if (_selectedImage != null) ...[
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    onPressed: _removeImage,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_selectedImage == null)
                  OutlinedButton.icon(
                    onPressed: _showImageSourceActionSheet,
                    icon: const Icon(Icons.image),
                    label: Text(
                      'Add Image',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 16.0,
                        color: AppTheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                PrimaryButton(
                  onPressed: _isLoading
                      ? null
                      : () async => await _createPost(),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
