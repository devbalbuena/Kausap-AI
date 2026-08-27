class ApiConfig {
  // Set to true only if running a local FastAPI server (http://127.0.0.1:8000)
  // Otherwise, connects 24/7 to the live production Render backend
  static const bool useLocalBackend = false;

  static const String baseUrl = useLocalBackend
      ? 'http://127.0.0.1:8000'
      : 'https://kausap-ai.onrender.com';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyCode = '/auth/verify-code';
  static const String resetPassword = '/auth/reset-password';

  static const String mood = '/mood';
  static const String moodSummary = '/mood/summary';

  // Direct Messages
  static const String directMessages = '/direct-messages';

  // Session endpoints
  static const String sessions = '/sessions';
  static const String sessionsUpcoming = '/sessions/upcoming';
  static const String sessionsPast = '/sessions/past';

  // Chat endpoints
  static const String chatSessions = '/chat/sessions';

  // Referral endpoints
  static const String referrals = '/referrals';
  static const String referralsMe = '/referrals/me';

  // Admin endpoints
  static const String adminUsers = '/admin/users';
  static const String adminFlaggedMessages = '/admin/flagged-messages';
  static const String adminStats = '/admin/stats';
  static const String adminAuditLogs = '/admin/audit-logs';
  static const String adminCounselors = '/admin/counselors';
  static const String adminTelemetryTokens = '/admin/telemetry/tokens';
  static const String adminTelemetryHealth = '/admin/telemetry/system-health';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';

  // Settings endpoints
  static const String changePassword = '/auth/change-password';
}
