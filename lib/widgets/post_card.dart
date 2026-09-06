import 'package:flutter/material.dart';
import '../core/brand.dart';
import '../models/post.dart';

class PostCard extends StatelessWidget {
  final CommunityPost post;
  const PostCard({super.key, required this.post});

  Color _badgeColor() {
    if (post.category == 'HELP NEEDED') return SisonkeColors.red;
    if (post.category == 'OPPORTUNITY') return SisonkeColors.blue;
    return SisonkeColors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(SisonkeSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(post.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(post.author, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(post.area, style: const TextStyle(color: SisonkeColors.muted, fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: _badgeColor().withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(post.category, style: TextStyle(color: _badgeColor(), fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ]),
            const SizedBox(height: 16),
            Text(post.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
            const SizedBox(height: 6),
            Text(post.content),
            const SizedBox(height: 16),
            Row(children: [
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.thumb_up_outlined), label: const Text('USEFUL')),
              const SizedBox(width: 4),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Great! You are responding to: ${post.title}')),
                    );
                  },
                  child: Text(post.action),
                ),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
