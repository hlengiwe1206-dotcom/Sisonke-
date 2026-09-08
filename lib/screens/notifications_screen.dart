import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  Stream<List<Map<String, dynamic>>>
      _notificationsStream() {
    final userId =
        _supabase.auth.currentUser?.id;

    if (userId == null) {
      return Stream.value(
        <Map<String, dynamic>>[],
      );
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((notifications) {
          notifications.sort((a, b) {
            final aDate =
                DateTime.tryParse(
              a['created_at']?.toString() ?? '',
            );

            final bDate =
                DateTime.tryParse(
              b['created_at']?.toString() ?? '',
            );

            if (aDate == null && bDate == null) {
              return 0;
            }

            if (aDate == null) {
              return 1;
            }

            if (bDate == null) {
              return -1;
            }

            return bDate.compareTo(aDate);
          });

          return notifications;
        });
  }

  Future<void> _markAsRead(
    Map<String, dynamic> notification,
  ) async {
    final notificationId =
        notification['id'];

    if (notificationId == null) {
      return;
    }

    if (notification['read_at'] != null) {
      return;
    }

    try {
      await _supabase
          .from('notifications')
          .update({
            'read_at':
                DateTime.now().toUtc().toIso8601String(),
          })
          .eq(
            'id',
            notificationId,
          );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to mark notification as read: $error',
          ),
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final userId =
        _supabase.auth.currentUser?.id;

    if (userId == null) {
      return;
    }

    try {
      await _supabase
          .from('notifications')
          .update({
            'read_at':
                DateTime.now().toUtc().toIso8601String(),
          })
          .eq(
            'user_id',
            userId,
          )
          .isFilter(
            'read_at',
            null,
          );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to mark all notifications as read: $error',
          ),
        ),
      );
    }
  }

  IconData _notificationIcon(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'deadline':
      case 'closing_date':
        return Icons.schedule_outlined;

      case 'opportunity':
      case 'opportunity_match':
      case 'personalised_match':
        return Icons.auto_awesome_outlined;

      case 'saved_opportunity':
        return Icons.bookmark_outline;

      case 'help_request':
        return Icons.volunteer_activism_outlined;

      case 'offer':
        return Icons.handshake_outlined;

      case 'connection':
        return Icons.people_outline;

      case 'message':
        return Icons.message_outlined;

      case 'alert':
      case 'warning':
        return Icons.warning_amber_rounded;

      case 'success':
        return Icons.check_circle_outline;

      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _notificationColor(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'deadline':
      case 'closing_date':
        return const Color(0xFFE9322A);

      case 'opportunity':
      case 'opportunity_match':
      case 'personalised_match':
        return const Color(0xFF1E4F7F);

      case 'help_request':
        return const Color(0xFFE9322A);

      case 'offer':
        return const Color(0xFF0F6B4A);

      case 'success':
        return const Color(0xFF0F6B4A);

      case 'alert':
      case 'warning':
        return const Color(0xFFFFB41F);

      default:
        return const Color(0xFF1F232B);
    }
  }

  String _formatDate(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final date =
        DateTime.tryParse(value.toString());

    if (date == null) {
      return '';
    }

    final localDate =
        date.toLocal();

    final now =
        DateTime.now();

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

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F3EE),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5F3EE),

        elevation: 0,

        surfaceTintColor:
            Colors.transparent,

        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1F232B),
            fontWeight: FontWeight.w800,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Color(0xFF1F232B),
        ),

        actions: [
          StreamBuilder<
              List<Map<String, dynamic>>>(
            stream: _notificationsStream(),

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
                            notification[
                                'read_at'] ==
                            null,
                      )
                      .length;

              if (unreadCount == 0) {
                return const SizedBox();
              }

              return IconButton(
                tooltip:
                    'Mark all as read',

                icon: const Icon(
                  Icons.done_all_rounded,
                ),

                onPressed:
                    _markAllAsRead,
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<
          List<Map<String, dynamic>>>(
        stream: _notificationsStream(),

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
            return _buildErrorState(
              snapshot.error.toString(),
            );
          }

          final notifications =
              snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              30,
            ),

            itemCount:
                notifications.length,

            separatorBuilder:
                (_, __) =>
                    const SizedBox(
              height: 10,
            ),

            itemBuilder:
                (context, index) {
              final notification =
                  notifications[index];

              return _buildNotificationCard(
                notification,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
  ) {
    final isUnread =
        notification['read_at'] == null;

    final title =
        notification['title']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? notification['title']
            .toString()
        : 'Notification';

    final body =
        notification['body']
                ?.toString()
                .trim() ??
            '';

    final type =
        notification['type']
                ?.toString()
                .trim() ??
            '';

    final date =
        _formatDate(
      notification['created_at'],
    );

    final color =
        _notificationColor(type);

    return Material(
      color: isUnread
          ? Colors.white
          : Colors.white
              .withOpacity(0.72),

      elevation: isUnread ? 2 : 0,

      borderRadius:
          BorderRadius.circular(22),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(22),

        onTap: () {
          if (isUnread) {
            _markAsRead(
              notification,
            );
          }
        },

        child: Container(
          padding:
              const EdgeInsets.all(18),

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(22),

            border: Border.all(
              color: isUnread
                  ? color.withOpacity(0.25)
                  : Colors.black
                      .withOpacity(0.05),
            ),
          ),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color:
                      color.withOpacity(0.12),

                  borderRadius:
                      BorderRadius.circular(15),
                ),

                child: Icon(
                  _notificationIcon(
                    type,
                  ),

                  color: color,

                  size: 26,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,

                            style: TextStyle(
                              color: const Color(
                                0xFF1F232B,
                              ),

                              fontSize: 16,

                              fontWeight:
                                  isUnread
                                      ? FontWeight
                                          .w800
                                      : FontWeight
                                          .w600,
                            ),
                          ),
                        ),

                        if (isUnread)
                          Container(
                            width: 9,
                            height: 9,

                            decoration:
                                const BoxDecoration(
                              color:
                                  Color(
                                0xFFE9322A,
                              ),

                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    if (body.isNotEmpty) ...[
                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        body,

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
                    ],

                    if (date.isNotEmpty) ...[
                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        date,

                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xFF9CA3AF,
                          ),

                          fontSize: 12,

                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(
          height: 120,
        ),

        Icon(
          Icons.notifications_none_rounded,
          size: 72,
          color: Color(0xFF9CA3AF),
        ),

        SizedBox(
          height: 18,
        ),

        Center(
          child: Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF1F232B),
            ),
          ),
        ),

        SizedBox(
          height: 8,
        ),

        Center(
          child: Text(
            'You are all caught up.',
            style: TextStyle(
              fontSize: 14,
              color:
                  Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    String error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline,
              size: 55,
              color: Color(
                0xFFE9322A,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'Unable to load notifications',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              error,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color:
                    Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
