import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/theme.dart';
import '../../../../shared/services/attachment_service.dart';
import 'attachment_picker_bottom_sheet.dart';
import 'attachment_preview_widget.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController messageController;
  final bool isSending;
  final String? replyToText;
  final String? replyToSenderId;
  final void Function(String messageText, AttachmentFile? attachment)
  onSendMessage;
  final VoidCallback onCancelReply;
  final Future<String> Function(String?)? getUserName;

  const ChatInputWidget({
    super.key,
    required this.messageController,
    required this.isSending,
    required this.onSendMessage,
    required this.onCancelReply,
    this.replyToText,
    this.replyToSenderId,
    this.getUserName,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  File? _selectedFile;
  String? _selectedFileType;
  String? _selectedFileName;

  bool get hasSelectedFile => _selectedFile != null;

  AttachmentFile? get selectedAttachment {
    if (_selectedFile != null &&
        _selectedFileType != null &&
        _selectedFileName != null) {
      return AttachmentFile(
        file: _selectedFile!,
        fileName: _selectedFileName!,
        fileType: _selectedFileType!,
      );
    }
    return null;
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentPickerBottomSheet(
        onPickImageFromGallery: () => _pickImage(ImageSource.gallery),
        onPickImageFromCamera: () => _pickImage(ImageSource.camera),
        onPickVideoFromGallery: () => _pickVideo(ImageSource.gallery),
        onPickVideoFromCamera: () => _pickVideo(ImageSource.camera),
        onPickDocument: _pickDocument,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await AttachmentService.pickImage(source);
    if (file != null) {
      setState(() {
        _selectedFile = file;
        _selectedFileType = 'image';
        _selectedFileName =
            'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final file = await AttachmentService.pickVideo(source);
    if (file != null) {
      setState(() {
        _selectedFile = file;
        _selectedFileType = 'video';
        _selectedFileName =
            'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      });
    }
  }

  Future<void> _pickDocument() async {
    final attachmentFile = await AttachmentService.pickDocument(context);
    if (attachmentFile != null) {
      setState(() {
        _selectedFile = attachmentFile.file;
        _selectedFileType = attachmentFile.fileType;
        _selectedFileName = attachmentFile.fileName;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "${attachmentFile.fileName}" selected'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _removeSelectedFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileType = null;
      _selectedFileName = null;
    });
  }

  void _onSendPressed() {
    if (widget.messageController.text.isEmpty && !hasSelectedFile) return;
    final messageText = widget.messageController.text;
    widget.onSendMessage(messageText, selectedAttachment);
    _removeSelectedFile();
    widget.messageController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Reply preview
        if (widget.replyToText != null)
          Container(
            color: Colors.grey[200],
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.getUserName != null &&
                          widget.replyToSenderId != null)
                        FutureBuilder<String>(
                          future: widget.getUserName!(widget.replyToSenderId!),
                          builder: (context, snapshot) {
                            return Text(
                              'Replying to ${snapshot.data ?? 'Unknown'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.primary,
                              ),
                            );
                          },
                        )
                      else
                        Text(
                          'Replying to message',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.primary,
                          ),
                        ),
                      Text(
                        widget.replyToText!,
                        style: TextStyle(fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: widget.onCancelReply,
                ),
              ],
            ),
          ),

        // Attachment preview
        if (_selectedFile != null)
          AttachmentPreviewWidget(
            file: _selectedFile!,
            fileType: _selectedFileType!,
            fileName: _selectedFileName!,
            onRemove: _removeSelectedFile,
          ),

        // Message input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _showAttachmentOptions,
                icon: Icon(Icons.attach_file_outlined),
              ),
              Expanded(
                child: TextField(
                  controller: widget.messageController,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              widget.isSending
                  ? Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _onSendPressed,
                      icon: const Icon(Icons.send),
                      style: ButtonStyle(
                        iconColor: WidgetStatePropertyAll(AppTheme.surface),
                        backgroundColor: WidgetStatePropertyAll(
                          AppTheme.primary,
                        ),
                        padding: WidgetStatePropertyAll(EdgeInsets.all(10)),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
