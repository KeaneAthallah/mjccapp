import '../../core/network/api_client.dart';
import '../../core/network/paginated.dart';

/// Common helper for talking to the Laravel `apiResource` endpoints.
///
/// Provides index (search/filter/sort/paginate), show, create, update and
/// delete plus (optional) trash/restore/force-delete operations.
class ResourceApi<T> {
  ResourceApi(this._path, {required this.fromJson});

  /// Resource path, e.g. `/schools`.
  final String _path;

  /// Parser for a single item from its JSON map.
  final T Function(Map<String, dynamic> json) fromJson;

  Future<Paginated<T>> index({
    int? page,
    int? perPage,
    String? search,
    Map<String, dynamic>? filters,
    String? sort,
    String? sortDirection,
  }) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      _path,
      queryParameters: {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sort != null) 'sort': sort,
        if (sortDirection != null) 'sort_direction': sortDirection,
        if (filters != null) ...filters,
      },
    );
    final body = response.data!;
    return Paginated<T>.fromJson(
      body,
      (items) => items.whereType<Map<String, dynamic>>().map(fromJson).toList(),
    );
  }

  Future<T> show(int id) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '$_path/$id',
    );
    final data = response.data!['data'];
    return fromJson(data as Map<String, dynamic>);
  }

  Future<T> create(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
      _path,
      data: data,
    );
    return fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<T> update(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
      '$_path/$id',
      data: data,
    );
    return fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> destroy(int id) async {
    await ApiClient.instance.dio.delete('$_path/$id');
  }

  Future<Paginated<T>> trash({int? page, int? perPage, String? search}) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '$_path/trash',
      queryParameters: {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return Paginated<T>.fromJson(
      response.data!,
      (items) => items.whereType<Map<String, dynamic>>().map(fromJson).toList(),
    );
  }

  Future<T> restore(int id) async {
    final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
      '$_path/$id/restore',
    );
    return fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> forceDestroy(int id) async {
    await ApiClient.instance.dio.delete('$_path/$id/force');
  }
}
