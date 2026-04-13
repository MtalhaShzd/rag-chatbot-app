import 'package:dio/dio.dart';

class ApiService {
  static const _baseUrl = 'http://localhost:8000';

  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(minutes: 2),
    receiveTimeout: const Duration(minutes: 4),
  ));

  Future<Map<String, dynamic>> sendMessage(
      String question, String language, String mode) async {
    final res = await _dio.post('/chat', queryParameters: {
      'question': question,
      'language': language,
      'mode': mode,
    });
    return res.data as Map<String, dynamic>;
  }

  // Mobile upload — uses file path
  Future<Map<String, dynamic>> uploadFile(
      String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath, filename: fileName),
    });
    final res = await _dio.post('/upload', data: formData);
    return res.data as Map<String, dynamic>;
  }

  // Web upload — uses bytes
  Future<Map<String, dynamic>> uploadFileBytes(
      List<int> bytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes, filename: fileName),
    });
    final res = await _dio.post('/upload', data: formData);
    return res.data as Map<String, dynamic>;
  }

  Future<void> resetIndex() async {
    await _dio.post('/reset');
  }
}