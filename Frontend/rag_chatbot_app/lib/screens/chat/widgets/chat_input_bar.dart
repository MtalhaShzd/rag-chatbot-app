import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/upload_provider.dart';
import '../../../core/theme/colors.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String) onSend;
  const ChatInputBar({super.key, required this.onSend});
  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
  try {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true, // ← important for web
      allowedExtensions: [
        'pdf', 'docx', 'pptx', 'xlsx',
        'xls', 'csv', 'png', 'jpg', 'jpeg'
      ],
    );

    if (res == null || res.files.isEmpty) return;
    final file = res.files.single;

    if (!mounted) return;

    // Show uploading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white)),
          const SizedBox(width: 12),
          Text('Uploading ${file.name}...'),
        ]),
        duration: const Duration(seconds: 30),
        backgroundColor: AppColors.darkCard,
      ),
    );

    Map<String, dynamic>? result;

    // Web uses bytes, mobile uses path
    if (file.bytes != null) {
      result = await context.read<UploadProvider>()
        .uploadBytes(file.bytes!, file.name);
    } else if (file.path != null) {
      result = await context.read<UploadProvider>()
        .upload(file.path!, file.name);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result != null && result.containsKey('error')
            ? '❌ ${result['error']}'
            : '✅ File uploaded! Ask questions about it.'),
        backgroundColor: result != null &&
          result.containsKey('error')
            ? AppColors.error
            : AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload failed: $e'),
        backgroundColor: AppColors.error));
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        border: Border(
          top: BorderSide(
            color: AppColors.darkBorder, width: 0.5))),
      child: Row(children: [
        // Attach button
        IconButton(
          icon: const Icon(Icons.attach_file_rounded),
          color: AppColors.textSecondary,
          tooltip: 'Upload file',
          onPressed: _pickFile,
        ),
        // Text field
        Expanded(
          child: TextField(
            controller: _ctrl,
            maxLines: 5,
            minLines: 1,
            textInputAction: TextInputAction.newline,
            onChanged: (v) => setState(
              () => _hasText = v.trim().isNotEmpty),
            decoration: InputDecoration(
              hintText: 'Ask anything...',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none),
              filled: true,
              fillColor: AppColors.darkCard,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Send button
        GestureDetector(
          onTap: _hasText ? _send : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _hasText
                ? AppColors.accent
                : AppColors.darkCard,
              borderRadius: BorderRadius.circular(22)),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: _hasText
                ? Colors.white
                : AppColors.textSecondary,
              size: 20),
          ),
        ),
      ]),
    );
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _ctrl.clear();
    setState(() => _hasText = false);
  }
}