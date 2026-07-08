import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/utils/platform_infos.dart';

/// The single owner of all call-related sounds.
///
/// Exactly one ringtone (incoming) or ringback (outgoing) loop can play at a
/// time and every start/stop is idempotent, so it is safe to drive this from
/// both the SDK delegate callbacks and the call controller without ever
/// ending up with two overlapping players — which is what happened when each
/// call widget owned its own [AudioPlayer].
class CallSounds {
  CallSounds._();
  static final CallSounds instance = CallSounds._();

  static const _ringtoneAsset = 'assets/sounds/phone.ogg';
  static const _ringbackAsset = 'assets/sounds/dialup.ogg';

  /// just_audio has no Linux/Windows implementation in this project, so
  /// attempting playback there throws. Web, Android, iOS and macOS work.
  bool get _canPlay =>
      PlatformInfos.isWeb || PlatformInfos.isMobile || PlatformInfos.isMacOS;

  AudioPlayer? _player;
  String? _playingAsset;

  Future<void> startRingtone() => _startLoop(_ringtoneAsset);

  Future<void> startRingback() => _startLoop(_ringbackAsset);

  Future<void> _startLoop(String asset) async {
    if (!_canPlay) return;
    if (_playingAsset == asset) return; // already playing this loop
    await stop();
    try {
      final player = AudioPlayer();
      _player = player;
      _playingAsset = asset;
      await player.setLoopMode(LoopMode.one);
      await player.setAsset(asset);
      // Do not await play() — it completes when playback stops.
      player.play().catchError((e) {
        Logs().w('[CallSounds] play failed for $asset: $e');
      });
    } catch (e) {
      Logs().w('[CallSounds] Failed to start $asset: $e');
      _playingAsset = null;
    }
  }

  Future<void> stop() async {
    final player = _player;
    _player = null;
    _playingAsset = null;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (_) {}
  }
}
