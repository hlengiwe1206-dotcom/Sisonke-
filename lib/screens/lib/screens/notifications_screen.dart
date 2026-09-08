import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final NotificationService _notificationService =
      NotificationService.instance;

  bool _isProcessing = false;

  Future<void> _markAllAsRead() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _notificationService.markAllAsRead();
    } catch (error) {
      if (mounted) {
        _showError(
          'Unable to mark notifications as read.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _deleteReadNotifications() async {
    if (_isProcessing) return;

    final confirmed =
        await _confirmDeleteRead();

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _notificationService
          .deleteReadNotifications();
    } catch (error) {
      if (mounted) {
        _showError(
          'Unable to clear notifications.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool?> _confirmDeleteRead() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Clear read notifications?'),
          content: const Text(
            'This will permanently remove all '
            'notifications you have already read.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleNotificationTap(
    AppNotification notification,
  ) async {
    try {
      if (!notification.isRead) {
        await _notificationService
            .markAsRead(notification.id);
      }

      if (!mounted) return;

      if (notification.opportunityId == null ||
          notification.opportunityId!.isEmpty) {
        return;
      }

      final opportunity =
          await _notificationService
              .getOpportunity(
        notification.opportunityId!,
      );

      if (!mounted) return;

      if (opportunity == null) {
        _showError(
          'This opportunity is no longer available.',
        );
        return;
      }

      _showOpportunityPreview(
        opportunity,
        notification,
      );
    } catch (error) {
      if (mounted) {
        _showError(
          'Unable to open this notification.',
        );
      }
    }
  }

  Future<void> _deleteNotification(
    AppNotification notification,
  ) async {
    try {
      await _notificationService
          .deleteNotification(
        notification.id,
      );
    } catch (error) {
      if (mounted) {
        _showError(
          'Unable to delete notification.',
        );
      }
    }
  }

  void _showOpportunityPreview(
    Map<String, dynamic> opportunity,
    AppNotification notification,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final title =
            opportunity['title']?.toString() ??
                'Opportunity';

        final description =
            opportunity['description']?.toString() ??
                '';

        final location =
            opportunity['location']?.toString();

        final category =
            opportunity['category']?.toString();

        final opportunityType =
            opportunity['opportunity_type']?.toString();

        final closingDate =
            _formatOpportunityDate(
          opportunity['closing_date'],
        );

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              28,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 16),

                  if (notification.matchScore != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber
                            .withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${notification.matchScore}% personalised match',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge,
                    ),

                  const SizedBox(height: 20),

                  _OpportunityInfo(
                    icon:
                        Icons.category_outlined,
                    label: 'Category',
                    value: category,
                  ),

                  _OpportunityInfo(
                    icon:
                        Icons.work_outline,
                    label: 'Type',
                    value: opportunityType,
                  ),

                  _OpportunityInfo(
                    icon:
                        Icons.location_on_outlined,
                    label: 'Location',
                    value: location,
                  ),

                  _OpportunityInfo(
                    icon:
                        Icons.calendar_today_outlined,
                    label: 'Closing date',
                    value: closingDate,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);

                        // ------------------------------------------------
                        // This intentionally uses the existing named route.
                        //
                        // It does not replace or modify your current
                        // Opportunity Details flow.
                        // ------------------------------------------------

                        Navigator.pushNamed(
                          this.context,
                          '/opportunity-details',
                          arguments: opportunity,
                        );
                      },
                      icon:
                          const Icon(Icons.open_in_new),
                      label:
                          const Text('Open Opportunity'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _formatOpportunityDate(
    dynamic value,
  ) {
    if (value == null) return null;

    final date = DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return value.toString();
    }

    final localDate =
        date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Notifications'),
        actions: [
          StreamBuilder<List<AppNotification>>(
            stream: _notificationService
                .watchNotifications(),
            builder: (
              context,
              snapshot,
            ) {
              final notifications =
                  snapshot.data ?? [];

              final unreadCount =
                  notifications
                      .where(
                        (item) =>
                            !item.isRead,
                      )
                      .length;

              if (unreadCount == 0) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip:
                    'Mark all as read',
                onPressed:
                    _isProcessing
                        ? null
                        : _markAllAsRead,
                icon: const Icon(
                  Icons.done_all,
                ),
              );
            },
          ),

          PopupMenuButton<String>(
            enabled:
                !_isProcessing,
            onSelected: (
              value,
            ) {
              if (value == 'clear_read') {
                _deleteReadNotifications();
              }
            },
            itemBuilder: (
              context,
            ) {
              return const [
                PopupMenuItem(
                  value: 'clear_read',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_sweep_outlined,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Clear read notifications',
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder<
          List<AppNotification>>(
        stream:
            _notificationService
                .watchNotifications(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              onRetry: () {
                setState(() {});
              },
            );
          }

          final notifications =
              snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const _EmptyNotifications();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.separated(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(
                vertical: 8,
              ),
              itemCount:
                  notifications.length,
              separatorBuilder:
                  (_, __) =>
                      const Divider(
                height: 1,
              ),
              itemBuilder: (
                context,
                index,
              ) {
                final notification =
                    notifications[index];

                return Dismissible(
                  key: ValueKey(
                    notification.id,
                  ),
                  direction:
                      DismissDirection.endToStart,
                  background:
                      Container(
                    alignment:
                        Alignment.centerRight,
                    padding:
                        const EdgeInsets.only(
                      right: 24,
                    ),
                    color:
                        Colors.red.shade600,
                    child:
                        const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) {
                    _deleteNotification(
                      notification,
                    );
                  },
                  child:
                      _NotificationTile(
                    notification:
                        notification,
                    onTap: () {
                      _handleNotificationTap(
                        notification,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile
    extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(
    final theme =
        Theme.of(context);

    final iconData =
        _notificationIcon(
      notification.notificationType,
    );

    final iconColor =
        _notificationColor(
      notification.notificationType,
    );

    return Material(
      color:
          notification.isRead
              ? Colors.transparent
              : theme.colorScheme.primary
                  .withOpacity(0.07),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    iconColor.withOpacity(
                  0.14,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight:
                                      notification.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w800,
                                ),
                          ),
                        ),

                        if (!notification.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration:
                                BoxDecoration(
                              color: theme
                                  .colorScheme
                                  .primary,
                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .bodyMedium,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          _relativeTime(
                            notification.createdAt,
                          ),
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: theme
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),

                        if (notification
                                .matchScore !=
                            null) ...[
                          const SizedBox(width: 12),

                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color:
                                Colors.amber
                                    .shade700,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            '${notification.matchScore}% match',
                            style: theme
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _notificationIcon(
    String type,
  ) {
    switch (type) {
      case 'closing_today':
        return Icons.priority_high;

      case 'closing_tomorrow':
        return Icons.warning_amber_rounded;

      case 'closing_soon':
        return Icons.timer_outlined;

      case 'closing_this_week':
        return Icons.calendar_month_outlined;

      case 'personalised_match':
        return Icons.auto_awesome;

      default:
        return Icons.notifications_outlined;
    }
  }

  Color _notificationColor(
    String type,
  ) {
    switch (type) {
      case 'closing_today':
        return Colors.red;

      case 'closing_tomorrow':
        return Colors.orange;

      case 'closing_soon':
        return Colors.deepOrange;

      case 'closing_this_week':
        return Colors.blue;

      case 'personalised_match':
        return Colors.purple;

      default:
        return Colors.blueGrey;
    }
  }

  String _relativeTime(
    DateTime date,
  ) {
    final now =
        DateTime.now();

    final difference =
        now.difference(
      date.toLocal(),
    );

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _OpportunityInfo
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _OpportunityInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    if (value == null ||
        value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium,
                ),

                const SizedBox(height: 3),

                Text(
                  value!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotifications
    extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 70,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'When opportunities strongly match your '
              'preferences or approach their closing dates, '
              'your alerts will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({
    required this.onRetry,
  });

  @override
  Widget build(
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            FilledButton(
              onPressed: onRetry,
              child:
                  const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
