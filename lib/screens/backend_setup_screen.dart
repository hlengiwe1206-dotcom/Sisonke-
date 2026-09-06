import 'package:flutter/material.dart';
import '../core/supabase_config.dart';
import '../widgets/sisonke_logo.dart';

class BackendSetupScreen extends StatelessWidget {
  const BackendSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SisonkeLogo(size: 56),
          const Spacer(),
          Text('Connect Sisonke to its live backend',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 16),
          const Text(
            'The app is built and ready for Supabase. Add your project URL and anonymous key in lib/core/supabase_config.dart, then run supabase/live_schema.sql in your Supabase SQL Editor.',
          ),
          const SizedBox(height: 24),
          const SelectableText(
            'Current status: BACKEND CREDENTIALS NOT CONFIGURED',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const Spacer(),
        ]),
      ),
    ),
  );
}
