import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/privacy_wrapper.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/signup/professional_pending_screen.dart';
import 'screens/professional/professional_base_screen.dart';
import 'screens/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
            return PrivacyWrapper(child: scaled);
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
