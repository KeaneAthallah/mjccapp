/// Generic wrapper around the consistent Laravel API envelope:
/// `{ success, message, data, meta?, errors? }`.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
    this.errors,
  });

  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? errors;

  bool get hasData => data != null;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(Map<String, dynamic>? data)? parse,
  ) {
    final rawData = json['data'];
    T? parsed;

    if (rawData is Map<String, dynamic> && parse != null) {
      parsed = parse(rawData);
    } else if (rawData is T) {
      parsed = rawData;
    }

    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: parsed,
      meta: json['meta'] as Map<String, dynamic>?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}
