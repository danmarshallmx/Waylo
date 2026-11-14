import 'package:flutter/material.dart';
import 'package:waylo/core/models/audio_capsule.dart';
import 'package:waylo/features/geolocation/services/audio_player_service.dart';

class AudioPlayerWidget extends StatelessWidget {
  final AudioCapsule capsule;
  final AudioPlayerService audioService;
  final VoidCallback? onClose;

  const AudioPlayerWidget({
    super.key,
    required this.capsule,
    required this.audioService,
    this.onClose,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.headphones_rounded, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cápsula de Audio Cultural',
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      capsule.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    audioService.stop();
                    onClose?.call();
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<Duration>(
            stream: audioService.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: audioService.durationStream,
                builder: (context, durSnapshot) {
                  final duration = durSnapshot.data ?? const Duration(seconds: 90);
                  final progress = duration.inMilliseconds > 0
                      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0;

                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(_formatDuration(duration), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded),
                            onPressed: () {
                              final newPos = position - const Duration(seconds: 10);
                              audioService.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
                            },
                          ),
                          StreamBuilder<bool>(
                            stream: audioService.playingStream,
                            builder: (context, playSnap) {
                              final isPlaying = playSnap.data ?? false;
                              return IconButton.filled(
                                icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                onPressed: () {
                                  if (isPlaying) {
                                    audioService.pause();
                                  } else {
                                    audioService.resume();
                                  }
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.forward_10_rounded),
                            onPressed: () {
                              final newPos = position + const Duration(seconds: 10);
                              audioService.seekTo(newPos);
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
