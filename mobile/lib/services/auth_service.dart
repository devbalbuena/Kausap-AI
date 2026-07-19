import '../config/api_config.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      ApiConfig.register,
      body: payload,
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiConfig.login,
      body: {
        'email': email,
        'password': password,
      },
    );
    
    final data = response as Map<String, dynamic>;
    if (data.containsKey('access_token')) {
      await _tokenStorage.saveToken(data['access_token']);
    }
    return data;
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _apiClient.get(ApiConfig.me);
    return response as Map<String, dynamic>;
  }
}
