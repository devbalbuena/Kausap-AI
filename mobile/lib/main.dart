import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/privacy_wrapper.dart';
import 'widgets/connectivity_banner.dart';
import 'widgets/retry_banner.dart';
import 'widgets/friendly_error_widget.dart';
import 'services/connectivity_service.dart';
import 'services/retry_service.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/signup/professional_pending_screen.dart';
import 'screens/professional/professional_base_screen.dart';
import 'screens/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Replace the default red screen of death with our custom friendly error widget
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return FriendlyErrorWidget(details: details);
  };

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
}

class KausapApp extends StatelessWidget {
  const KausapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final activeTheme = themeProvider.highContrast
            ? AppTheme.highContrastTheme
            : AppTheme.theme;
        final activeDarkTheme = themeProvider.highContrast
            ? AppTheme.highContrastTheme
            : AppTheme.darkTheme;
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
/// - Routes to Home if already logged in
/// - Routes to Role Selection if not
class _AppStartup extends StatelessWidget {
  const _AppStartup();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      // Show proper animated splash while auth checks token
      return const SplashScreen();
    }

    if (auth.isAuthenticated && auth.currentUser != null) {
      final user = auth.currentUser!;
      if (user['role'] == 'professional') {
        final profile = user['professional_profile'];
        if (profile == null || profile['is_verified'] != true) {
          return const ProfessionalPendingScreen();
        }
        return const ProfessionalBaseScreen();
      }
      return HomeScreen(user: user);
    }

    return const RoleSelectionScreen();
  }
}
