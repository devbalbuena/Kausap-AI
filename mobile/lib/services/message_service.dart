import '../config/api_config.dart';
import 'api_client.dart';

class MessageService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch chat history with a specific user
  Future<List<Map<String, dynamic>>> getMessages(String otherUserId) async {
    final response = await _apiClient.get('${ApiConfig.directMessages}/$otherUserId');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Send a message to a specific user
  Future<Map<String, dynamic>> sendMessage(String otherUserId, String content) async {
    final response = await _apiClient.post(
      ApiConfig.directMessages,
      body: {
        'receiver_id': otherUserId,
        'content': content,
      },
    );
    return response as Map<String, dynamic>;
  }
}
