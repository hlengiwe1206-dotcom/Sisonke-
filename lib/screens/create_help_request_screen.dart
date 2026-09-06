import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/help_exchange_service.dart';

class CreateHelpRequestScreen extends StatefulWidget {
  const CreateHelpRequestScreen({super.key});
  @override
  State<CreateHelpRequestScreen> createState() => _CreateHelpRequestScreenState();
}

class _CreateHelpRequestScreenState extends State<CreateHelpRequestScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    title.dispose(); description.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (title.text.trim().length < 5 || description.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a clear title and explain what help you need.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await HelpExchangeService(Supabase.instance.client).createRequest(
        title: title.text,
        content: description.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your request is now visible to the community.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to publish request: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ask for help')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text('What do you need help with?', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text('Keep personal information private until you decide to connect with someone.'),
      const SizedBox(height: 24),
      TextField(
        controller: title,
        maxLength: 90,
        decoration: const InputDecoration(
          labelText: 'Short title',
          hintText: 'Example: I need help improving my CV',
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: description,
        minLines: 6,
        maxLines: 10,
        decoration: const InputDecoration(
          labelText: 'Explain what help you need',
          hintText: 'Describe the situation and the kind of help that would make a difference.',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: loading ? null : submit,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
        child: Text(loading ? 'PUBLISHING...' : 'ASK THE COMMUNITY'),
      ),
    ]),
  );
}
