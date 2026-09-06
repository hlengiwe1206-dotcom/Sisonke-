import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  /// The ID of the connection or conversation.
  final String? connectionId;

  /// The name shown at the top of the chat.
  final String title;

  const ChatScreen({
    super.key,
    this.connectionId,
    this.title = 'Sisonke Chat',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final List<Map<String, String>> _messages = [
    {
      'sender': 'Sisonke',
      'message':
          'Welcome to Sisonke. How can we help you today?',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final String message =
        _messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    setState(() {
      _messages.add({
        'sender': 'You',
        'message': message,
      });
    });

    _messageController.clear();

    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(
              milliseconds: 300,
            ),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String chatTitle = widget.title;

    return Scaffold(
      appBar: AppBar(
        title: Text(chatTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (widget.connectionId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Text(
                'Connection ID: ${widget.connectionId}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (
                BuildContext context,
                int index,
              ) {
                final Map<String, String> message =
                    _messages[index];

                final bool isMe =
                    message['sender'] == 'You';

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context)
                                  .size
                                  .width *
                              0.78,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.blue
                          : Colors.grey.shade200,
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['sender'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isMe
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message['message'] ?? '',
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  CircleAvatar(
                    child: IconButton(
                      icon:
                          const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
