import 'dart:io';

abstract class BaseMessageService {
  /// Send a text message
  Future<void> sendTextMessage({
    required String messageText,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
  });

  /// Send a message with attachment
  Future<void> sendAttachmentMessage({
    required String messageText,
    required File file,
    required String fileName,
    required String fileType,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
  });

  /// Upload file and get URL
  Future<String?> uploadFile({
    required File file,
    required String fileName,
    required String fileType,
    Map<String, String>? customMetadata,
  });
}
