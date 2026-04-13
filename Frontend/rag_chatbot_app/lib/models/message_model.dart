class MessageModel {
  final String id;
  final String role;       // 'user' or 'assistant'
  final String content;
  final String? audioPath;
  final DateTime timestamp;
  final bool isError;

  MessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.audioPath,
    required this.timestamp,
    this.isError = false,
  });
}