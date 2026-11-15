import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _player;

  AudioPlayerService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;

  bool get isPlaying => _player.playing;

  Future<void> play(String pathOrUrl) async {
    try {
      if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
        await _player.setUrl(pathOrUrl);
      } else if (pathOrUrl.startsWith('asset://') || pathOrUrl.startsWith('assets/')) {
        final assetPath = pathOrUrl.replaceFirst('asset://', '');
        await _player.setAsset(assetPath);
      } else if (!pathOrUrl.contains('/') && !pathOrUrl.contains('\\')) {
        // Simple key like 'gdl_catedral' or 'gdl_cabanas'
        await _player.setAsset('assets/audio/$pathOrUrl.m4a');
      } else {
        await _player.setFilePath(pathOrUrl);
      }
      await _player.play();
    } catch (e) {
      debugPrint('Error playing audio capsule: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
