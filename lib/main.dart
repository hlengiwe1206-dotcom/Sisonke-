import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_help_request_screen.dart';
import 'screens/help_exchange_screen.dart';
import 'screens/opportunities_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initialization.
  //
  // Replace these values with your real Supabase Project URL and Anon Key
  // when you are ready to connect the live backend.
  //
  // The try/catch allows the UI to continue running while you are still
  // building and testing the frontend.

  try {
    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: '',
      ),
      anonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
      ),
    );
  } catch (_) {
    // Frontend testing can continue even if Supabase credentials
    // have not yet been configured.
  }

  runApp(const SisonkeApp());
}

class SisonkeApp extends StatelessWidget {
  const SisonkeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sisonke',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF244B73),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFF7F8FA),

        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1F2937),
        ),

        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF244B73),
              width: 2,
            ),
          ),
        ),
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const HomeScreen(),

        '/discover': (context) => const DiscoverScreen(),

        '/profile': (context) => const ProfileScreen(),

        '/create-help-request': (context) =>
            const CreateHelpRequestScreen(),

        '/help-exchange': (context) =>
            const HelpExchangeScreen(),

        '/opportunities': (context) =>
            const OpportunitiesScreen(),
      },

      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        );
      },
    );
  }
}
