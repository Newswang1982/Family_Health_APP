import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;

  factory ApiClient({String? baseUrl}) {
    if (baseUrl != null) {
      _instance._dio.options.baseUrl = baseUrl;
    }
    return _instance;
  }

  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  /// Returns the current base URL
  String get baseUrl => _dio.options.baseUrl;

  /// Update the base URL at runtime (for switching between local/dev/prod)
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  ApiClient._internal() {
    // Default to localhost; override with env var or build config
    // In production, set this to your cloud server URL
    const defaultUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080/api/v1',
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: defaultUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_secureStorage),
      if (kDebugMode) _LogInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.get<T>(path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.post<T>(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.put<T>(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.patch<T>(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.delete<T>(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  _AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.path.contains('/auth/')) {
      return handler.next(options);
    }
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
    handler.next(options);
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API] --> ${options.method} ${options.path}');
    if (options.data != null) debugPrint('[API] Body: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[API] <-- ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[API] <-- ERROR ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
    handler.next(err);
  }
}

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic data;

  ApiException({this.statusCode, required this.message, this.data});

  @override
  String toString() =>
      'ApiException($statusCode): $message${data != null ? ' | $data' : ''}';

  factory ApiException.fromDioException(DioException e) {
    final response = e.response;
    final statusCode = response?.statusCode;
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = '连接超时，请检查网络';
        break;
      case DioExceptionType.connectionError:
        message = '无法连接到服务器，请稍后重试';
        break;
      case DioExceptionType.badResponse:
        final data = response?.data;
        if (data is Map<String, dynamic>) {
          message = (data['error'] ?? data['message'] ?? data['detail'] ?? '未知错误').toString();
        } else {
          message = data?.toString() ?? '未知错误';
        }
        break;
      case DioExceptionType.cancel:
        message = '请求已取消';
        break;
      default:
        message = e.message ?? '发生意外错误';
        break;
    }

    return ApiException(statusCode: statusCode, message: message, data: response?.data);
  }
}

void handleDioException(DioException e) {
  throw ApiException.fromDioException(e);
}
