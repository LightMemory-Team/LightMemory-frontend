import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';

enum RecordButtonState { idle, recording, paused, uploading }

class RecordButton extends StatefulWidget {
  /// 使用者按下「完成」、錄音正式結束時呼叫，
  /// 回傳錄好的音檔與這段錄了幾秒；15 秒門檻這類規則由外部（頁面）自行判斷。
  final void Function(XFile audioFile, int elapsedSeconds) onRoundComplete;
  /// 每次內部狀態變化時通知外部（例如頁面要知道現在是不是正在錄音中，
  /// 用來決定「跳過」「提前完成」這些按鈕要不要顯示）
  final void Function(RecordButtonState state)? onStateChanged;
  /// 錄音發生任何失敗時，把可以顯示給使用者看的訊息往外拋
  final void Function(String message)? onError;

  const RecordButton({
    super.key,
    required this.onRoundComplete,
    this.onStateChanged,
    this.onError,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  final AudioRecorder _recorder = AudioRecorder();
  RecordButtonState _state = RecordButtonState.idle;
  int _elapsedSeconds = 0;
  Timer? _timer;
  StreamSubscription<Amplitude>? _amplitudeSub;

  static const int maxRecordSeconds = 180; // 單輪最長 3 分鐘，時間到自動送出
  static const int _barCount = 12;
  static const double _minBarHeight = 8;
  static const double _maxBarHeight = 48;
  final List<double> _barHeights = List.filled(_barCount, _minBarHeight);
  final Random _random = Random();

  // Chrome 等瀏覽器的 MediaRecorder 不支援預設的 AAC 編碼，
  // 改用 Opus（webm）在 web 跟大多數手機瀏覽器上都能正常錄音。
  RecordConfig get _recordConfig {
    return const RecordConfig(encoder: AudioEncoder.opus);
  }

  void _updateState(RecordButtonState newState) {
    setState(() => _state = newState);
    widget.onStateChanged?.call(newState);
  }

  /// 外部（頁面）判斷這段錄音不合格（例如太短）時呼叫，讓按鈕回到待機狀態重錄
  void resetToIdle() {
    _timer?.cancel();
    _stopAmplitudeListening();
    setState(() {
      _state = RecordButtonState.idle;
      _elapsedSeconds = 0;
    });
    widget.onStateChanged?.call(RecordButtonState.idle);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= maxRecordSeconds) {
        _completeRecording();
      }
    });
  }

  void _listenAmplitude() {
    _amplitudeSub?.cancel();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 150))
        .listen((amp) {
      if (!mounted) return;
      final level = ((amp.current + 60) / 60).clamp(0.0, 1.0);
      setState(() {
        for (var i = 0; i < _barHeights.length; i++) {
          final jitter = 0.55 + _random.nextDouble() * 0.45;
          _barHeights[i] =
              _minBarHeight + (level * (_maxBarHeight - _minBarHeight) * jitter);
        }
      });
    });
  }

  void _stopAmplitudeListening() {
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _barHeights.length; i++) {
        _barHeights[i] = _minBarHeight;
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      debugPrint('[RecordButton] hasPermission: $hasPermission');
      if (!hasPermission) {
        widget.onError?.call('沒有取得麥克風權限，請允許瀏覽器使用麥克風');
        return;
      }
      await _recorder.start(_recordConfig, path: 'round_audio.webm');
      final isRecording = await _recorder.isRecording();
      debugPrint('[RecordButton] start() 之後 isRecording: $isRecording');
      if (!isRecording) {
        widget.onError?.call('錄音無法啟動，請確認瀏覽器麥克風權限後再試一次');
        return;
      }
      setState(() {
        _state = RecordButtonState.recording;
        _elapsedSeconds = 0;
      });
      widget.onStateChanged?.call(RecordButtonState.recording);
      _startTimer();
      _listenAmplitude();
    } catch (e) {
      debugPrint('[RecordButton] _startRecording 例外: $e');
      widget.onError?.call('錄音啟動失敗：$e');
    }
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    _timer?.cancel();
    _stopAmplitudeListening();
    _updateState(RecordButtonState.paused);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    _updateState(RecordButtonState.recording);
    _startTimer();
    _listenAmplitude();
  }

  /// 暫停時整段作廢，不用先完成送出再後悔
  Future<void> _restartRecording() async {
    _timer?.cancel();
    _stopAmplitudeListening();
    try {
      await _recorder.stop(); // 丟棄錄好的內容，不使用回傳的路徑
    } catch (e) {
      debugPrint('[RecordButton] _restartRecording stop() 例外: $e');
    }
    if (!mounted) return;
    setState(() {
      _state = RecordButtonState.idle;
      _elapsedSeconds = 0;
    });
    widget.onStateChanged?.call(RecordButtonState.idle);
  }

  Future<void> _completeRecording() async {
    _timer?.cancel();
    _stopAmplitudeListening();
    _updateState(RecordButtonState.uploading);
    try {
      final path = await _recorder.stop();
      debugPrint('[RecordButton] _recorder.stop() 回傳: $path');
      if (path == null) {
        widget.onError?.call('錄音沒有成功產生檔案，請重新錄製');
        resetToIdle();
        return;
      }
      widget.onRoundComplete(XFile(path), _elapsedSeconds);
    } catch (e) {
      debugPrint('[RecordButton] _completeRecording 例外: $e');
      widget.onError?.call('錄音處理失敗：$e');
      resetToIdle();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.fontSizeLevel,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(_elapsedSeconds),
              style: TextStyle(
                fontSize: AppSettings.scaleFont(AppTheme.fontTimer),
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            _buildWaveform(),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _onMicTap,
                  child: Container(
                    width: AppTheme.sizeMicButton,
                    height: AppTheme.sizeMicButton,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _state == RecordButtonState.uploading
                          ? Colors.grey
                          : AppTheme.primaryColor,
                    ),
                    child: Icon(
                      _iconForState(),
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                if (_state == RecordButtonState.recording ||
                    _state == RecordButtonState.paused) ...[
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: _state == RecordButtonState.uploading
                        ? null
                        : _completeRecording,
                    child: Container(
                      width: AppTheme.sizeMicButton,
                      height: AppTheme.sizeMicButton,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_state == RecordButtonState.paused) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _restartRecording,
                child: Text(
                  '重新錄製',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(13),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildWaveform() {
    final active = _state == RecordButtonState.recording;
    return Container(
      width: 230,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barCount, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 4,
            height: active ? _barHeights[i] : _minBarHeight,
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.primaryColor
                  : AppTheme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  void _onMicTap() {
    switch (_state) {
      case RecordButtonState.idle:
        _startRecording();
        break;
      case RecordButtonState.recording:
        _pauseRecording();
        break;
      case RecordButtonState.paused:
        _resumeRecording();
        break;
      case RecordButtonState.uploading:
        break; // 上傳中不接受任何點擊
    }
  }

  IconData _iconForState() {
    switch (_state) {
      case RecordButtonState.idle:
        return Icons.mic;
      case RecordButtonState.recording:
        return Icons.pause;
      case RecordButtonState.paused:
        return Icons.mic;
      case RecordButtonState.uploading:
        return Icons.hourglass_top;
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}