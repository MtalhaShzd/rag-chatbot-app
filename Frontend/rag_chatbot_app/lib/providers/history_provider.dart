import 'package:flutter/material.dart';

class HistoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> get sessions => _sessions;

  void setSessions(List<Map<String, dynamic>> data) {
    _sessions = data;
    notifyListeners();
  }

  void clear() {
    _sessions = [];
    notifyListeners();
  }
}