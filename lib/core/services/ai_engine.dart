import 'package:ting/core/services/api_client.dart';
import 'package:ting/core/services/types.dart';

class AiEngine {
  static Future<ChatSummaryResponse> summarizeMessages(
    List<String> messages,
  ) async {
    try {
      final response = await ApiClient.post(
        '/chat/summarize',
        data: {'messages': messages},
      );

      return ChatSummaryResponse.fromJson(response.data);
    } catch (e) {
      throw ApiException('Failed to summarize messages: ${e.toString()}');
    }
  }

  static Future<String> generateMessageDraft(
    List<Map<String, String>> messages,
    MessageContext context,
  ) async {
    try {
      final response = await ApiClient.post(
        '/chat/generate-message',
        data: {'recent_messages': messages, 'context': context.toJson()},
      );

      return response.data;
    } catch (e) {
      throw ApiException('Failed to generate message draft: ${e.toString()}');
    }
  }

  static Future<ModeratedMessageResponse> moderateMessage(
    String message,
  ) async {
    try {
      final response = await ApiClient.post(
        '/chat/moderate',
        data: {'message': message},
      );
      return ModeratedMessageResponse.fromJson(response.data);
    } catch (e) {
      throw ApiException('Failed to moderate message: ${e.toString()}');
    }
  }
}
