import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/signup/professional_pending_screen.dart';
import 'screens/professional/professional_base_screen.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const KausapApp(),
    ),
  );
}

class KausapApp extends StatelessWidget {
  const KausapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kausap AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _AppStartup(),
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
