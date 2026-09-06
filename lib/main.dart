import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/supabase_config.dart';
import 'screens/auth_screen.dart';
import 'screens/backend_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/help_exchange_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/action_sheet.dart';
import 'screens/connect_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  runApp(const SisonkeApp());
}

class SisonkeApp extends StatelessWidget {
  const SisonkeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sisonke',
    debugShowCheckedModeBanner: false,
    theme: sisonkeTheme(),
    home: !SupabaseConfig.isConfigured
        ? const BackendSetupScreen()
        : const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return const AuthScreen();
        return const AppShell();
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  void openAction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => const ActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onAction: openAction),
      const DiscoverScreen(),
      const HelpExchangeScreen(),
      const ConnectScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          if (value == 2) {
            openAction();
          } else {
            setState(() => index = value);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Action'),
          NavigationDestination(icon: Icon(Icons.handshake_outlined), selectedIcon: Icon(Icons.handshake), label: 'Connect'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
