import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  // 重複利用同一個 AudioPlayer 實例，避免不斷向 Android 系統申請通道導致卡死
  static final AudioPlayer _player = AudioPlayer();
  static bool _isInitialized = false;

  static Future _init() async {
    if (_isInitialized) return;
    try {
      // 設置為低延遲模式（在 Android 上會使用 SoundPool，專門給遊戲短音效使用）
      await _player.setPlayerMode(PlayerMode.lowLatency);
      // 設置音訊焦點，避免被系統靜音
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ AudioService 初始化異常: $e');
    }
  }

  static Future _play(String fileName) async {
    try {
      await _init();
      debugPrint('👉 開始播放音效: $fileName');
      // 如果上一段音效還在播，先停止並回到開頭，確保立刻重播
      await _player.stop();
      await _player.play(
        AssetSource('audio/$fileName'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e, stack) {
      debugPrint('❌ 播放音效失敗 (\(fileName):\)e');
      debugPrint('$stack');
    }
  }

  static Future playCorrect() async => _play('correct.mp3');
  static Future playWrong() async => _play('no.mp3');
  static Future playClick() async => _play('normal.mp3');
  static Future playLevelUp() async => _play('correct.mp3');
}
