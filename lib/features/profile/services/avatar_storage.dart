import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// 會員頭像先存在手機裡（後端還沒有頭像 API），換手機或重新安裝就會不見。
///
/// 每個帳號各存一張，放在 App 文件資料夾的 avatars/ 底下。
/// 之後後端有頭像 API 時，只要改這個 class，畫面不用動。
class AvatarStorage {
  /// 測試時換成暫存資料夾
  @visibleForTesting
  static Future<Directory> Function() baseDirectory =
      getApplicationDocumentsDirectory;

  static Future<Directory> _avatarDir() async {
    final base = await baseDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}avatars');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 帳號可能有 @ 或中文，轉成檔名安全的字串
  static String _prefix(String username) =>
      '${base64Url.encode(utf8.encode(username)).replaceAll('=', '')}_';

  static Future<List<File>> _filesOf(String username) async {
    final dir = await _avatarDir();
    final prefix = _prefix(username);
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith(prefix))
        .toList();
  }

  /// 目前頭像的圖片內容，沒設定過是 null。
  /// 回傳 bytes 讓畫面用 Image.memory 顯示，圖片元件不會一直開著檔案，
  /// 換頭像、移除時才刪得掉舊檔
  static Future<Uint8List?> load(String username) async {
    final files = await _filesOf(username);
    if (files.isEmpty) return null;
    // 檔名帶存檔時間，最新的排最前面
    files.sort((a, b) => b.path.compareTo(a.path));
    return files.first.readAsBytes();
  }

  /// 存下新頭像並刪掉舊的，回傳新頭像的圖片內容
  static Future<Uint8List> save(String username, XFile picked) async {
    final old = await _filesOf(username);
    final dir = await _avatarDir();
    final target = File(
      '${dir.path}${Platform.pathSeparator}'
      '${_prefix(username)}${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final bytes = await picked.readAsBytes();
    await target.writeAsBytes(bytes, flush: true);
    for (final f in old) {
      await _tryDelete(f);
    }
    return bytes;
  }

  static Future<void> remove(String username) async {
    for (final f in await _filesOf(username)) {
      await _tryDelete(f);
    }
  }

  /// 刪不掉（例如檔案還被開著）就留著，下次存檔或移除時會再清一次；
  /// 舊檔留著也不影響，load 只拿最新的那張
  static Future<void> _tryDelete(File file) async {
    try {
      await file.delete();
    } on FileSystemException catch (e) {
      debugPrint('舊頭像刪除失敗：$e');
    }
  }
}
