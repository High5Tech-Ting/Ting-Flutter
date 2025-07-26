import 'package:flutter/material.dart';
import 'package:ting/shared/theme.dart';
import 'package:ting/core/services/message_service.dart';
import 'package:ting/features/chat/presentation/screens/image_preview_screen.dart';
import 'package:ting/features/chat/presentation/screens/video_preview_screen.dart';
import 'package:ting/services/document_download_service.dart';
import 'dart:io';

class MessageBubble extends StatefulWidget {
  final String message;
  final bool isSender;
  final String time;
  final Widget? statusIcon;
  final String conversationId;
  final String messageId;
  final String senderId;
  final String currentUserId;
  final bool isDeletedForEveryone;
  final List<String> deletedFor;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;
  final void Function(String messageId, String text, String senderId)? onReply;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSender,
    required this.time,
    this.statusIcon,
    required this.conversationId,
    required this.messageId,
    required this.senderId,
    required this.currentUserId,
    required this.isDeletedForEveryone,
    required this.deletedFor,
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
    required this.onReply,
    this.fileUrl,
    this.fileType,
    this.fileName,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isAlreadyDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkIfFileExists();
  }

  Future<void> _checkIfFileExists() async {
    if (widget.fileType == 'document' && widget.fileName != null) {
      final exists = await DocumentDownloadService.isDocumentAlreadyDownloaded(
        widget.fileName!,
      );
      if (mounted) {
        setState(() {
          _isAlreadyDownloaded = exists;
        });
      }
    }
  }

  Future<void> _downloadDocument(BuildContext context) async {
    if (_isDownloading || widget.fileUrl == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final fileName = widget.fileName ?? 'document';

    try {
      final filePath = await DocumentDownloadService.downloadDocument(
        url: widget.fileUrl!,
        fileName: fileName,
        context: context,
        autoOpen: true, // Auto-open the file after download
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      setState(() {
        _isDownloading = false;
      });

      if (filePath != null && mounted) {
        // Update the downloaded state
        setState(() {
          _isAlreadyDownloaded = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Document opened!\nLocation: ${Platform.isAndroid ? "Downloads/Ting/" : "Documents/"}$fileName',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Open Again',
              textColor: Colors.white,
              onPressed: () async {
                await DocumentDownloadService.openDownloadedFile(filePath);
              },
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Delete message?'),
        children: [
          SimpleDialogOption(
            child: Text('Delete for me'),
            onPressed: () async {
              Navigator.pop(context);
              await deleteMessageForMe(
                widget.conversationId,
                widget.messageId,
                widget.currentUserId,
              );
            },
          ),
          if (widget.senderId == widget.currentUserId)
            SimpleDialogOption(
              child: Text('Delete for everyone'),
              onPressed: () async {
                Navigator.pop(context);
                await deleteMessageForEveryone(
                  widget.conversationId,
                  widget.messageId,
                );
              },
            ),
          SimpleDialogOption(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDeletedForEveryone) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: widget.isSender
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "This message was deleted",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (widget.deletedFor.contains(widget.currentUserId)) {
      return const SizedBox.shrink();
    }

    Widget content = Text(
      widget.message,
      style: TextStyle(
        color: widget.isSender ? Colors.white : Colors.black,
        fontSize: 16,
      ),
    );

    return GestureDetector(
      onLongPress: () {
        _showDeleteDialog(context);
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0 && widget.onReply != null) {
          widget.onReply!(widget.messageId, widget.message, widget.senderId);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: widget.isSender
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: IntrinsicWidth(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: widget.isSender ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(8),
                      bottomLeft: Radius.circular(widget.isSender ? 8 : 0),
                      bottomRight: Radius.circular(widget.isSender ? 0 : 8),
                      topRight: const Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.replyToText != null)
                        Container(
                          margin: EdgeInsets.only(bottom: 4),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.replyToText!,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      content,
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.time,
                              style: TextStyle(
                                color: widget.isSender
                                    ? Colors.white
                                    : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            if (widget.statusIcon != null) ...[
                              const SizedBox(width: 4),
                              widget.statusIcon!,
                            ],
                          ],
                        ),
                      ),
                      if (widget.fileUrl != null && widget.fileType != null)
                        if (widget.fileType == 'image')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ImagePreviewScreen(
                                      imageUrl: widget.fileUrl!,
                                      fileName: widget.fileName,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.fileUrl!,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          width: 200,
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          )
                        else if (widget.fileType == 'video')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoPreviewScreen(
                                      videoUrl: widget.fileUrl!,
                                      fileName: widget.fileName,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.all(8),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Row(
                                      spacing: 8.0,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow,
                                            size: 30,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            widget.fileName ?? 'Video',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else if (widget.fileType == 'document')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: InkWell(
                              onTap: () async {
                                await _downloadDocument(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: widget.isSender
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  children: [
                                    if (_isDownloading) ...[
                                      LinearProgressIndicator(
                                        value: _downloadProgress,
                                        backgroundColor: Colors.grey[300],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              widget.isSender
                                                  ? Colors.white
                                                  : AppTheme.primary,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Downloading... ${(_downloadProgress * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isSender
                                              ? Colors.white70
                                              : Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.insert_drive_file,
                                          color: Colors.blue[700],
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.fileName ?? 'Document',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: widget.isSender
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    _isDownloading
                                                        ? Icons.downloading
                                                        : _isAlreadyDownloaded
                                                        ? Icons.open_in_new
                                                        : Icons.download,
                                                    size: 14,
                                                    color: widget.isSender
                                                        ? Colors.white70
                                                        : Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _isDownloading
                                                        ? 'Downloading...'
                                                        : _isAlreadyDownloaded
                                                        ? 'Tap to open'
                                                        : 'Tap to download',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: widget.isSender
                                                          ? Colors.white70
                                                          : Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
