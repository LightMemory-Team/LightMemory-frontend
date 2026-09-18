import 'package:audioplayers/audioplayers.dart';

/// 全站共用的音效服務，所有遊戲統一透過這個 service 播放音效
///
/// 用單一 AudioPlayer 實例，不是每種音效各自 new 一個 player
/// （對應設計文件第四節的要求）：這樣暫停/退出時要停止音效，
/// 呼叫端不用先判斷「現在正在播哪一種音效」，直接 stopAll() 就好，邏輯單純。
class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  // 是否啟用音效，對應畫面上的音效開關（音量設定）
  // 之後接上設定頁的真實狀態時，直接把這個值換成從 SettingsService 讀取即可
  static bool _isEnabled = true;

  static bool get isEnabled => _isEnabled;

  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stopAll();
    }
  }

  /// 播放指定音效，assetName 例如 "normal.mp3"、"correct.mp3"
  /// 實際檔案要放在 assets/audio/game/ 底下
  static Future<void> play(String assetName) async {
    if (!_isEnabled) return;
    await _player.stop(); // 播放新音效前先停掉當下播放中的，避免疊加
    await _player.play(AssetSource('audio/game/$assetName'));
  }

  /// 任何離開遊戲主流程的操作（暫停、退出、切到背景）都呼叫這個
  static Future<void> stopAll() async {
    await _player.stop();
  }
}
