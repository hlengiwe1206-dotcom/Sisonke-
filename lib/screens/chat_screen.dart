import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/chat_service.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final String connectionId;
  final String title;

  const ChatScreen({
    super.key,
    required this.connectionId,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatService service;

  final TextEditingController controller = TextEditingController();

  String? conversationId;
  bool loading = true;

  @override
  void initState() {
    super.initState();

    service = ChatService(
      Supabase.instance.client,
    );

    _load();
  }

  Future<void> _load() async {
    final id = await service.conversationForConnection(
      widget.connectionId,
    );

    if (!mounted) return;

    setState(() {
      conversationId = id;
      loading = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = controller.text.trim();

    if (text.isEmpty || conversationId == null) {
      return;
    }

    await service.send(
      conversationId!,
      text,
    );

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : conversationId == null
              ? const Center(
                  child: Text(
                    'Conversation is not available yet.',
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<SisonkeMessage>>(
                        stream: service.watchMessages(
                          conversationId!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Unable to load messages: '
                                '${snapshot.error}',
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final messages = snapshot.data!;
                          final myUserId = service.userId;

                          if (messages.isEmpty) {
                            return const Center(
                              child: Text(
                                'No messages yet. Start the conversation.',
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];

                              final isMine =
                                  message.senderId == myUserId;

                              return Align(
                                alignment: isMine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 8,
                                  ),
                                  padding: const EdgeInsets.all(
                                    12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    message.content,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                minLines: 1,
                                maxLines: 4,
                                onSubmitted: (_) {
                                  _sendMessage();
                                },
                                decoration:
                                    const InputDecoration(
                                  hintText:
                                      'Write a message...',
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            IconButton.filled(
                              onPressed: _sendMessage,
                              icon: const Icon(
                                Icons.send,
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
