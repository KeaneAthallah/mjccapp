import '../../core/network/api_client.dart';
import '../../core/network/paginated.dart';
import '../models/sos_alert.dart';

/// Repository for the SOS/emergency module.
class SosRepository {
  Future<Paginated<SosAlert>> index({
    int? page,
    int? perPage,
    String? search,
    String? status,
    String? from,
    String? to,
  }) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/sos',
      queryParameters: {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );
    return Paginated<SosAlert>.fromJson(
      response.data!,
      (items) => items
          .whereType<Map<String, dynamic>>()
          .map(SosAlert.fromJson)
          .toList(),
    );
  }

  Future<SosAlert> show(int id) async {
    final response = await ApiClient.instance.dio
        .get<Map<String, dynamic>>('/sos/$id');
    final data = response.data!['data'];
    return SosAlert.fromJson(data as Map<String, dynamic>);
  }

  Future<SosAlert?> myOpen() async {
    final response = await ApiClient.instance.dio
        .get<Map<String, dynamic>>('/sos/my-open');
    final data = response.data!['data'];
    if (data is! Map<String, dynamic>) return null;
    return SosAlert.fromJson(data);
  }

  Future<SosAlert> create({
    required double latitude,
    required double longitude,
    double? accuracy,
    String? message,
  }) async {
    final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
      '/sos',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'message': message,
      },
    );
    return SosAlert.fromJson(ApiClient.envelopeData(response));
  }

  Future<SosAlert> acknowledge(int id, {String? message}) async {
    return _transition(id, 'acknowledge', message);
  }

  Future<SosAlert> respond(int id, {String? message}) async {
    return _transition(id, 'respond', message);
  }

  Future<SosAlert> resolve(int id, {String? message}) async {
    return _transition(id, 'resolve', message);
  }

  Future<SosAlert> cancel(int id) async {
    final response = await ApiClient.instance.dio
        .post<Map<String, dynamic>>('/sos/$id/cancel');
    return SosAlert.fromJson(ApiClient.envelopeData(response));
  }

  Future<Map<String, int>> activeCount() async {
    final response = await ApiClient.instance.dio
        .get<Map<String, dynamic>>('/sos/active-count');
    final data = response.data!['data'];
    if (data is! Map<String, dynamic>) return const {};
    return data.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  Future<SosAlert> _transition(int id, String action, String? message) async {
    final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
      '/sos/$id/$action',
      data: {if (message != null && message.isNotEmpty) 'response_message': message},
    );
    return SosAlert.fromJson(ApiClient.envelopeData(response));
  }
}