/// Central application configuration.
///
/// The API base URL is environment-aware and overridable at build time via
/// `--dart-define=API_BASE_URL=...`. During local development from an Android
/// emulator the host machine is reached via `10.0.2.2`. For a physical device
/// or a real server pass the desired URL through `--dart-define`.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Default development base URL (host and port only, without the prefix).
///
/// Points at the host machine on the local network so a physical Android
/// device (e.g. MI 8) on the same LAN can reach the Laravel server. Override
/// via `--dart-define=API_BASE_URL=...` when the address differs (e.g. when
/// using the Android emulator's `10.0.2.2` host alias or a remote server).
const String _defaultDevBaseUrl = 'http://10.0.2.2:8000';

/// Resolves the API base URL for the current build.
///
/// Priority:
///  1. `API_BASE_URL` passed via `--dart-define` (highest).
///  2. `AppEnvironment` selection.
class AppConfig {
  AppConfig._();

  /// The API path prefix that the Laravel backend expects.
  static const String apiPrefix = '/api/v1';

  /// Connection timeout for outgoing requests.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Response receive timeout.
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// The base URL (host and port, no prefix) for this run.
  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return _normalize(fromDefine);
    }

    if (!kIsWeb && Platform.isAndroid) {
      return _normalize(_defaultDevBaseUrl);
    }

    return _normalize(_defaultDevBaseUrl);
  }

  /// Full API base URL including the version prefix.
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  static String _normalize(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
