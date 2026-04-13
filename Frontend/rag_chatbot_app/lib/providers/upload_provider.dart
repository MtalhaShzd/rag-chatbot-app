import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class UploadProvider extends ChangeNotifier {
  bool _uploading = false;
  bool get uploading => _uploading;

  String _fileName = '';
  String get fileName => _fileName;

  Map<String, dynamic>? _result;
  Map<String, dynamic>? get result => _result;

  // For mobile — uses file path
  Future<Map<String, dynamic>?> upload(
      String filePath, String fileName) async {
    _uploading = true;
    _fileName = fileName;
    _result = null;
    notifyListeners();
    try {
      final api = ApiService();
      final res = await api.uploadFile(filePath, fileName);
      _result = res;
      return res;
    } catch (e) {
      _result = {'error': e.toString()};
      return _result;
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  // For web — uses bytes
  Future<Map<String, dynamic>?> uploadBytes(
      List<int> bytes, String fileName) async {
    _uploading = true;
    _fileName = fileName;
    _result = null;
    notifyListeners();
    try {
      final api = ApiService();
      final res = await api.uploadFileBytes(bytes, fileName);
      _result = res;
      return res;
    } catch (e) {
      _result = {'error': e.toString()};
      return _result;
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _result = null;
    notifyListeners();
  }
}