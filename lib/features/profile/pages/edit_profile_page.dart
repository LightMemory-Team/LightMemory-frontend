import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../core/network/auth_headers.dart';
import '../../../core/services/token_storage.dart';
import '../../auth/pages/auth_gate.dart';
import '../../dashboard/widgets/dashboard_palette.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

/// 編輯會員資料。儲存成功後 pop 回新的 [UserProfile]，沒改就直接返回
class EditProfilePage extends StatefulWidget {
  final UserProfile profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ProfileService _service = ProfileService();
  late final TextEditingController _nicknameController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  DateTime? _birthDate;
  String? _gender;
  String? _region;

  bool _isSaving = false;

  // 各欄位的錯誤訊息（前端檢查＋後端回傳的都放這裡）
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nicknameController = TextEditingController(text: p.nickname);
    _contactNameController = TextEditingController(
      text: p.emergencyContactName ?? '',
    );
    _contactPhoneController = TextEditingController(
      text: p.emergencyContactPhone ?? '',
    );
    _birthDate = p.birthDate;
    // 不認得的代碼（例如後端沒擋的其他值）當作沒選
    _gender = kGenderLabels.containsKey(p.gender) ? p.gender : null;
    _region = kRegionLabels.containsKey(p.region) ? p.region : null;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  /// 跟原本的資料比，只挑有改的欄位送出
  Map<String, dynamic> _collectChanges() {
    final p = widget.profile;
    final changes = <String, dynamic>{};
    final nickname = _nicknameController.text.trim();
    if (nickname != p.nickname) changes['nickname'] = nickname;
    if (_birthDate != p.birthDate && _birthDate != null) {
      changes['birth_date'] = formatApiDate(_birthDate!);
    }
    if (_gender != null && _gender != p.gender) changes['gender'] = _gender;
    if (_region != null && _region != p.region) changes['region'] = _region;
    final contactName = _contactNameController.text.trim();
    if (contactName != (p.emergencyContactName ?? '')) {
      changes['emergency_contact_name'] = contactName.isEmpty
          ? null
          : contactName;
    }
    final contactPhone = _contactPhoneController.text.trim();
    if (contactPhone != (p.emergencyContactPhone ?? '')) {
      changes['emergency_contact_phone'] = contactPhone.isEmpty
          ? null
          : contactPhone;
    }
    return changes;
  }

  /// 前端先擋明顯的錯，後端目前沒檢查電話格式
  Map<String, String> _validate() {
    final errors = <String, String>{};
    if (_nicknameController.text.trim().isEmpty) {
      errors['nickname'] = '請輸入暱稱';
    }
    final phone = _contactPhoneController.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^\+?[0-9\- ]{8,15}$').hasMatch(phone)) {
      errors['emergency_contact_phone'] = '請輸入正確的電話號碼';
    }
    return errors;
  }

  Future<void> _save() async {
    final errors = _validate();
    setState(() => _fieldErrors = errors);
    if (errors.isNotEmpty) return;

    final changes = _collectChanges();
    if (changes.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await _service.updateMe(changes);
      if (!mounted) return;
      Navigator.pop(context, updated);
    } on NotLoggedInException {
      await TokenStorage.clear();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } on ProfileValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _fieldErrors = {
          for (final entry in e.fields.entries)
            if (entry.value.isNotEmpty) entry.key: entry.value.first,
        };
      });
      _showMessage(e.message);
    } catch (e) {
      debugPrint('會員資料儲存失敗：$e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('資料暫時無法儲存，請稍後再試一次');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: TextStyle(fontSize: AppSettings.scaleFont(16)),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 65),
      firstDate: DateTime(1900),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: '選擇生日',
      cancelText: '取消',
      confirmText: '確定',
    );
    if (picked != null) setState(() => _birthDate = picked);
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
        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: palette.card,
            elevation: 0.5,
            centerTitle: true,
            leading: IconButton(
              tooltip: '返回',
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: palette.primary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '編輯資料',
              style: TextStyle(
                color: palette.primary,
                fontWeight: FontWeight.bold,
                fontSize: AppSettings.scaleFont(20),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _label('帳號', palette),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 20),
                child: Text(
                  '${widget.profile.username}（帳號無法修改）',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(17),
                    color: palette.body,
                  ),
                ),
              ),
              _label('暱稱', palette),
              _textField(
                controller: _nicknameController,
                hint: '大家怎麼稱呼您',
                errorText: _fieldErrors['nickname'],
                palette: palette,
              ),
              _label('生日', palette),
              _birthDateField(palette),
              _label('性別', palette),
              Row(
                children: [
                  for (final (i, entry) in kGenderLabels.entries.indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _choiceButton(
                        label: entry.value,
                        selected: _gender == entry.key,
                        onTap: () => setState(() => _gender = entry.key),
                        palette: palette,
                      ),
                    ),
                  ],
                ],
              ),
              _errorLine(_fieldErrors['gender'], palette),
              const SizedBox(height: 20),
              _label('地區', palette),
              _regionDropdown(palette),
              _errorLine(_fieldErrors['region'], palette),
              const SizedBox(height: 20),
              _label('緊急聯絡人姓名', palette),
              _textField(
                controller: _contactNameController,
                hint: '例如：王小明',
                errorText: _fieldErrors['emergency_contact_name'],
                palette: palette,
              ),
              _label('緊急聯絡人電話', palette),
              _textField(
                controller: _contactPhoneController,
                hint: '例如：0912345678',
                errorText: _fieldErrors['emergency_contact_phone'],
                keyboardType: TextInputType.phone,
                palette: palette,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          '儲存',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(19),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text, DashboardPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppSettings.scaleFont(17),
          fontWeight: FontWeight.bold,
          color: palette.title,
        ),
      ),
    );
  }

  Widget _errorLine(String? text, DashboardPalette palette) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppSettings.scaleFont(15),
          color: palette.isDark
              ? const Color(0xFFEF9A9A)
              : const Color(0xFFC62828),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.2}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required String? errorText,
    required DashboardPalette palette,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: AppSettings.scaleFont(18),
          color: palette.title,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: palette.body.withValues(alpha: 0.7)),
          errorText: errorText,
          errorStyle: TextStyle(fontSize: AppSettings.scaleFont(15)),
          filled: true,
          fillColor: palette.card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: _border(
            palette.isHighContrast ? palette.title : palette.grid,
          ),
          focusedBorder: _border(palette.primary, width: 2),
          errorBorder: _border(const Color(0xFFC62828)),
          focusedErrorBorder: _border(const Color(0xFFC62828), width: 2),
        ),
      ),
    );
  }

  Widget _birthDateField(DashboardPalette palette) {
    final birth = _birthDate;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _pickBirthDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: palette.isHighContrast ? palette.title : palette.grid,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      birth == null
                          ? '請選擇生日'
                          : '${birth.year} 年 ${birth.month} 月 ${birth.day} 日',
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(18),
                        color: birth == null
                            ? palette.body.withValues(alpha: 0.7)
                            : palette.title,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined, color: palette.primary),
                ],
              ),
            ),
          ),
          _errorLine(_fieldErrors['birth_date'], palette),
        ],
      ),
    );
  }

  Widget _choiceButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required DashboardPalette palette,
  }) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.primary : palette.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected
                  ? palette.primary
                  : (palette.isHighContrast ? palette.title : palette.grid),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(18),
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : palette.title,
            ),
          ),
        ),
      ),
    );
  }

  Widget _regionDropdown(DashboardPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: palette.isHighContrast ? palette.title : palette.grid,
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _region,
          dropdownColor: palette.card,
          iconEnabledColor: palette.primary,
          hint: Text(
            '請選擇您的所在地區',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(18),
              color: palette.body.withValues(alpha: 0.7),
            ),
          ),
          style: TextStyle(
            fontSize: AppSettings.scaleFont(18),
            color: palette.title,
          ),
          items: [
            for (final entry in kRegionLabels.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (value) => setState(() => _region = value),
        ),
      ),
    );
  }
}
