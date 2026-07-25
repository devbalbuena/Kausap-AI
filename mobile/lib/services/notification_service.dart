import '../config/api_config.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch all notifications for the current user (newest first).
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _apiClient.get(ApiConfig.notifications);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Get count of unread notifications.
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(ApiConfig.notificationsUnreadCount);
    return (response as Map<String, dynamic>)['count'] as int? ?? 0;
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _apiClient.put(
      '${ApiConfig.notifications}/$notificationId/read',
      body: {},
    );
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    await _apiClient.put(
      ApiConfig.notificationsReadAll,
      body: {},
    );
  }
}
