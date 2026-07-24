class ApiConfig {
  // Use 10.0.2.2 for Android Emulator connecting to localhost
  // Use your local IP (e.g. 192.168.x.x) if testing on physical device
  static const String baseUrl = 'http://10.0.2.2:8000';

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
}
