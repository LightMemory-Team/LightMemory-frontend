import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static Future _play(String fileName) async {
    try {
      debugPrint('👉 開始播放音效: $fileName');
      final player = AudioPlayer();
      await player.play(AssetSource('audio/$fileName'));
      // 播完自動釋放資源，避免佔用通道
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
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
