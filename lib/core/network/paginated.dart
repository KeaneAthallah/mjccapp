/// Result of a paginated list request.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => items.isEmpty;

  /// Parses a paginated envelope from the Laravel `meta` block.
  factory Paginated.fromJson(
    Map<String, dynamic> json,
    List<T> Function(List<dynamic> items) parseItems,
  ) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    final rawItems = json['data'] as List<dynamic>? ?? const [];

    return Paginated<T>(
      items: parseItems(rawItems),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      perPage: (meta['per_page'] as num?)?.toInt() ?? rawItems.length,
      total: (meta['total'] as num?)?.toInt() ?? rawItems.length,
    );
  }
}
