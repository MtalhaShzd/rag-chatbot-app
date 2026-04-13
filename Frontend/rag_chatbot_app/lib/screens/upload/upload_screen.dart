import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../core/theme/colors.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _uploading = false;
  String? _fileName;
  Map<String, dynamic>? _result;

  static const _baseUrl = 'http://localhost:8000';

  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(minutes: 3),
    receiveTimeout: const Duration(minutes: 5),
  ));

  Future<void> _pickAndUpload() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true, // required for web
        allowedExtensions: [
          'pdf', 'docx', 'pptx', 'xlsx',
          'xls', 'csv', 'png', 'jpg', 'jpeg',
          'mp4',
        ],
      );

      if (res == null || res.files.isEmpty) return;
      final file = res.files.single;

      if (file.bytes == null) {
        setState(() {
          _result = {'error': 'Could not read file bytes.'};
        });
        return;
      }

      setState(() {
        _uploading = true;
        _fileName = file.name;
        _result = null;
      });

      // Upload using bytes (works on web)
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
      });

      final response = await _dio.post(
        '/upload',
        data: formData,
      );

      setState(() {
        _result = response.data as Map<String, dynamic>;
      });

    } catch (e) {
      setState(() {
        _result = {'error': 'Upload failed: $e'};
      });
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _resetIndex() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Knowledge Base?'),
        content: const Text(
          'This will delete all uploaded documents '
          'from the FAISS index. You will need to '
          're-upload files to use document mode.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _uploading = true;
                _result = null;
              });
              try {
                await _dio.post('/reset');
                setState(() {
                  _result = {
                    'message': 'Knowledge base cleared!',
                    'chunks': 0,
                    'reset': true,
                  };
                });
              } catch (e) {
                setState(() {
                  _result = {
                    'error': 'Reset failed: $e'
                  };
                });
              } finally {
                setState(() => _uploading = false);
              }
            },
            child: const Text('Reset',
              style: TextStyle(
                color: AppColors.error))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
        actions: [
          // Reset FAISS button in app bar
          Tooltip(
            message: 'Reset knowledge base',
            child: IconButton(
              icon: const Icon(
                Icons.refresh,
                color: AppColors.error),
              onPressed: _uploading ? null : _resetIndex,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent
                  .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.accent
                    .withValues(alpha: 0.3))),
              child: const Row(children: [
                Icon(Icons.info_outline,
                  color: AppColors.accent, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upload a document then switch to '
                    'Document Mode in Settings to '
                    'ask questions about it.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accent))),
              ]),
            ),
            const SizedBox(height: 20),

            // Supported formats
            const Text('Supported formats',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: const [
                _FileTypeCard(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf,
                  color: Color(0xFFFF4D4D)),
                _FileTypeCard(
                  label: 'Word/DOCX',
                  icon: Icons.description,
                  color: Color(0xFF2B579A)),
                _FileTypeCard(
                  label: 'Excel/CSV',
                  icon: Icons.table_chart,
                  color: Color(0xFF34C87A)),
                _FileTypeCard(
                  label: 'Image OCR',
                  icon: Icons.image,
                  color: Color(0xFFF5A623)),
                _FileTypeCard(
                  label: 'PowerPoint',
                  icon: Icons.slideshow,
                  color: Color(0xFFD04423)),
 _FileTypeCard(          
      label: 'Video MP4',
      icon: Icons.videocam,
      color: Color(0xFF7C6AF7)),
              ],
            ),
            const SizedBox(height: 24),

            // Upload drop zone
            GestureDetector(
              onTap: _uploading ? null : _pickAndUpload,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 170,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _uploading
                      ? AppColors.accent
                      : AppColors.darkBorder,
                    width: 1.5,
                  ),
                ),
                child: _uploading
                  ? Column(
                      mainAxisAlignment:
                        MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.accent),
                        const SizedBox(height: 16),
                        Text(
                          'Uploading $_fileName...',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14)),
                        const SizedBox(height: 6),
                        const Text(
                          'Please wait',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                      ])
                  : Column(
                      mainAxisAlignment:
                        MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 52,
                          color: AppColors.accent),
                        const SizedBox(height: 14),
                        const Text(
                          'Tap to select a file',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        const Text(
                          'PDF, DOCX, XLSX, PNG, JPEG...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                      ]),
              ),
            ),
            const SizedBox(height: 20),

            // Result card
            if (_result != null)
              _ResultCard(result: _result!),

            const SizedBox(height: 24),

            // Reset section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error
                  .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.error
                    .withValues(alpha: 0.2))),
              child: Column(
                crossAxisAlignment:
                  CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.warning_amber_outlined,
                      color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('Danger Zone',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    'Reset the knowledge base to remove '
                    'all uploaded documents. This cannot '
                    'be undone.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _uploading
                        ? null
                        : _resetIndex,
                      icon: const Icon(
                        Icons.delete_sweep_outlined,
                        color: AppColors.error),
                      label: const Text(
                        'Reset Knowledge Base',
                        style: TextStyle(
                          color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.error),
                        padding:
                          const EdgeInsets.symmetric(
                            vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                            BorderRadius.circular(10))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _FileTypeCard({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isError = result.containsKey('error');
    final isReset = result.containsKey('reset');
    final color = isError
      ? AppColors.error
      : AppColors.success;

    String message;
    if (isError) {
      message = '❌ ${result['error']}';
    } else if (isReset) {
      message = '🗑️ Knowledge base has been reset successfully.';
    } else {
      final chunks = result['chunks'] ?? 0;
      message =
        '✅ Document uploaded! $chunks text chunks '
        'indexed. Switch to Document Mode in '
        'Settings to query it.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.4))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
              ? Icons.error_outline
              : Icons.check_circle_outline,
            color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
              style: TextStyle(
                color: color, fontSize: 13))),
        ],
      ),
    );
  }
}