import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/theme.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_help_request_screen.dart';
import 'screens/help_exchange_screen.dart';
import 'screens/opportunities_screen.dart';
import 'screens/notifications_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the LIVE Sisonke Supabase backend.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const SisonkeApp());
}

class SisonkeApp extends StatelessWidget {
  const SisonkeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sisonke',
      debugShowCheckedModeBanner: false,

      theme: sisonkeTheme(),

      // AuthGate automatically decides whether the user
      // should see the login screen or enter the application.
      home: const AuthGate(),

      routes: {
        '/home': (context) => const HomeScreen(),

        '/discover': (context) => const DiscoverScreen(),

        '/profile': (context) => const ProfileScreen(),

        '/create-help-request': (context) =>
            const CreateHelpRequestScreen(),

        '/help-exchange': (context) =>
            const HelpExchangeScreen(),

        '/opportunities': (context) =>
            const OpportunitiesScreen(),

        // LIVE NOTIFICATIONS SCREEN
        '/notifications': (context) =>
            const NotificationsScreen(),
      },

      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => const AuthGate(),
        );
      },
    );
  }
}

///
/// AUTH GATE
///
/// Automatically listens to Supabase authentication.
///
/// - Not signed in -> AuthScreen
/// - Signed in -> HomeScreen
///
/// This is important because notifications belong
/// to the currently authenticated user.
///
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,

      builder: (context, snapshot) {
        // Check the current session immediately.
        final session =
            Supabase.instance.client.auth.currentSession;

        // User is already signed in.
        if (session != null) {
          return const HomeScreen();
        }

        // No authenticated user.
        return const AuthScreen();
      },
    );
  }
}
