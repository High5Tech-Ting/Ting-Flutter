import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiClient {
  static final Dio _dio = Dio();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Base URL for your API
  static const String _baseUrl =
      'https://ting-ai-5ed339577b51.herokuapp.com/api';

  static ApiClient? _instance;

  ApiClient._internal() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get JWT token from Firebase Auth
          final user = _auth.currentUser;
          if (user != null) {
            try {
              final token = await user.getIdToken();
              options.headers['Authorization'] = 'Bearer $token';
            } catch (e) {
              print('Error getting auth token: $e');
            }
          }

          options.headers['Content-Type'] = 'application/json';
          handler.next(options);
        },
        onError: (error, handler) {
          print('API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  // Summarize chat messages
  Future<ChatSummaryResponse> summarizeMessages(List<String> messages) async {
    try {
      final response = await _dio.post(
        '/chat/summarize',
        data: {'messages': messages},
      );

      return ChatSummaryResponse.fromJson(response.data);
    } catch (e) {
      throw ApiException('Failed to summarize messages: ${e.toString()}');
    }
  }

  // Generic method for API calls
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParameters);
    } catch (e) {
      throw ApiException('GET request failed: ${e.toString()}');
    }
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    try {
      return await _dio.post(endpoint, data: data);
    } catch (e) {
      throw ApiException('POST request failed: ${e.toString()}');
    }
  }

  Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      return await _dio.put(endpoint, data: data);
    } catch (e) {
      throw ApiException('PUT request failed: ${e.toString()}');
    }
  }

  Future<Response> delete(String endpoint) async {
    try {
      return await _dio.delete(endpoint);
    } catch (e) {
      throw ApiException('DELETE request failed: ${e.toString()}');
    }
  }
}

// Response model for chat summary
class ChatSummaryResponse {
  final String message;
  final bool success;
  final String summary;
  final ApiUser? user;

  ChatSummaryResponse({
    required this.message,
    required this.success,
    required this.summary,
    this.user,
  });

  factory ChatSummaryResponse.fromJson(Map<String, dynamic> json) {
    return ChatSummaryResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
      summary: json['summary'] ?? '',
      user: json['user'] != null ? ApiUser.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'success': success,
      'summary': summary,
      'user': user?.toJson(),
    };
  }

  // Helper getter to extract message count from the message field
  int get messageCount {
    // Extract number from message like "Successfully summarized 5 messages"
    final regex = RegExp(r'Successfully summarized (\d+) messages');
    final match = regex.firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 0;
  }
}

// User model for API response
class ApiUser {
  final String email;
  final String uid;

  ApiUser({required this.email, required this.uid});

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(email: json['email'] ?? '', uid: json['uid'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'uid': uid};
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
