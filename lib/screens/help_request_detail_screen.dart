import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/brand.dart';
import '../data/help_exchange_service.dart';
import '../models/help_request.dart';
import '../models/help_offer.dart';

class HelpRequestDetailScreen extends StatefulWidget {
  final HelpRequest request;
  const HelpRequestDetailScreen({super.key, required this.request});

  @override
  State<HelpRequestDetailScreen> createState() => _HelpRequestDetailScreenState();
}

class _HelpRequestDetailScreenState extends State<HelpRequestDetailScreen> {
  final message = TextEditingController();
  bool sending = false;
  late final HelpExchangeService service;

  @override
  void initState() {
    super.initState();
    service = HelpExchangeService(Supabase.instance.client);
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  bool get isOwner =>
      Supabase.instance.client.auth.currentUser?.id == widget.request.requesterId;

  Future<void> submitOffer() async {
    if (message.text.trim().isEmpty) return;
    setState(() => sending = true);
    try {
      await service.offerHelp(
        helpRequestId: widget.request.id,
        message: message.text,
      );
      message.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your offer has been sent. Thank you for helping!')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to send offer: $e')),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> acceptOffer(HelpOffer offer) async {
    try {
      final connectionId = await service.acceptOffer(offer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Help connection created: $connectionId')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to accept offer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help request')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SisonkeColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SisonkeColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('HELP NEEDED', style: TextStyle(color: SisonkeColors.red, fontWeight: FontWeight.w900, fontSize: 11)),
          const SizedBox(height: 10),
          Text(widget.request.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(widget.request.content),
        ]),
      ),
      const SizedBox(height: 22),
      if (!isOwner) ...[
        Text('Offer help', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        TextField(
          controller: message,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            hintText: 'Explain how you can help. Do not share sensitive personal details.',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: sending ? null : submitOffer,
          child: Text(sending ? 'SENDING...' : 'I CAN HELP'),
        ),
      ] else ...[
        Text('Offers from the community', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        StreamBuilder<List<HelpOffer>>(
          stream: service.watchOffers(widget.request.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Unable to load offers: ${snapshot.error}');
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final offers = snapshot.data!;
            if (offers.isEmpty) return const Text('No offers yet. Your community will be notified as activity grows.');
            return Column(
              children: offers.map((offer) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text(offer.helperName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(offer.message),
                  trailing: offer.status == 'pending'
                      ? FilledButton(
                          onPressed: () => acceptOffer(offer),
                          child: const Text('ACCEPT'),
                        )
                      : Text(offer.status.toUpperCase()),
                ),
              )).toList(),
            );
          },
        )
      ],
    ]),
  );
}
