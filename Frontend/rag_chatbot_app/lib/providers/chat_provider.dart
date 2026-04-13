import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';

class ChatProvider extends ChangeNotifier {
  final _api       = ApiService();
  final _firestore = FirestoreService();

  final List<MessageModel> _messages = [];
  List<MessageModel> get messages => List.unmodifiable(_messages);

  bool _thinking = false;
  bool get thinking => _thinking;

  String _language = 'english';
  String get language => _language;

  // NEW — chat mode
  String _mode = 'general'; 
  String get mode => _mode;
  bool get isDocumentMode => _mode == 'document';

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void setMode(String mode) {
    _mode = mode;
    notifyListeners();
  }

  Future<void> sendMessage(String text, String userId) async {
    final userMsg = MessageModel(
      id: DateTime.now().toIso8601String(),
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _thinking = true;
    notifyListeners();

    try {
      final res = await _api.sendMessage(text, _language, _mode);
      final aiMsg = MessageModel(
        id: '${DateTime.now().toIso8601String()}_ai',
        role: 'assistant',
        content: res['answer'] ?? '',
        audioPath: res['audio_url'],
        timestamp: DateTime.now(),
      );
      _messages.add(aiMsg);
      await _firestore.saveMessage(userId, userMsg);
      await _firestore.saveMessage(userId, aiMsg);
    } catch (e) {
      _messages.add(MessageModel(
        id: 'err_${DateTime.now()}',
        role: 'assistant',
        content: 'Something went wrong. Please try again.',
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      _thinking = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}