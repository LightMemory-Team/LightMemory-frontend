// 會員頁、編輯資料頁的 widget test。後端用 MockClient 假造 /api/users/me/

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:light_memory/features/auth/pages/login_page.dart';
import 'package:light_memory/features/profile/pages/edit_profile_page.dart';
import 'package:light_memory/features/profile/pages/profile_page.dart';
import 'package:light_memory/features/profile/services/avatar_storage.dart';

/// 1x1 的 PNG，當作「使用者選的照片」
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

/// 假的相簿／相機：回傳 [path]；[error] 不是 null 時改成丟出例外（例如沒權限）
class _FakeImagePicker extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  final String path;
  final Object? error;
  ImageSource? lastSource;

  _FakeImagePicker(this.path, {this.error});

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    lastSource = source;
    if (error != null) throw error!;
    return XFile(path);
  }
}

/// 頭像存檔是真的檔案 IO，在測試的假時鐘裡不會自己跑完。存檔有好幾步
/// （建資料夾、讀照片、寫檔、刪舊檔），每一步都要讓真實時間過一下再 pump
Future<void> _settleIO(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// 頭像右下角的相機小圖示（整個頭像都可以點）
final _avatarButton = find.byIcon(Icons.photo_camera_rounded);

final _avatarImage = find.byWidgetPredicate(
  (w) => w is Image && w.image is MemoryImage,
);

const _profileJson = {
  'username': 'demo',
  'nickname': '小美',
  'birth_date': '1950-03-02',
  'gender': 'female',
  'region': 'north',
  'emergency_contact_name': null,
  'emergency_contact_phone': null,
};

/// 假後端：記下送出的 PATCH，[getStatus]／[patchResponse] 可改成失敗情境
class _FakeBackend {
  int getStatus = 200;
  Map<String, dynamic> current = Map.of(_profileJson);

  /// GET /api/users/me/stats/ 的 data；null 時回 500（讀不到統計）
  Map<String, dynamic>? stats;
  (int, Map<String, dynamic>)? patchResponse;
  final List<Map<String, dynamic>> patches = [];

  MockClient client() => MockClient((req) async {
    if (req.url.path.endsWith('/api/users/me/stats/')) {
      final data = stats;
      if (data == null) return http.Response('{}', 500);
      return _json(200, {'success': true, 'data': data, 'error': null});
    }
    if (!req.url.path.endsWith('/api/users/me/')) {
      return http.Response('{}', 404);
    }
    if (req.method == 'GET') {
      if (getStatus != 200) return http.Response('{}', getStatus);
      return _json(200, current);
    }
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    patches.add(body);
    final forced = patchResponse;
    if (forced != null) return _json(forced.$1, forced.$2);
    current = {...current, ...body};
    return _json(200, current);
  });

  http.Response _json(int status, Object body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Future<void> _pumpProfile(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
  await tester.pumpAndSettle();
}

void _profileTest(
  String description,
  Future<void> Function(WidgetTester tester, _FakeBackend backend) body,
) {
  testWidgets(description, (tester) async {
    // 畫面拉高，讓 ListView 一次把登出、儲存按鈕都建出來，不用捲動
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'access_token': 'test'});
    final backend = _FakeBackend();
    await http.runWithClient(
      () => body(tester, backend),
      () => backend.client(),
    );
  });
}

Map<String, dynamic> _statsJson(int streak, {int active = 42}) => {
  'joined_at': '2026-09-01',
  'active_day_count': active,
  'session_count': 120,
  'diary_count': 15,
  'streak_days': streak,
};

void main() {
  _profileTest('連續天數火苗：顯示連續天數與累計活動天數', (tester, backend) async {
    backend.stats = _statsJson(5);
    await _pumpProfile(tester);

    expect(find.text('已連續 5 天'), findsOneWidget);
    expect(find.text('今天也來玩一場或寫篇日記，火苗就不會熄滅'), findsOneWidget);
    expect(find.text('累計活動 42 天'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
  });

  _profileTest('連續天數火苗：7 天以上顯示稱讚', (tester, backend) async {
    backend.stats = _statsJson(8);
    await _pumpProfile(tester);

    expect(find.text('已連續 8 天 🎉'), findsOneWidget);
    expect(find.text('太棒了，繼續保持！'), findsOneWidget);
  });

  _profileTest('連續天數火苗：0 天不顯示「0 天」，改成鼓勵句', (tester, backend) async {
    backend.stats = _statsJson(0, active: 0);
    await _pumpProfile(tester);

    expect(find.text('今天點燃火苗吧！'), findsOneWidget);
    expect(find.textContaining('0 天'), findsNothing);
  });

  _profileTest('統計讀不到時不顯示火苗，會員資料照常', (tester, backend) async {
    backend.stats = null;
    await _pumpProfile(tester);

    expect(find.byIcon(Icons.local_fire_department_rounded), findsNothing);
    expect(find.text('帳號：demo'), findsOneWidget);
  });

  _profileTest('顯示會員資料，沒填的欄位顯示未填寫', (tester, backend) async {
    await _pumpProfile(tester);

    expect(find.text('帳號：demo'), findsOneWidget);
    expect(find.text('女'), findsOneWidget);
    expect(find.text('北部'), findsOneWidget);
    expect(find.textContaining('1950/03/02'), findsOneWidget);
    // 緊急聯絡人、電話沒填
    expect(find.text('未填寫'), findsNWidgets(2));
    expect(find.text('登出'), findsOneWidget);
  });

  _profileTest('沒有暱稱時大字顯示帳號', (tester, backend) async {
    backend.current['nickname'] = '';
    await _pumpProfile(tester);

    expect(find.text('demo'), findsOneWidget);
    expect(find.text('帳號：demo'), findsNothing);
  });

  _profileTest('讀不到會員資料時，快速入口和登出照常顯示', (tester, backend) async {
    backend.getStatus = 500;
    await _pumpProfile(tester);

    expect(find.text('會員資料暫時讀不到'), findsOneWidget);
    expect(find.text('我的週報表'), findsOneWidget);
    expect(find.text('登出'), findsOneWidget);

    backend.getStatus = 200;
    await tester.tap(find.text('再試一次'));
    await tester.pumpAndSettle();
    expect(find.text('帳號：demo'), findsOneWidget);
  });

  _profileTest('編輯暱稱只送有改的欄位，回到會員頁顯示新資料', (tester, backend) async {
    await _pumpProfile(tester);
    await tester.tap(find.text('編輯'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfilePage), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '小美'), '阿美');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(backend.patches, [
      {'nickname': '阿美'},
    ]);
    expect(find.byType(EditProfilePage), findsNothing);
    expect(find.text('阿美'), findsWidgets);
    expect(find.text('資料已更新'), findsOneWidget);
  });

  _profileTest('沒改任何欄位按儲存，不送請求直接返回', (tester, backend) async {
    await _pumpProfile(tester);
    await tester.tap(find.text('編輯'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(backend.patches, isEmpty);
    expect(find.byType(EditProfilePage), findsNothing);
  });

  _profileTest('暱稱清空、電話格式錯時前端先擋下', (tester, backend) async {
    await _pumpProfile(tester);
    await tester.tap(find.text('編輯'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '小美'), '');
    await tester.enterText(
      find.widgetWithText(TextField, '例如：0912345678'),
      'abc',
    );
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(backend.patches, isEmpty);
    expect(find.text('請輸入暱稱'), findsOneWidget);
    expect(find.text('請輸入正確的電話號碼'), findsOneWidget);
  });

  _profileTest('清空緊急聯絡人時送 null', (tester, backend) async {
    backend.current['emergency_contact_name'] = '王小明';
    await _pumpProfile(tester);
    await tester.tap(find.text('編輯'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '王小明'), '');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(backend.patches, [
      {'emergency_contact_name': null},
    ]);
  });

  _profileTest('後端欄位錯誤顯示在該欄位下方，停留在編輯頁', (tester, backend) async {
    backend.patchResponse = (
      400,
      {
        'success': false,
        'data': null,
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': '資料格式有誤，請再檢查一下',
          'fields': {
            'nickname': ['暱稱太長了'],
          },
        },
      },
    );
    await _pumpProfile(tester);
    await tester.tap(find.text('編輯'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '小美'), '很長的暱稱');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfilePage), findsOneWidget);
    expect(find.text('暱稱太長了'), findsOneWidget);
  });

  _profileTest('登出：確認後清掉 token 並回到登入頁', (tester, backend) async {
    await _pumpProfile(tester);
    await tester.tap(find.text('登出'));
    await tester.pumpAndSettle();
    expect(find.text('確定要登出目前的帳號嗎？'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '登出'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('access_token'), isNull);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  group('頭像', () {
    late Directory tempDir;
    late String photoPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('avatar_test');
      AvatarStorage.baseDirectory = () async => tempDir;
      photoPath = '${tempDir.path}${Platform.pathSeparator}picked.png';
      await File(photoPath).writeAsBytes(base64Decode(_pngBase64));
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    List<FileSystemEntity> savedAvatars() {
      final dir = Directory('${tempDir.path}${Platform.pathSeparator}avatars');
      return dir.existsSync() ? dir.listSync() : [];
    }

    _profileTest('沒設定頭像：顯示預設圖示，選單沒有「移除頭像」', (tester, backend) async {
      ImagePickerPlatform.instance = _FakeImagePicker(photoPath);
      await _pumpProfile(tester);
      await _settleIO(tester);

      expect(_avatarImage, findsNothing);
      await tester.tap(_avatarButton);
      await tester.pumpAndSettle();
      expect(find.text('從相簿選擇'), findsOneWidget);
      expect(find.text('拍照'), findsOneWidget);
      expect(find.text('移除頭像'), findsNothing);
    });

    _profileTest('從相簿選照片：存成頭像並顯示，再移除就回到預設圖示', (tester, backend) async {
      final picker = _FakeImagePicker(photoPath);
      ImagePickerPlatform.instance = picker;
      await _pumpProfile(tester);
      await _settleIO(tester);

      await tester.tap(_avatarButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('從相簿選擇'));
      await _settleIO(tester);

      expect(picker.lastSource, ImageSource.gallery);
      expect(savedAvatars(), hasLength(1));
      expect(_avatarImage, findsOneWidget);

      await tester.tap(_avatarButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('移除頭像'));
      await _settleIO(tester);

      expect(savedAvatars(), isEmpty);
      expect(_avatarImage, findsNothing);
    });

    _profileTest('換新頭像會刪掉舊檔，重新進來還看得到', (tester, backend) async {
      final picker = _FakeImagePicker(photoPath);
      ImagePickerPlatform.instance = picker;
      await _pumpProfile(tester);
      await _settleIO(tester);

      for (final option in ['從相簿選擇', '拍照']) {
        await tester.tap(_avatarButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text(option));
        await _settleIO(tester);
      }
      expect(picker.lastSource, ImageSource.camera);
      expect(savedAvatars(), hasLength(1));

      // 重新建立會員頁（例如重開 App），頭像從手機裡讀回來
      await tester.pumpWidget(const SizedBox());
      await _pumpProfile(tester);
      await _settleIO(tester);
      expect(_avatarImage, findsOneWidget);
    });

    _profileTest('沒有相機／相簿權限：顯示提示，不會壞掉', (tester, backend) async {
      ImagePickerPlatform.instance = _FakeImagePicker(
        photoPath,
        error: Exception('photo_access_denied'),
      );
      await _pumpProfile(tester);
      await _settleIO(tester);

      await tester.tap(_avatarButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('從相簿選擇'));
      await _settleIO(tester);

      expect(find.textContaining('請到手機的「設定」允許使用'), findsOneWidget);
      expect(savedAvatars(), isEmpty);
    });
  });

  _profileTest('登出：按取消就留在會員頁', (tester, backend) async {
    await _pumpProfile(tester);
    await tester.tap(find.text('登出'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('access_token'), 'test');
    expect(find.byType(ProfilePage), findsOneWidget);
  });
}
