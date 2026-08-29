import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../storage/secure_storage.dart';

  /// Central HTTP client for all API communication.
  ///
  /// Responsibilities:
  ///  - Attach the stored bearer token to every authenticated request.
  ///  - Normalise transport/HTTP errors into [AppException] subtypes.
  ///  - Broadcast authentication-expiry events so the UI can react.
  class ApiClient {

    /// Extracts the `data` field from a JSON envelope body.
    ///
    /// Guards against malformed / non-JSON responses (e.g. an HTML error page
    /// returned when the API is unreachable) by throwing a clean [AppException]
    /// instead of leaking a raw cast error to the UI.
    static Map<String, dynamic> envelopeData(
      Response<dynamic> response, {
      String fallback = 'Respons server tidak valid.',
    }) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic>) return data;
        throw AppException(
          (body['message'] as String?) ?? fallback,
          statusCode: response.statusCode,
        );
      }
      throw AppException(
        (response.statusMessage) ?? fallback,
        statusCode: response.statusCode,
      );
    }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio dio;

  /// Called whenever an authenticated request returns 401.
  void Function()? onUnauthorized;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    final error = _mapError(e) ?? e;
    if (error is UnauthorizedException) {
      onUnauthorized?.call();
    }
    handler.reject(
      error is DioException ? error : _asDio(e, error as AppException),
    );
  }

  AppException? _mapError(DioException e) {
    final response = e.response;
    final status = response?.statusCode;
    final data = response?.data;

    String? message;
    Map<String, dynamic>? errors;

    if (data is Map<String, dynamic>) {
      message = (data['message'] as String?) ?? _statusMessage(status);
      if (data['errors'] is Map<String, dynamic>) {
        errors = data['errors'] as Map<String, dynamic>;
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException(
          'Tidak dapat terhubung ke server. '
          'Periksa koneksi internet Anda dan coba lagi.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          'Tidak dapat terhubung ke server. '
          'Pastikan server sedang berjalan dan periksa koneksi Anda.',
        );
      case DioExceptionType.badCertificate:
        return const NetworkException('Sertifikat server tidak valid.');
      case DioExceptionType.unknown:
        return const NetworkException(
          'Tidak dapat terhubung ke server. '
          'Periksa koneksi internet Anda.',
        );
      case DioExceptionType.badResponse:
        break;
      case DioExceptionType.cancel:
        return null;
    }

    switch (status) {
      case 400:
        return AppException(message ?? 'Permintaan tidak valid.');
      case 401:
        return UnauthorizedException(message ?? 'Anda belum terautentikasi.');
      case 403:
        return ForbiddenException(message ?? 'Anda tidak memiliki akses.');
      case 404:
        return AppException(
          message ?? 'Data tidak ditemukan.',
          statusCode: status,
        );
      case 409:
        return AppException(
          message ?? 'Terjadi konflik data.',
          statusCode: status,
        );
      case 422:
        return ValidationException(message ?? 'Validasi gagal', errors: errors);
      case 429:
        return AppException(
          message ?? 'Terlalu banyak permintaan. Silakan coba lagi nanti.',
          statusCode: status,
        );
      case 500:
      case 502:
      case 503:
        return AppException(
          message ?? 'Terjadi kesalahan pada server.',
          statusCode: status,
        );
      default:
        return AppException(
          message ?? _statusMessage(status) ?? 'Terjadi kesalahan.',
          statusCode: status,
        );
    }
  }

  String? _statusMessage(int? status) {
    return switch (status) {
      401 => 'Anda belum terautentikasi.',
      403 => 'Anda tidak memiliki akses.',
      404 => 'Data tidak ditemukan.',
      422 => 'Validasi gagal',
      429 => 'Terlalu banyak permintaan.',
      500 => 'Terjadi kesalahan pada server.',
      _ => 'Terjadi kesalahan. Silakan coba lagi.',
    };
  }

  DioException _asDio(DioException original, AppException error) {
    return DioException(
      requestOptions: original.requestOptions,
      response: original.response,
      type: original.type,
      error: error,
      message: error.message,
    );
  }
}
