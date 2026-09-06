import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'PASTE_YOUR_SUPABASE_PROJECT_URL_HERE',
    anonKey: 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE',
  );

  runApp(const SisonkeApp());
}

class SisonkeApp extends StatelessWidget {
  const SisonkeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sisonke',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
