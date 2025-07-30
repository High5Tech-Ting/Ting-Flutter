class ChatSummaryResponse {
  final String message;
  final bool success;
  final String summary;

  ChatSummaryResponse({
    required this.message,
    required this.success,
    required this.summary,
  });

  factory ChatSummaryResponse.fromJson(Map<String, dynamic> json) {
    return ChatSummaryResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
      summary: json['summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'success': success, 'summary': summary};
  }

  int get messageCount {
    final regex = RegExp(r'Successfully summarized (\d+) messages');
    final match = regex.firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 0;
  }
}

class MessageContext {
  final String senderRole;
  final String receiverRole;

  MessageContext({required this.senderRole, required this.receiverRole});

  Map<String, dynamic> toJson() {
    return {'sender_role': senderRole, 'receiver_role': receiverRole};
  }

  factory MessageContext.fromJson(Map<String, dynamic> json) {
    return MessageContext(
      senderRole: json['sender_role'] ?? '',
      receiverRole: json['receiver_role'] ?? '',
    );
  }
}
