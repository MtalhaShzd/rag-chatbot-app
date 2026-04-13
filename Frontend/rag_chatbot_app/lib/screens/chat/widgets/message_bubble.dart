// lib/screens/chat/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../models/message_model.dart';
import '../../../core/theme/colors.dart';
import 'audio_player_widget.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  const MessageBubble({super.key, required this.message});

  bool get isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(radius: 16, backgroundColor: AppColors.accent,
              child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                  ? AppColors.userBubble
                  : (message.isError ? AppColors.error.withOpacity(0.15) : AppColors.aiBubble),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: message.isError
                  ? Border.all(color: AppColors.error.withOpacity(0.4)) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Markdown for AI, plain text for user
                  isUser
                    ? Text(message.content,
                        style: const TextStyle(fontSize: 15, height: 1.5))
                    : MarkdownBody(
                        data: message.content,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: const TextStyle(fontSize: 15, height: 1.6),
                          code: TextStyle(
                            fontFamily: 'monospace', fontSize: 13,
                            backgroundColor: AppColors.darkBorder,
                            color: AppColors.accentLight),
                          codeblockDecoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(8)),
                        )),
                  // Audio player if AI message has audio
                  if (!isUser && message.audioPath != null) ...[
                    const SizedBox(height: 10),
                    AudioPlayerWidget(audioUrl: message.audioPath!),
                  ],
                  const SizedBox(height: 4),
                  Text(_formatTime(message.timestamp),
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(radius: 16, backgroundColor: AppColors.darkCard,
              child: const Icon(Icons.person, size: 16, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}