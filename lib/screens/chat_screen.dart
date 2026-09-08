import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String? otherUserId;
  final String? otherUserName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherUserId,
    this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  RealtimeChannel? _messageChannel;

  List<Map<String, dynamic>> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;
  bool _isConnected = false;

  static const Color green =
      Color(0xFF007749);

  static const Color darkGreen =
      Color(0xFF005A38);

  static const Color ivory =
      Color(0xFFF8F7F2);

  @override
  void initState() {
    super.initState();

    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageChannel?.unsubscribe();

    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD MESSAGES
  // ============================================================

  Future<void> _loadMessages() async {
    if (widget.conversationId.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final data = await _supabase
          .from('messages')
          .select()
          .eq(
            'conversation_id',
            widget.conversationId,
          )
          .order(
            'created_at',
            ascending: true,
          );

      final messages = data
          .map(
            (item) =>
                Map<String, dynamic>.from(item),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (error) {
      debugPrint(
        'Error loading messages: $error',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load messages.',
        isError: true,
      );
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void _subscribeToMessages() {
    if (widget.conversationId.trim().isEmpty) {
      return;
    }

    _messageChannel = _supabase
        .channel(
          'messages-${widget.conversationId}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type:
                PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value:
                widget.conversationId,
          ),
          callback: (payload) {
            final record =
                payload.newRecord;

            if (record.isEmpty) {
              return;
            }

            final message =
                Map<String, dynamic>.from(
              record,
            );

            final id =
                message['id']?.toString();

            final alreadyExists =
                _messages.any(
              (item) =>
                  item['id']?.toString() ==
                  id,
            );

            if (alreadyExists) {
              return;
            }

            if (!mounted) return;

            setState(() {
              _messages.add(message);
            });

            _scrollToBottom();
          },
        )
        .subscribe(
          (status, error) {
            debugPrint(
              'Message realtime status: '
              '$status',
            );

            if (!mounted) return;

            setState(() {
              _isConnected =
                  status == RealtimeSubscribeStatus
                      .subscribed;
            });
          },
        );
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _sendMessage() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to send messages.',
        isError: true,
      );
      return;
    }

    final content =
        _messageController.text.trim();

    if (content.isEmpty) {
      return;
    }

    if (widget.conversationId
        .trim()
        .isEmpty) {
      _showMessage(
        'This conversation is not available.',
        isError: true,
      );
      return;
    }

    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final inserted = await _supabase
          .from('messages')
          .insert({
        'conversation_id':
            widget.conversationId,
        'sender_id': user.id,
        'content': content,
      })
          .select()
          .single();

      final message =
          Map<String, dynamic>.from(
        inserted,
      );

      final alreadyExists =
          _messages.any(
        (item) =>
            item['id']?.toString() ==
            message['id']?.toString(),
      );

      if (!alreadyExists && mounted) {
        setState(() {
          _messages.add(message);
        });
      }

      _messageController.clear();

      _scrollToBottom();
    } on PostgrestException catch (error) {
      debugPrint(
        'Database error sending message: '
        '${error.message}',
      );

      if (mounted) {
        _showMessage(
          'Unable to send message:\n'
          '${error.message}',
          isError: true,
        );
      }
    } catch (error) {
      debugPrint(
        'Error sending message: $error',
      );

      if (mounted) {
        _showMessage(
          'Unable to send message.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController
            .position
            .maxScrollExtent,
        duration:
            const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String _formatTime(dynamic value) {
    final date = _parseDate(value);

    if (date == null) {
      return '';
    }

    final local = date.toLocal();

    final hour =
        local.hour == 0
            ? 12
            : local.hour > 12
                ? local.hour - 12
                : local.hour;

    final minute =
        local.minute.toString().padLeft(2, '0');

    final suffix =
        local.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $suffix';
  }

  String _formatDay(dynamic value) {
    final date = _parseDate(value);

    if (date == null) {
      return '';
    }

    final local = date.toLocal();
    final now = DateTime.now();

    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return 'Today';
    }

    final yesterday =
        now.subtract(
      const Duration(days: 1),
    );

    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'Yesterday';
    }

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  // ============================================================
  // USER NAME
  // ============================================================

  String get _displayName {
    final name =
        widget.otherUserName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'Sisonke Member';
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Colors.red.shade700
                : green,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF18201D),
        elevation: 0,

        titleSpacing: 0,

        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  green.withAlpha(20),
              child: const Icon(
                Icons.person,
                color: green,
                size: 22,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration:
                            BoxDecoration(
                          shape:
                              BoxShape.circle,
                          color:
                              _isConnected
                                  ? green
                                  : Colors.grey,
                        ),
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Text(
                        _isConnected
                            ? 'Connected'
                            : 'Private conversation',
                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          _buildSafetyBanner(),

          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color: green,
                    ),
                  )
                : _buildMessages(),
          ),

          _buildMessageComposer(),
        ],
      ),
    );
  }

  // ============================================================
  // SAFETY BANNER
  // ============================================================

  Widget _buildSafetyBanner() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        4,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: green.withAlpha(12),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: green,
            size: 20,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Keep communication respectful and never share passwords, PINs or sensitive financial information.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color:
                    Color(0xFF47524E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(30),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.all(18),
                decoration:
                    BoxDecoration(
                  color:
                      green.withAlpha(18),
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 38,
                  color: green,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Start the conversation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Introduce yourself and discuss how you can work together to solve the help request.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller:
          _scrollController,
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        20,
      ),
      itemCount:
          _messages.length,
      itemBuilder:
          (context, index) {
        final message =
            _messages[index];

        final previous =
            index > 0
                ? _messages[index - 1]
                : null;

        final currentDate =
            _parseDate(
          message['created_at'],
        );

        final previousDate =
            previous == null
                ? null
                : _parseDate(
                    previous['created_at'],
                  );

        final showDay =
            previousDate == null ||
            currentDate == null ||
            previousDate.year !=
                currentDate.year ||
            previousDate.month !=
                currentDate.month ||
            previousDate.day !=
                currentDate.day;

        return Column(
          children: [
            if (showDay)
              _buildDayDivider(
                message['created_at'],
              ),

            _buildMessageBubble(
              message,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayDivider(
    dynamic value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              color:
                  Color(0xFFE0E4E2),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            child: Text(
              _formatDay(value),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              color:
                  Color(0xFFE0E4E2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
  ) {
    final user =
        _supabase.auth.currentUser;

    final senderId =
        message['sender_id']
            ?.toString();

    final bool isMine =
        user != null &&
        senderId == user.id;

    final content =
        message['content']
                ?.toString()
                .trim() ??
            '';

    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                      .size
                      .width *
                  0.78,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 8,
        ),
        padding:
            const EdgeInsets.fromLTRB(
          14,
          10,
          14,
          8,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? green
              : Colors.white,
          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(
              18,
            ),
            topRight:
                const Radius.circular(
              18,
            ),
            bottomLeft:
                Radius.circular(
              isMine ? 18 : 4,
            ),
            bottomRight:
                Radius.circular(
              isMine ? 4 : 18,
            ),
          ),
          boxShadow: [
            if (!isMine)
              BoxShadow(
                color:
                    Colors.black.withAlpha(
                  8,
                ),
                blurRadius: 5,
                offset:
                    const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: isMine
                    ? Colors.white
                    : const Color(
                        0xFF26312D,
                      ),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              _formatTime(
                message['created_at'],
              ),
              style: TextStyle(
                fontSize: 9.5,
                color: isMine
                    ? Colors.white
                        .withAlpha(190)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMPOSER
  // ============================================================

  Widget _buildMessageComposer() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        12,
        9,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withAlpha(12),
            blurRadius: 12,
            offset:
                const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller:
                    _messageController,
                minLines: 1,
                maxLines: 5,
                textCapitalization:
                    TextCapitalization.sentences,
                onSubmitted: (_) {
                  _sendMessage();
                },
                decoration:
                    InputDecoration(
                  hintText:
                      'Write a message...',
                  filled: true,
                  fillColor:
                      const Color(
                    0xFFF2F4F3,
                  ),
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    borderSide:
                        const BorderSide(
                      color: green,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            Material(
              color: green,
              shape:
                  const CircleBorder(),
              child: InkWell(
                customBorder:
                    const CircleBorder(),
                onTap:
                    _isSending
                        ? null
                        : _sendMessage,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: _isSending
                      ? const Padding(
                          padding:
                              EdgeInsets.all(
                            14,
                          ),
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color:
                              Colors.white,
                          size: 21,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
