import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../../../core/network/error_message.dart';
import 'login_page.dart';
import 'welcome_page.dart';

/// 註冊頁：拆成三個步驟
///
/// 第 1 步：帳號、密碼（必填）
/// 第 2 步：暱稱、生日、性別（必填）
/// 第 3 步：所在地區、緊急聯絡人（選填；都沒填按鈕顯示「略過」，有填顯示「完成註冊」）
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color _green = Color(0xFF5B8A6B);
  static const Color _bg = Color(0xFFF6F8F3);
  static const int _totalSteps = 3;

  /// 目前在第幾步（0、1、2）
  int _step = 0;

  // 第 1 步
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // 第 2 步
  final _nicknameController = TextEditingController();
  int? _birthYear;
  int? _birthMonth;
  int? _birthDay;
  String? _selectedGender; // 不預設，要使用者自己選

  /// 年、月、日都選了才組成生日
  DateTime? get _selectedBirthDate {
    if (_birthYear == null || _birthMonth == null || _birthDay == null) {
      return null;
    }
    return DateTime(_birthYear!, _birthMonth!, _birthDay!);
  }

  /// 這個月有幾天（還沒選年或月時當成 31 天）
  int get _daysInSelectedMonth {
    if (_birthYear == null || _birthMonth == null) return 31;
    return DateTime(_birthYear!, _birthMonth! + 1, 0).day;
  }

  /// 換了年或月之後，原本選的日如果超過那個月的天數（例如 2 月 30 日），就清掉重選
  void _fixBirthDay() {
    if (_birthDay != null && _birthDay! > _daysInSelectedMonth) {
      _birthDay = null;
    }
  }

  // 第 3 步
  String? _selectedCounty;
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  bool _isSubmitting = false;

  // ============================================================
  // 縣市選單（依北到南分區，區域只是小標題不能選）
  // ============================================================

  static const Map<String, List<String>> _countiesByArea = {
    '北部': ['臺北市', '新北市', '基隆市', '桃園市', '新竹市', '新竹縣', '宜蘭縣'],
    '中部': ['苗栗縣', '臺中市', '彰化縣', '南投縣', '雲林縣'],
    '南部': ['嘉義市', '嘉義縣', '臺南市', '高雄市', '屏東縣'],
    '東部': ['花蓮縣', '臺東縣'],
    '離島': ['澎湖縣', '金門縣', '連江縣'],
  };

  /// 後端目前的 region 只收 north／central／south。
  /// 暫時把縣市換算成這三個代碼送出；東部、離島先不送（回傳 null）。
  /// TODO：等小惠確認後端改成直接收縣市後，改成直接送 _selectedCounty。
  String? _regionCodeForBackend(String? county) {
    if (county == null) return null;
    if (_countiesByArea['北部']!.contains(county)) return 'north';
    if (_countiesByArea['中部']!.contains(county)) return 'central';
    if (_countiesByArea['南部']!.contains(county)) return 'south';
    return null;
  }

  @override
  void initState() {
    super.initState();
    // 輸入框內容改變時重畫，讓「下一步」按鈕即時變成可按／不可按
    for (final c in [
      _usernameController,
      _passwordController,
      _nicknameController,
      _contactNameController,
      _contactPhoneController,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // 各步驟是否填完
  // ============================================================

  bool get _step1Done =>
      _usernameController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  bool get _step2Done =>
      _nicknameController.text.trim().isNotEmpty &&
      _selectedBirthDate != null &&
      _selectedGender != null;

  /// 第 3 步有沒有填任何一欄（決定按鈕顯示「略過」或「完成註冊」）
  bool get _step3HasAnyInput =>
      _selectedCounty != null ||
      _contactNameController.text.trim().isNotEmpty ||
      _contactPhoneController.text.trim().isNotEmpty;

  // ============================================================
  // 換頁
  // ============================================================

  void _goNext() {
    FocusScope.of(context).unfocus();
    setState(() => _step++);
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  // 把 DateTime 轉成 "1950-01-01" 這種格式，並補 0
  String _formatBirthDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  // ============================================================
  // 送出註冊（第 3 步的「略過」和「完成註冊」都走這裡）
  // ============================================================

  Future<void> _handleRegister() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final nickname = _nicknameController.text.trim();

    try {
      await AuthService.register(
        username: username,
        password: password,
        birthDate: _formatBirthDate(_selectedBirthDate!),
        gender: _selectedGender!,
        region: _regionCodeForBackend(_selectedCounty),
        // TODO：暱稱（nickname）、緊急聯絡人（姓名、電話）後端註冊 API 目前沒有欄位，
        // 等小惠加好後再送出。
      );

      // 註冊成功後直接幫使用者登入並存 token。
      try {
        await AuthService.loginAndSaveToken(
          username: username,
          password: password,
        );
      } catch (e) {
        // 帳號已經建好了，只是自動登入沒成功：請使用者到登入頁自己登入一次
        debugPrint('[RegisterPage] 註冊後自動登入失敗: $e');
        if (!mounted) return;
        _showMessage('註冊成功！請用剛才的帳號密碼登入');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return;
      }

      if (!mounted) return;

      // 註冊並登入成功，導向歡迎頁（顯示暱稱）
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomePage(userName: nickname, isNewUser: true),
        ),
      );
    } catch (e) {
      debugPrint('[RegisterPage] 註冊例外: $e');
      if (!mounted) return;
      _showMessage(friendlyErrorMessage(e, fallback: '註冊失敗，請稍後再試一次'));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // 手機返回鍵：不在第 1 步時回上一步，不直接離開註冊頁
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
                    centerTitle: true,
          automaticallyImplyLeading: false,
          // 第 1 步左上角用文字「返回」（不用箭頭），離開註冊頁；
          // 第 2、3 步改用下方的「上一步」按鈕
          leadingWidth: 88,
          leading: _step == 0
              ? TextButton(
                  onPressed: _isSubmitting ? null : _goBack,
                  style: TextButton.styleFrom(foregroundColor: _green),
                  child: const Text(
                    '返回',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          title: const Text(
            '建立帳號',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildProgress(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: _buildStepContent(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _buildBottomButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 上方進度：「第 1 步，共 3 步」＋三段進度條
  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '第 ${_step + 1} 步，共 $_totalSteps 步',
            style: const TextStyle(
              fontSize: 14,
              color: _green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_totalSteps, (index) {
              final reached = index <= _step;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: reached ? _green : const Color(0xFFDCE8DC),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      default:
        return _buildStep3();
    }
  }

  // ---------- 第 1 步：帳號、密碼 ----------

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('必填資料'),
        const SizedBox(height: 18),
        _label('帳號', required: true),
        const SizedBox(height: 8),
        _textField(_usernameController, '建議使用電話或電子郵件'),
        const SizedBox(height: 20),
        _label('密碼', required: true),
        const SizedBox(height: 8),
        _textField(_passwordController, '請設定密碼', obscure: true),
      ],
    );
  }

  // ---------- 第 2 步：暱稱、生日、性別 ----------

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('必填資料'),
        const SizedBox(height: 18),
        _label('暱稱', required: true),
        const SizedBox(height: 8),
        _textField(
          _nicknameController,
          '我們要怎麼稱呼您？例如：玉蘭',
          maxLength: 10,
        ),
        const SizedBox(height: 20),
        _label('生日', required: true),
        const SizedBox(height: 8),
        _dateField(),
        const SizedBox(height: 20),
        _label('性別', required: true),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _genderButton('男', 'male')),
            const SizedBox(width: 12),
            Expanded(child: _genderButton('女', 'female')),
          ],
        ),
      ],
    );
  }

  // ---------- 第 3 步：所在地區、緊急聯絡人 ----------

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('選填資料'),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            '可以先略過，之後再補填',
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
        ),
        const SizedBox(height: 18),
        _label('所在地區'),
        const SizedBox(height: 8),
        _countyDropdown(),
        const SizedBox(height: 24),
        _label('緊急聯絡人'),
        const SizedBox(height: 8),
        _textField(_contactNameController, '聯絡人姓名', maxLength: 20),
        const SizedBox(height: 12),
        _textField(
          _contactPhoneController,
          '聯絡人電話',
          keyboardType: TextInputType.phone,
          digitsOnly: true,
          maxLength: 10,
        ),
      ],
    );
  }

    // ---------- 下方按鈕 ----------
  // 第 1 步：只有「下一步」
  // 第 2、3 步：左「上一步」、右「下一步／略過／完成註冊」

  Widget _buildBottomButton() {
    final bool isLastStep = _step == _totalSteps - 1;

    final String nextLabel;
    final bool nextEnabled;

    if (_step == 0) {
      nextLabel = '下一步';
      nextEnabled = _step1Done;
    } else if (_step == 1) {
      nextLabel = '下一步';
      nextEnabled = _step2Done;
    } else {
      // 第 3 步：都沒填顯示「略過」，有填任何一欄顯示「完成註冊」
      nextLabel = _step3HasAnyInput ? '完成註冊' : '略過';
      nextEnabled = true;
    }

    final Widget nextButton = SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          disabledBackgroundColor: const Color(0xFFC9D6CC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: (!nextEnabled || _isSubmitting)
            ? null
            : (isLastStep ? _handleRegister : _goNext),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                nextLabel,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );

    // 第 1 步：只有「下一步」，返回在左上角
    if (_step == 0) {
      return SizedBox(width: double.infinity, child: nextButton);
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                backgroundColor: Colors.white,
                side: const BorderSide(color: _green, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _isSubmitting ? null : _goBack,
              child: const Text(
                '上一步',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: nextButton),
      ],
    );
  }

  // ============================================================
  // 共用小元件
  // ============================================================

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: _green),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
        children: [
          TextSpan(text: text),
          if (required) const TextSpan(text: ' *', style: TextStyle(color: Colors.redAccent)),
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    int? maxLength,
    TextInputType? keyboardType,
    bool digitsOnly = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
    );
  }

  /// 生日：年、月、日三個下拉選單（中文，長輩直接選年份，不用一直翻日曆）
  Widget _dateField() {
    final int thisYear = DateTime.now().year;
    final years = [for (int y = 1920; y <= thisYear; y++) y];
    final months = [for (int m = 1; m <= 12; m++) m];
    final days = [for (int d = 1; d <= _daysInSelectedMonth; d++) d];

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _numberDropdown(
            value: _birthYear,
            hint: '年',
            unit: '年',
            options: years,
            onChanged: (v) => setState(() {
              _birthYear = v;
              _fixBirthDay();
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _numberDropdown(
            value: _birthMonth,
            hint: '月',
            unit: '月',
            options: months,
            onChanged: (v) => setState(() {
              _birthMonth = v;
              _fixBirthDay();
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _numberDropdown(
            value: _birthDay,
            hint: '日',
            unit: '日',
            options: days,
            onChanged: (v) => setState(() => _birthDay = v),
          ),
        ),
      ],
    );
  }

  Widget _numberDropdown({
    required int? value,
    required String hint,
    required String unit,
    required List<int> options,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.black38)),
          icon: const Icon(Icons.keyboard_arrow_down),
          menuMaxHeight: 360,
          items: options
              .map((n) => DropdownMenuItem<int>(value: n, child: Text('$n $unit')))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _genderButton(String label, String value) {
    final isSelected = _selectedGender == value;
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _green : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? _green : const Color(0xFFE0E0E0)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  /// 縣市下拉選單：區域當小標題（不能選），底下列縣市
  Widget _countyDropdown() {
    final List<DropdownMenuItem<String>> items = [];

    _countiesByArea.forEach((area, counties) {
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          value: '__$area',
          child: Text(
            area,
            style: const TextStyle(
              color: _green,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
      for (final county in counties) {
        items.add(
          DropdownMenuItem<String>(
            value: county,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(county),
            ),
          ),
        );
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCounty,
          hint: const Text('請選擇您的所在縣市', style: TextStyle(color: Colors.black38)),
          icon: const Icon(Icons.keyboard_arrow_down),
          menuMaxHeight: 400,
          items: items,
          // 選到的縣市在按鈕上不要縮排
          selectedItemBuilder: (context) => items.map((item) {
            final value = item.value ?? '';
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(value.startsWith('__') ? '' : value),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCounty = value),
        ),
      ),
    );
  }
}