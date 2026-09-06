import 'package:flutter/material.dart';
import '../core/brand.dart';

class ActionSheet extends StatelessWidget {
  const ActionSheet({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Take action', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('What would you like to do?', style: TextStyle(color: SisonkeColors.muted)),
        const SizedBox(height: 18),
        ...[
          ('Report a community issue', Icons.warning_amber_rounded, SisonkeColors.red),
          ('Share useful information', Icons.campaign_outlined, SisonkeColors.blue),
          ('Share an opportunity', Icons.work_outline, SisonkeColors.gold),
          ('Ask for help', Icons.volunteer_activism_outlined, SisonkeColors.green),
          ('Offer help', Icons.handshake_outlined, SisonkeColors.greenDark),
          ('Create community action', Icons.groups_outlined, SisonkeColors.black),
        ].map((item) => Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: (item.$3 as Color).withValues(alpha:.12), child: Icon(item.$2 as IconData, color:item.$3 as Color)),
            title: Text(item.$1 as String, style: const TextStyle(fontWeight: FontWeight.w800)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.$1} flow is ready for backend connection.')));
            },
          ),
        )),
      ]),
    ),
  );
}
