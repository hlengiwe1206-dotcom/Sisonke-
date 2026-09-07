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
import 'screens/saved_opportunities_screen.dart';
import 'screens/notifications_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the live Sisonke Supabase backend.
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

      // Automatically determines whether the user should
      // enter the application or see the authentication screen.
      home: const AuthGate(),

      routes: {
        '/home': (context) => const HomeScreen(),

        '/discover': (context) => const DiscoverScreen(),

        '/profile': (context) => const ProfileScreen(),

        '/create-help-request': (context) =>
            const CreateHelpRequestScreen(),

        '/help-exchange': (context) =>
            const HelpExchangeScreen(),

        // Universal Opportunities hub.
        '/opportunities': (context) =>
            const OpportunitiesScreen(),

        // Saved opportunities.
        '/saved-opportunities': (context) =>
            const SavedOpportunitiesScreen(),

        // Live notifications.
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

/// AuthGate listens for Supabase authentication changes.
///
/// - No authenticated user -> AuthScreen
/// - Authenticated user -> HomeScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            Supabase.instance.client.auth.currentSession;

        if (session != null) {
          return const HomeScreen();
        }

        return const AuthScreen();
      },
    );
  }
}
