GridView.count(
  crossAxisCount: 2,
  childAspectRatio: 1.08,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  children: [
    _QuickAction(
      label: 'ASK FOR HELP',
      icon: Icons.volunteer_activism_outlined,
      color: SisonkeColors.red,
      onTap: onAction,
    ),

    _QuickAction(
      label: 'OFFER HELP',
      icon: Icons.handshake_outlined,
      color: SisonkeColors.green,
      onTap: onAction,
    ),

    _QuickAction(
      label: 'OPPORTUNITIES',
      icon: Icons.work_outline,
      color: SisonkeColors.blue,
      onTap: onAction,
    ),

    _QuickAction(
      label: 'SHARE INFO',
      icon: Icons.campaign_outlined,
      color: SisonkeColors.gold,
      onTap: onAction,
    ),
  ],
),
