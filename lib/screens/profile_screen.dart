import 'package:flutter/material.dart';
import '../core/brand.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        const CircleAvatar(radius: 34, backgroundColor: SisonkeColors.green, child: Text('H', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Community Member', style: Theme.of(context).textTheme.titleLarge),
          const Text('Johannesburg, Gauteng', style: TextStyle(color: SisonkeColors.muted)),
        ]),
      ]),
      const SizedBox(height: 28),
      Text('My Sisonke Impact', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.45, mainAxisSpacing: 10, crossAxisSpacing: 10,
        children: const [
          _Impact('12', 'People helped'),
          _Impact('5', 'Help received'),
          _Impact('8', 'Opportunities shared'),
          _Impact('4', 'Actions joined'),
        ],
      ),
      const SizedBox(height: 28),
      Card(child: Column(children: const [
        ListTile(leading: Icon(Icons.bookmark_border), title: Text('Saved content')),
        Divider(height: 1),
        ListTile(leading: Icon(Icons.settings_outlined), title: Text('Settings')),
        Divider(height: 1),
        ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy & safety')),
      ])),
    ]),
  );
}

class _Impact extends StatelessWidget {
  final String value, label;
  const _Impact(this.value, this.label);
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: SisonkeColors.green)),
        Text(label, style: const TextStyle(color: SisonkeColors.muted, fontSize: 12)),
      ]),
    ),
  );
}
