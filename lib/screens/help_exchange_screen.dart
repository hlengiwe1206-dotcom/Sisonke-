import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/brand.dart';
import '../data/help_exchange_service.dart';
import '../models/help_request.dart';
import 'create_help_request_screen.dart';
import 'help_request_detail_screen.dart';

class HelpExchangeScreen extends StatelessWidget {
  const HelpExchangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = HelpExchangeService(Supabase.instance.client);
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateHelpRequestScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('ASK FOR HELP'),
        ),
        body: StreamBuilder<List<HelpRequest>>(
          stream: service.watchOpenRequests(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorState(message: snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final requests = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Help Exchange', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                const Text(
                  'Real people. Real needs. Real opportunities to help.',
                  style: TextStyle(color: SisonkeColors.muted),
                ),
                const SizedBox(height: 22),
                if (requests.isEmpty)
                  const _EmptyState()
                else
                  ...requests.map((request) => _RequestCard(
                    request: request,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HelpRequestDetailScreen(request: request),
                      ),
                    ),
                  )),
                const SizedBox(height: 90),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback onTap;
  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SisonkeColors.red.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.volunteer_activism_outlined, color: SisonkeColors.red),
            ),
            const Spacer(),
            Text(
              request.category?.toUpperCase() ?? 'HELP NEEDED',
              style: const TextStyle(
                color: SisonkeColors.red,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Text(request.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(request.content, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.people_outline, size: 16, color: SisonkeColors.muted),
            const SizedBox(width: 6),
            Text('${request.offerCount} offer${request.offerCount == 1 ? '' : 's'}',
              style: const TextStyle(color: SisonkeColors.muted)),
            const Spacer(),
            const Icon(Icons.arrow_forward, size: 18),
          ]),
        ]),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 80),
    child: Column(children: [
      const Icon(Icons.handshake_outlined, size: 72, color: SisonkeColors.green),
      const SizedBox(height: 18),
      Text('No open requests yet', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text('Be the first to ask your community for help.', textAlign: TextAlign.center),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(child: Text('Unable to load Help Exchange.\n\n$message')),
  );
}
