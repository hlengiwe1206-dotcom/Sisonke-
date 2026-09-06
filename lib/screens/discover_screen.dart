import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../data/demo_data.dart';
import '../widgets/post_card.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(padding: const EdgeInsets.all(16), children: [
      Text('Discover', style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 16),
      TextField(
        decoration: InputDecoration(
          hintText: 'Search opportunities, help or information',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 20),
      Wrap(spacing: 8, runSpacing: 8, children: const [
        _Chip('Jobs'), _Chip('Training'), _Chip('Help'), _Chip('Education'),
        _Chip('Business'), _Chip('Community'),
      ]),
      const SizedBox(height: 24),
      Text('Trending now', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      ...demoPosts.reversed.map((post) => PostCard(post: post)),
    ]),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label),
    backgroundColor: SisonkeColors.white,
    side: const BorderSide(color: SisonkeColors.border),
  );
}
