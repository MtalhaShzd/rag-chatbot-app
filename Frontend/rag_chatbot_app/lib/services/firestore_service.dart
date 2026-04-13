import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveMessage(String userId, MessageModel message) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('messages')
          .doc(message.id)
          .set({
        'id': message.id,
        'role': message.role,
        'content': message.content,
        'timestamp': message.timestamp.toIso8601String(),
        'audioPath': message.audioPath,
        'isError': message.isError,
      });
    } catch (e) {
      print('Firestore save error: $e');
    }
  }

  Future<void> createSession(String userId, String sessionId, String title) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .set({
        'title': title,
        'preview': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Firestore session error: $e');
    }
  }
}