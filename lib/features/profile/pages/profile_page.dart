import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app_settings.dart';
import '../../../core/network/auth_headers.dart';
import '../../../core/services/token_storage.dart';
import '../../../screens/main_screen.dart';
import '../../../screens/notification_screen.dart';
import '../../../screens/settings_screen.dart';
import '../../auth/pages/auth_gate.dart';
import '../../auth/services/logout_helper.dart';
import '../../dashboard/pages/weekly_report_page.dart';
import '../../dashboard/widgets/dashboard_palette.dart';
import '../models/user_profile.dart';
import '../models/user_stats.dart';
import '../services/avatar_storage.dart';
import '../services/profile_service.dart';
import 'edit_profile_page.dart';
import '../../rewards/pages/achievements_page.dart';

/// 點頭像跳出的選單
enum _AvatarAction { gallery, camera, remove }

/// 底部導覽「會員」分頁：頭像、我的資料、快速入口、登出。
/// 會員資料讀不到時，快速入口和登出照常可以用
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _service = ProfileService();
  final ImagePicker _picker = ImagePicker();
  UserProfile? _profile;
  UserStats? _stats; // 連續天數火苗；讀不到時是 null，不顯示卡片
  Uint8List? _avatar; // 頭像圖片內容，沒設定是 null
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    // 統計跟會員資料分開讀：統計失敗只是不顯示火苗，不影響其他區塊
    final statsFuture = _loadStats();
    try {
      final profile = await _service.getMe();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
      // 會員資料先顯示，頭像讀好再補上
      final avatar = await _loadAvatar(profile.username);
      if (!mounted) return;
      setState(() => _avatar = avatar);
    } on NotLoggedInException {
      // 沒登入或 token 無效：清掉 token，交給 AuthGate 走登入流程
      await TokenStorage.clear();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('會員資料讀取失敗：$e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
    await statsFuture;
  }

  /// 讀會員統計；失敗時保留上一次的結果（第一次失敗就不顯示火苗卡片）
  Future<void> _loadStats() async {
    try {
      final stats = await _service.getStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (e) {
      // 沒登入的情況交給 getMe 處理，這裡只記錄
      debugPrint('會員統計讀取失敗：$e');
    }
  }

  /// 頭像讀不到不影響會員資料，直接用預設圖示
  Future<Uint8List?> _loadAvatar(String username) async {
    try {
      return await AvatarStorage.load(username);
    } catch (e) {
      debugPrint('頭像讀取失敗：$e');
      return null;
    }
  }

  Future<void> _changeAvatar(UserProfile profile) async {
    final palette = DashboardPalette.current();
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      backgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Widget option(_AvatarAction value, IconData icon, String label) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 6,
            ),
            leading: Icon(icon, color: palette.primary, size: 28),
            title: Text(
              label,
              style: TextStyle(
                fontSize: AppSettings.scaleFont(18),
                fontWeight: FontWeight.bold,
                color: palette.title,
              ),
            ),
            onTap: () => Navigator.pop(sheetContext, value),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                option(
                  _AvatarAction.gallery,
                  Icons.photo_library_outlined,
                  '從相簿選擇',
                ),
                option(_AvatarAction.camera, Icons.photo_camera_outlined, '拍照'),
                if (_avatar != null)
                  option(_AvatarAction.remove, Icons.delete_outline, '移除頭像'),
              ],
            ),
          ),
        );
      },
    );
    if (action == null || !mounted) return;

    try {
      if (action == _AvatarAction.remove) {
        await AvatarStorage.remove(profile.username);
        if (!mounted) return;
        setState(() => _avatar = null);
        return;
      }
      // 頭像只顯示成小圓圈，先縮小再存，避免照片太大
      final picked = await _picker.pickImage(
        source: action == _AvatarAction.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      final saved = await AvatarStorage.save(profile.username, picked);
      if (!mounted) return;
      setState(() => _avatar = saved);
    } catch (e) {
      // 最常見的是使用者沒給相機／相簿權限
      debugPrint('更換頭像失敗：$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '沒辦法開啟相機或相簿，請到手機的「設定」允許使用後再試一次',
            style: TextStyle(fontSize: AppSettings.scaleFont(16)),
          ),
        ),
      );
    }
  }

  Future<void> _openEdit(UserProfile profile) async {
    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(profile: profile)),
    );
    if (updated == null || !mounted) return;
    setState(() => _profile = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '資料已更新',
          style: TextStyle(fontSize: AppSettings.scaleFont(16)),
        ),
      ),
    );
  }

  /// 重新進入首頁並從第一步播放新手導覽
  void _replayTutorial() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen(startTutorial: true)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final palette = DashboardPalette.current();
        final profile = _profile;

        // 紅色在深色底上調亮一點，維持足夠對比
        final Color logoutColor = palette.isDark
            ? const Color(0xFFEF5350)
            : const Color(0xFFC62828);

        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: palette.card,
            elevation: 0.5,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: Text(
              '會員',
              style: TextStyle(
                color: palette.primary,
                fontWeight: FontWeight.bold,
                fontSize: AppSettings.scaleFont(20),
              ),
            ),
          ),
          body: RefreshIndicator(
            color: palette.primary,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                _Header(
                  profile: profile,
                  avatar: _avatar,
                  palette: palette,
                  // 要有帳號才知道頭像存給誰，資料讀到之前不能換
                  onTapAvatar: profile == null
                      ? null
                      : () => _changeAvatar(profile),
                ),
                const SizedBox(height: 24),
                // 連續天數火苗（GET /api/users/me/stats/ 的 streak_days）
                if (_stats != null) ...[
                  _StreakCard(stats: _stats!, palette: palette),
                  const SizedBox(height: 20),
                ],
                if (profile != null)
                  _InfoCard(
                    profile: profile,
                    palette: palette,
                    onEdit: () => _openEdit(profile),
                  )
                else
                  _InfoPlaceholder(
                    isLoading: _isLoading,
                    onRetry: _load,
                    palette: palette,
                  ),
                const SizedBox(height: 20),
                _ShortcutCard(
                  palette: palette,
                  items: [
                    // 點數與成就系統規格：會員頁新增「我的成就與點數」入口
                    _Shortcut(
                      icon: Icons.military_tech_outlined,
                      label: '我的成就與點數',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AchievementsPage(),
                        ),
                      ),
                    ),
                    _Shortcut(
                      icon: Icons.event_note_rounded,
                      label: '我的週報表',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WeeklyReportPage(),
                        ),
                      ),
                    ),
                    _Shortcut(
                      icon: Icons.notifications_none_rounded,
                      label: '通知',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      ),
                    ),
                    _Shortcut(
                      icon: Icons.explore_outlined,
                      label: '重看新手導覽',
                      onTap: _replayTutorial,
                    ),
                    _Shortcut(
                      icon: Icons.settings_outlined,
                      label: '設定',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 登出按鈕：滿寬、加大，方便長輩點擊
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => LogoutHelper.confirmAndLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 24),
                    label: Text(
                      '登出',
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(18),
                        fontWeight: palette.isHighContrast
                            ? FontWeight.w900
                            : FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: logoutColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 頭像＋名稱：有暱稱時大字暱稱、小字帳號；資料還沒讀到時只有頭像。
/// 點頭像可以更換，右下角的相機小圖示提示可以點
class _Header extends StatelessWidget {
  final UserProfile? profile;
  final Uint8List? avatar;
  final DashboardPalette palette;
  final VoidCallback? onTapAvatar;

  const _Header({
    required this.profile,
    required this.avatar,
    required this.palette,
    required this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final defaultIcon = Icon(
      Icons.person_rounded,
      size: 56,
      color: palette.primary,
    );
    final bytes = avatar;

    return Column(
      children: [
        Semantics(
          button: onTapAvatar != null,
          label: '更換頭像',
          child: GestureDetector(
            onTap: onTapAvatar,
            child: SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: palette.soft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.primary,
                        width: palette.isHighContrast ? 3.0 : 2.0,
                      ),
                    ),
                    child: ClipOval(
                      child: bytes == null
                          ? defaultIcon
                          : Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                              // 檔案被清掉或壞掉時退回預設圖示
                              errorBuilder: (_, _, _) => defaultIcon,
                            ),
                    ),
                  ),
                  if (onTapAvatar != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: palette.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.card, width: 2),
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (p != null) ...[
          const SizedBox(height: 12),
          Text(
            p.displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(24),
              fontWeight: FontWeight.bold,
              color: palette.title,
            ),
          ),
          if (p.nickname.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '帳號：${p.username}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSettings.scaleFont(15),
                color: palette.body,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// 連續天數火苗卡片。
///
/// 點數規格的原則是「成就只算累積、不算連續」，所以火苗只是顯示：不綁成就、
/// 不發點數；中斷時（0 天）不寫負面字眼，改成鼓勵句
class _StreakCard extends StatelessWidget {
  final UserStats stats;
  final DashboardPalette palette;

  const _StreakCard({required this.stats, required this.palette});

  /// 連續幾天以上算「很棒」：火苗加大、換成橘紅色
  static const int _greatStreak = 7;

  @override
  Widget build(BuildContext context) {
    final days = stats.streakDays;
    final isLit = days > 0;
    final isGreat = days >= _greatStreak;

    final Color flameColor;
    if (!isLit) {
      flameColor = palette.isDark
          ? const Color(0xFF8A8A8A)
          : const Color(0xFF9E9E9E);
    } else if (isGreat) {
      flameColor = palette.isDark
          ? const Color(0xFFFF7043)
          : const Color(0xFFE64A19);
    } else {
      flameColor = palette.isDark
          ? const Color(0xFFFFA726)
          : const Color(0xFFF57C00);
    }

    final String title;
    final String subtitle;
    if (!isLit) {
      title = '今天點燃火苗吧！';
      subtitle = '玩一場遊戲或寫一篇日記，就能開始累積';
    } else if (isGreat) {
      title = '已連續 $days 天 🎉';
      subtitle = '太棒了，繼續保持！';
    } else {
      title = '已連續 $days 天';
      subtitle = '今天也來玩一場或寫篇日記，火苗就不會熄滅';
    }

    return Semantics(
      container: true,
      label: isLit ? '已連續 $days 天' : '今天點燃火苗吧',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        decoration: palette.cardDecoration(radius: 16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: flameColor.withValues(alpha: palette.isDark ? 0.18 : 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.local_fire_department_rounded,
                size: isGreat ? 52 : 44,
                color: flameColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(21),
                      fontWeight: FontWeight.bold,
                      color: palette.title,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(15),
                      color: palette.body,
                    ),
                  ),
                  if (stats.activeDayCount > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '累計活動 ${stats.activeDayCount} 天',
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(14),
                        color: palette.body,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 「我的資料」卡片，沒填的欄位顯示灰色「未填寫」
class _InfoCard extends StatelessWidget {
  final UserProfile profile;
  final DashboardPalette palette;
  final VoidCallback onEdit;

  const _InfoCard({
    required this.profile,
    required this.palette,
    required this.onEdit,
  });

  String? get _birthText {
    final birth = profile.birthDate;
    if (birth == null) return null;
    return '${birth.year}/${birth.month.toString().padLeft(2, '0')}/'
        '${birth.day.toString().padLeft(2, '0')}（${profile.age} 歲）';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('暱稱', profile.nickname.isEmpty ? null : profile.nickname),
      ('生日', _birthText),
      ('性別', profile.genderLabel),
      ('地區', profile.regionLabel),
      ('緊急聯絡人', profile.emergencyContactName),
      ('聯絡人電話', profile.emergencyContactPhone),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: palette.cardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '我的資料',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(19),
                    fontWeight: FontWeight.bold,
                    color: palette.title,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: palette.primary,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.edit_outlined, size: 22),
                label: Text(
                  '編輯',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(17),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4, right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: AppSettings.scaleFont(100),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(16),
                        color: palette.body,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value ?? '未填寫',
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(17),
                        fontWeight: value == null
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: value == null
                            ? palette.body.withValues(alpha: 0.75)
                            : palette.title,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 會員資料讀取中／讀不到時佔住「我的資料」的位置
class _InfoPlaceholder extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRetry;
  final DashboardPalette palette;

  const _InfoPlaceholder({
    required this.isLoading,
    required this.onRetry,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: palette.cardDecoration(radius: 16),
      child: isLoading
          ? Center(child: CircularProgressIndicator(color: palette.primary))
          : Column(
              children: [
                Text(
                  '會員資料暫時讀不到',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(17),
                    color: palette.title,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.primary,
                    side: BorderSide(color: palette.primary, width: 2),
                    minimumSize: const Size(140, 48),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    '再試一次',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(17),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Shortcut {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// 快速入口：一張卡片裡用分隔線排成清單
class _ShortcutCard extends StatelessWidget {
  final List<_Shortcut> items;
  final DashboardPalette palette;

  const _ShortcutCard({required this.items, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: palette.cardDecoration(radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (final (i, item) in items.indexed) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: palette.grid,
                ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: Icon(item.icon, color: palette.primary, size: 26),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(17),
                    fontWeight: palette.isHighContrast
                        ? FontWeight.w900
                        : FontWeight.bold,
                    color: palette.title,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: palette.primary,
                ),
                onTap: item.onTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
