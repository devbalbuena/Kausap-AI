import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/privacy_wrapper.dart';
import 'widgets/connectivity_banner.dart';
import 'widgets/retry_banner.dart';
import 'widgets/friendly_error_widget.dart';
import 'widgets/pin_lock_screen.dart';
import 'services/connectivity_service.dart';
import 'services/retry_service.dart';
import 'services/api_client.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/deactivated_account_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/counselor/counselor_dashboard_screen.dart';
import 'screens/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Replace the default red screen of death with our custom friendly error widget
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return FriendlyErrorWidget(details: details);
  };

  // 2. Catch Flutter framework errors (widget build failures, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // 3. Catch unhandled async / platform-level errors (outside Flutter zones)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled async error: $error\n$stack');
    return true; // Mark as handled to prevent app crash
  };

  // 4. Bound GPU image cache to 50MB / 100 images to prevent OOM on budget devices
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 MB
  PaintingBinding.instance.imageCache.maximumSize = 100;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => RetryService()),
      ],
      child: const KausapApp(),
    ),
  );

  // Background warm-up ping: gently triggers Render wakeup as soon as app opens
  ApiClient().get('/health', silent: true).catchError((_) => null);
}

class KausapApp extends StatelessWidget {
  const KausapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final activeTheme = themeProvider.highContrast
            ? AppTheme.getHighContrastTheme(themeProvider.accentColor)
            : AppTheme.getTheme(themeProvider.accentColor);
        final activeDarkTheme = themeProvider.highContrast
            ? AppTheme.getHighContrastTheme(themeProvider.accentColor)
            : AppTheme.getDarkTheme(themeProvider.accentColor);
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Kausap AI',
          debugShowCheckedModeBanner: false,
          theme: activeTheme,
          darkTheme: activeDarkTheme,
          themeMode: themeProvider.themeMode,
          builder: (context, child) {
            final scaled = MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(themeProvider.textScaleFactor),
              ),
              child: child ?? const SizedBox.shrink(),
            );
            return ConnectivityBanner(
              child: RetryBanner(
                child: PrivacyWrapper(child: scaled),
              ),
            );
          },
          home: const _AppStartup(),
        );
      },
    );
  }
}

/// Handles startup logic:
/// - Shows a splash while checking stored token / auth state
/// - Synchronizes user-specific theme preferences
/// - Routes to Home / Admin / Counselor if logged in
/// - Routes to Login if not
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  String? _lastSyncedUserId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.read<ThemeProvider>();

    if (auth.isLoading) {
      // Show proper animated splash while auth checks token
      return const SplashScreen();
    }

    if (auth.isAuthenticated && auth.currentUser != null) {
      final user = auth.currentUser!;
      final userId = user['id']?.toString() ?? user['email']?.toString() ?? '';

      if (_lastSyncedUserId != userId) {
        _lastSyncedUserId = userId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            theme.loadUserPreferences(userId);
          }
        });
      }

      if (user['is_active'] == false) {
        return DeactivatedAccountScreen(userProfile: user);
      }
      Widget home;
      if (user['role'] == 'admin') {
        home = const AdminDashboardScreen();
      } else if (user['role'] == 'counselor') {
        home = const CounselorDashboardScreen();
      } else {
        home = HomeScreen(user: user);
      }
      // Wrap with PIN lock — only blocks if user has set a PIN
      return PinLockScreen(child: home);
    }

    // Unauthenticated state: reset theme to clean default
    if (_lastSyncedUserId != null) {
      _lastSyncedUserId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          theme.resetToDefaults();
        }
      });
    }

    return const LoginScreen();
  }
}
