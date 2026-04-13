import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/colors.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  const AudioPlayerWidget({super.key, required this.audioUrl});
  @override
  State<AudioPlayerWidget> createState() =>
    _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState
    extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  bool _playing = false;
  bool _loading = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _playing = state.playing;
        if (state.processingState ==
            ProcessingState.completed) {
          _playing = false;
          _player.seek(Duration.zero);
          _player.pause();
        }
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
      return;
    }

    if (!_loaded) {
      setState(() => _loading = true);
      try {
        await _player.setUrl(widget.audioUrl);
        _loaded = true;
      } catch (e) {
        debugPrint('Audio load error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot play audio: $e'),
              backgroundColor: AppColors.error));
        }
        setState(() => _loading = false);
        return;
      }
      setState(() => _loading = false);
    }
    await _player.play();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _loading
          ? const SizedBox(
              width: 26, height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent))
          : GestureDetector(
              onTap: _togglePlay,
              child: Icon(
                _playing
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
                color: AppColors.accent,
                size: 32)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voice response',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w500)),
            Text(
              _loading
                ? 'Loading...'
                : _playing
                  ? 'Playing...'
                  : 'Tap to play',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary)),
          ]),
      ]),
    );
  }
}