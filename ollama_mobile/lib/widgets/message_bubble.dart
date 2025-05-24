import 'package:flutter/material.dart';
import 'package:ollama_mobile/models/message.dart';
import 'package:ollama_mobile/services/voice_service.dart';
import 'package:provider/provider.dart';
import 'package:ollama_mobile/providers/chat_provider.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback onSpeak;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == 'user';
    final voiceService = Provider.of<VoiceService>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.timestamp.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isUser
                        ? theme.colorScheme.onPrimary.withOpacity(0.7)
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                if (!isUser && !chatProvider.isLoading) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      voiceService.state == VoiceState.speaking &&
                              voiceService.currentSpeakingText == message.content
                          ? Icons.stop
                          : Icons.volume_up,
                      size: 16,
                      color: isUser
                          ? theme.colorScheme.onPrimary.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                    onPressed: onSpeak,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
} 