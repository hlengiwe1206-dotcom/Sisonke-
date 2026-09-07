import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'create_help_request_screen.dart';
import 'notifications_screen.dart';
Widget _buildHeader() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // TOP HEADER WITH GREETING AND NOTIFICATION BELL
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // GREETING
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  'Good morning,',
                  style: TextStyle(
                    fontSize: 22,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Together, we can\nmove forward.',
                  style: TextStyle(
                    fontSize: 36,
                    height: 1.08,
                    color: Color(0xFF1F232B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // NOTIFICATION BELL
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _unreadNotificationsStream(),
            builder: (context, snapshot) {

              final unreadCount =
                  snapshot.data?.length ?? 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [

                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),

                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(16),

                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationsScreen(),
                          ),
                        );
                      },

                      child: Container(
                        width: 58,
                        height: 58,

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),

                          boxShadow: const [
                            BoxShadow(
                              color:
                                  Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),

                        child: const Icon(
                          Icons.notifications_none,
                          size: 28,
                          color: Color(0xFF1F232B),
                        ),
                      ),
                    ),
                  ),

                  // UNREAD BADGE
                  if (unreadCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,

                      child: Container(
                        constraints:
                            const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),

                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 5,
                        ),

                        decoration:
                            const BoxDecoration(
                          color: Color(0xFFE9322A),
                          shape: BoxShape.circle,
                        ),

                        alignment: Alignment.center,

                        child: Text(
                          unreadCount > 99
                              ? '99+'
                              : unreadCount.toString(),

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      const SizedBox(height: 20),

      // LOCATION
      const Row(
        children: [

          Icon(
            Icons.location_on_outlined,
            color: Color(0xFF6B7280),
            size: 27,
          ),

          SizedBox(width: 8),

          Expanded(
            child: Text(
              'Johannesburg, Gauteng',
              style: TextStyle(
                fontSize: 19,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
