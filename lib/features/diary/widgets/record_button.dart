import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../../../theme/app_theme.dart';

enum RecordButtonState { idle, recording, paused, uploading }

class RecordButton extends StatefulWidget {
  /// 使用者按下「完成」、錄音正式結束時呼叫，
  /// 回傳錄好的音檔與這段錄了幾秒；15 秒門檻這類規則由外部（頁面）自行判斷。
  final void Function(XFile audioFile, int elapsedSeconds) onRoundComplete;

  const RecordButton({super.key, required this.onRoundComplete});

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  final AudioRecorder _recorder = AudioRecorder();
  RecordButtonState _state = RecordButtonState.idle;
  int _elapsedSeconds = 0;
  Timer? _timer;

  /// 外部（頁面）判斷這段錄音不合格（例如太短）時呼叫，讓按鈕回到待機狀態重錄
  void resetToIdle() {
    setState(() {
      _state = RecordButtonState.idle;
      _elapsedSeconds = 0;
    });
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;
    // 手機/桌面需要指定存檔路徑，網頁環境這個參數會被忽略，錄音存在瀏覽器記憶體裡
    await _recorder.start(const RecordConfig(), path: 'round_audio');
    setState(() {
      _state = RecordButtonState.recording;
      _elapsedSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    _timer?.cancel();
    setState(() => _state = RecordButtonState.paused);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    setState(() => _state = RecordButtonState.recording);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _completeRecording() async {
    _timer?.cancel();
    setState(() => _state = RecordButtonState.uploading);
    final path = await _recorder.stop();
    if (path == null) {
      resetToIdle();
      return;
    }
    widget.onRoundComplete(XFile(path), _elapsedSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(_elapsedSeconds),
          style: TextStyle(
            fontSize: AppTheme.fontTimer,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
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
                    border: Border.all(color: AppTheme.primaryColor, width: 3),
                  ),
                  child: Icon(Icons.check, color: AppTheme.primaryColor, size: 32),
                ),
              ),
            ],
          ],
        ),
      ],
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