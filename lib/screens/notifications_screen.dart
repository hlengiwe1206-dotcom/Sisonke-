import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/notification_service.dart';
import '../models/notification_model.dart';

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
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();

    _notificationService =
        NotificationService(
      Supabase.instance.client,
    );
  }

  IconData _notificationIcon(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'help':
      case 'help_request':
        return Icons.volunteer_activism_outlined;

      case 'offer':
      case 'help_offer':
        return Icons.handshake_outlined;

      case 'connection':
        return Icons.people_alt_outlined;

      case 'message':
        return Icons.chat_bubble_outline_rounded;

      case 'opportunity':
        return Icons.business_center_outlined;

      case 'test':
        return Icons.science_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  Color _notificationColor(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'help':
      case 'help_request':
        return const Color(0xFFE9322A);

      case 'offer':
      case 'help_offer':
        return const Color(0xFF0F6B4A);

      case 'connection':
        return const Color(0xFF244B73);

      case 'message':
        return const Color(0xFF6C4AB6);

      case 'opportunity':
        return const Color(0xFFFFB000);

      case 'test':
        return const Color(0xFF1E4F7F);

      default:
        return const Color(0xFFFFB000);
    }
  }

  String _formatDate(
    DateTime date,
  ) {
    final now = DateTime.now();

    final localDate = date.toLocal();

    final difference =
        now.difference(localDate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F3EE),

      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          StreamBuilder<List<SisonkeNotification>>(
            stream:
                _notificationService.watchNotifications(),

            builder: (
              context,
              snapshot,
            ) {
              final notifications =
                  snapshot.data ?? [];

              final unreadCount =
                  notifications
                      .where(
                        (notification) =>
                            !notification.isRead,
                      )
                      .length;

              if (unreadCount == 0) {
                return const SizedBox.shrink();
              }

              return TextButton(
                onPressed: () async {
                  await _notificationService
                      .markAllAsRead();
                },

                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color:
                        Color(0xFF244B73),
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body:
          StreamBuilder<List<SisonkeNotification>>(
        stream:
            _notificationService.watchNotifications(),

        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFFFFB000),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),

                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    const Icon(
                      Icons
                          .notifications_off_outlined,
                      size: 60,
                      color:
                          Color(0xFFE9322A),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    const Text(
                      'Unable to load notifications',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      snapshot.error
                          .toString(),
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications =
              snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(32),

                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    const Icon(
                      Icons
                          .notifications_none_rounded,
                      size: 72,
                      color:
                          Color(0xFFFFB000),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    const Text(
                      'When something important happens in your Sisonke community, you will see it here.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              40,
            ),

            itemCount:
                notifications.length,

            separatorBuilder:
                (_, __) =>
                    const SizedBox(
              height: 12,
            ),

            itemBuilder:
                (
              context,
              index,
            ) {
              final notification =
                  notifications[index];

              final color =
                  _notificationColor(
                notification.type,
              );

              return Material(
                color:
                    notification.isRead
                        ? Colors.white
                        : const Color(
                            0xFFFFF7E6,
                          ),

                borderRadius:
                    BorderRadius.circular(
                  22,
                ),

                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),

                  onTap: () async {
                    if (!notification
                        .isRead) {
                      await _notificationService
                          .markAsRead(
                        notification.id,
                      );
                    }
                  },

                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Container(
                          width: 52,
                          height: 52,

                          decoration:
                              BoxDecoration(
                            color: color
                                .withOpacity(
                              0.12,
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),

                          child: Icon(
                            _notificationIcon(
                              notification
                                  .type,
                            ),

                            color: color,
                            size: 27,
                          ),
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification
                                          .title,

                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            notification
                                                    .isRead
                                                ? FontWeight
                                                    .w700
                                                : FontWeight
                                                    .w900,
                                      ),
                                    ),
                                  ),

                                  if (!notification
                                      .isRead)
                                    Container(
                                      width: 10,
                                      height: 10,

                                      decoration:
                                          const BoxDecoration(
                                        color:
                                            Color(
                                          0xFFFFB000,
                                        ),

                                        shape:
                                            BoxShape
                                                .circle,
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Text(
                                notification.body,

                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                    0xFF6B7280,
                                  ),

                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              Text(
                                _formatDate(
                                  notification
                                      .createdAt,
                                ),

                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                    0xFF9CA3AF,
                                  ),

                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
