import '../config/api_config.dart';
import 'api_client.dart';

class DiscoverService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getProfessionals({
    String? search,
    String? specialization,
  }) async {
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
    
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
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
