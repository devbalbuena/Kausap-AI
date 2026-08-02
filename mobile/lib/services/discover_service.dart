import '../config/api_config.dart';
import 'api_client.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class DiscoverService {
  final ApiClient _apiClient = ApiClient();

  /// Fetches professionals list.
  /// - When online: fetches fresh data, caches it, returns it.
  /// - When offline: returns cached data (if available) without throwing.
  Future<List<Map<String, dynamic>>> getProfessionals({
    String? search,
    String? specialization,
  }) async {
    final connectivity = ConnectivityService();
    final cacheKey = '${CacheKeys.professionals}_${search ?? ""}_${specialization ?? ""}';

    if (!connectivity.isOnline) {
      // Offline — try cache
      final cached = await CacheService.readList(cacheKey, ttlMinutes: 1440);
      if (cached != null) return cached;
      return []; // No cache, return empty
    }

    try {
      final queryParams = <String>[];
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(search)}');
      }
      if (specialization != null && specialization.isNotEmpty) {
        queryParams.add('specialization=${Uri.encodeComponent(specialization)}');
      }

      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final url = '${ApiConfig.discoverProfessionals}$queryString';

      final response = await _apiClient.get(url);

      List<Map<String, dynamic>> result = [];
      if (response is List) {
        result = List<Map<String, dynamic>>.from(response);
      }

      // Cache only the base professionals list (no search filter)
      if ((search == null || search.isEmpty) &&
          (specialization == null || specialization.isEmpty)) {
        await CacheService.saveList(CacheKeys.professionals, result);
      }
      // Always cache keyed variant
      await CacheService.saveList(cacheKey, result);

      return result;
    } catch (_) {
      // Network failed mid-online — fall back to cache
      final cached = await CacheService.readList(cacheKey, ttlMinutes: 1440);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProfessionalDetails(String userId) async {
    final url = '${ApiConfig.discoverProfessionals}/$userId';
    final response = await _apiClient.get(url);
    if (response is Map<String, dynamic>) {
      return response;
    }
    return null;
  }
}
