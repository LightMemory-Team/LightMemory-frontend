import 'package:audioplayers/audioplayers.dart';

class SoundPlayer {
  static final AudioPlayer _player = AudioPlayer();

  /// 一般點擊音效（選菜、按按鈕時）
  static Future<void> playClick() async {
    await _player.play(AssetSource('audio/normal.mp3'));
  }

  /// 答對音效
  static Future<void> playCorrect() async {
    await _player.play(AssetSource('audio/correct.mp3'));
  }

  /// 答錯音效
  static Future<void> playWrong() async {
    await _player.play(AssetSource('audio/no.mp3'));
  }
  /// 找零正確音效
  static Future<void> playCashiering() async {
  await _player.play(AssetSource('audio/cashiering.mp3'));
}
}