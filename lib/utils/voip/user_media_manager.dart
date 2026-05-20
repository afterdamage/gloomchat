import 'package:just_audio/just_audio.dart';

class UserMediaManager {
  factory UserMediaManager() => _instance;
  UserMediaManager._internal();
  static final UserMediaManager _instance = UserMediaManager._internal();

  AudioPlayer? _assetsAudioPlayer;

  Future<void> startRingingTone() async {
    // Dispose any previous player before creating a new one.
    await stopRingingTone();
    const path = 'assets/sounds/phone.ogg';
    final player = _assetsAudioPlayer = AudioPlayer();
    await player.setLoopMode(LoopMode.one);
    await player.setAsset(path);
    await player.play();
  }

  Future<void> stopRingingTone() async {
    final player = _assetsAudioPlayer;
    _assetsAudioPlayer = null;
    await player?.stop();
    await player?.dispose();
  }
}
