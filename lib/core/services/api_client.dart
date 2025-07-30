import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiClient {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _baseUrl =
      'https://ting-ai-5ed339577b51.herokuapp.com/api';
  static ApiClient? _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio();
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
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

  static Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await instance._dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
    } catch (e) {
      throw ApiException('GET request failed: ${e.toString()}');
    }
  }

  static Future<Response> post(String endpoint, {dynamic data}) async {
    try {
      return await instance._dio.post(endpoint, data: data);
    } catch (e) {
      throw ApiException('POST request failed: ${e.toString()}');
    }
  }

  static Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      return await instance._dio.put(endpoint, data: data);
    } catch (e) {
      throw ApiException('PUT request failed: ${e.toString()}');
    }
  }

  static Future<Response> delete(String endpoint) async {
    try {
      return await instance._dio.delete(endpoint);
    } catch (e) {
      throw ApiException('DELETE request failed: ${e.toString()}');
    }
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
