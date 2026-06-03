import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/status_model.dart';

/// In-app audio player using just_audio.
/// Supports both audio and music variants with distinct accent colors.
class AudioPlayerWidget extends StatefulWidget {
  final MediaInfo media;

  const AudioPlayerWidget({super.key, required this.media});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  bool _hasError = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final duration = await _player.setUrl(widget.media.url);
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
          _isLoading = false;
        });
      }

      _player.positionStream.listen((position) {
        if (mounted) setState(() => _position = position);
      });

      _player.playerStateStream.listen((state) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.media.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMusic = widget.media.isMusic;
    final accent = isMusic ? const Color(0xFFFF9800) : const Color(0xFF4CAF50);

    if (_hasError) {
      return _buildError(isDark, accent);
    }

    final isPlaying = _player.playing;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: isDark ? 0.15 : 0.08),
              accent.withValues(alpha: isDark ? 0.05 : 0.02),
            ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.2 : 0.15),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Play/Pause button
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          if (isPlaying) {
                            _player.pause();
                          } else {
                            _player.play();
                          }
                        },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.15),
                      border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: _isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accent,
                            ),
                          )
                        : Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: accent,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.media.name ?? (isMusic ? 'Music' : 'Audio'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      // Duration text
                      Text(
                        '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                // Type icon
                Icon(
                  isMusic ? Icons.music_note_rounded : Icons.mic_rounded,
                  color: accent.withValues(alpha: 0.4),
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: accent,
                inactiveTrackColor: accent.withValues(alpha: 0.2),
                thumbColor: accent,
                overlayColor: accent.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        final newPosition = Duration(
                          milliseconds: (value * _duration.inMilliseconds).toInt(),
                        );
                        _player.seek(newPosition);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.05),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Failed to load audio',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _openExternally,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Open'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
