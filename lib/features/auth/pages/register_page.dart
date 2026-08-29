import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime? _selectedBirthDate;
  String _selectedGender = 'male';
  String? _selectedRegion;

  final List<String> _interestOptions = [
    '健康講座', '運動健身', '藝術創作', '數位學習',
    '音樂表演', '旅遊戶外', '語言學習', '心靈成長', '志工服務',
  ];
  final Set<String> _selectedInterests = {};

  final List<String> _familyMembers = []; // 之後可放家屬姓名，先用字串代表已新增的項目

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1955, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8F3),
        elevation: 0,
        title: const Text('建立帳號', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
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

            const SizedBox(height: 32),
            _sectionTitle('選填資料'),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('填寫後可獲得更個人化的體驗', style: TextStyle(fontSize: 13, color: Colors.black45)),
            ),
            const SizedBox(height: 18),

            _label('所在地區'),
            const SizedBox(height: 8),
            _regionDropdown(),
            const SizedBox(height: 20),

            _label('興趣喜好'),
            const SizedBox(height: 10),
            _interestChips(),
            const SizedBox(height: 20),

            _label('家屬聯絡人'),
            const SizedBox(height: 10),
            _addFamilyButton(),
            const SizedBox(height: 6),
            const Center(
              child: Text('可綁定多位家屬帳號', style: TextStyle(fontSize: 12, color: Colors.black45, decoration: TextDecoration.underline)),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B8A6B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  // TODO: 呼叫註冊 API（興趣喜好、家屬聯絡人暫不送出，待後端補齊欄位）
                },
                child: const Text(
                  '完成註冊',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 共用小元件 ----------

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: const Color(0xFF5B8A6B)),
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

  Widget _textField(TextEditingController controller, String hint, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
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

  Widget _dateField() {
    return InkWell(
      onTap: _pickBirthDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedBirthDate == null
                  ? '年 / 月 / 日'
                  : '${_selectedBirthDate!.year} / ${_selectedBirthDate!.month} / ${_selectedBirthDate!.day}',
              style: TextStyle(color: _selectedBirthDate == null ? Colors.black38 : Colors.black87),
            ),
            const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black45),
          ],
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
          color: isSelected ? const Color(0xFF5B8A6B) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? const Color(0xFF5B8A6B) : const Color(0xFFE0E0E0)),
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

  Widget _regionDropdown() {
    const regions = ['north', 'central', 'south'];
    const regionLabels = {'north': '北部', 'central': '中部', 'south': '南部'};

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
          value: _selectedRegion,
          hint: const Text('請選擇您的所在地區', style: TextStyle(color: Colors.black38)),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: regions.map((r) {
            return DropdownMenuItem(value: r, child: Text(regionLabels[r]!));
          }).toList(),
          onChanged: (value) => setState(() => _selectedRegion = value),
        ),
      ),
    );
  }

  Widget _interestChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _interestOptions.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedInterests.remove(interest);
              } else {
                _selectedInterests.add(interest);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF5B8A6B) : const Color(0xFFDCE8DC),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              interest,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF3D6B4A),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _addFamilyButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        // TODO: 開啟新增家屬帳號的表單（待後端 API 確認格式）
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF5B8A6B), width: 1.2, style: BorderStyle.solid),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Color(0xFF5B8A6B), size: 18),
              SizedBox(width: 6),
              Text('新增家屬帳號', style: TextStyle(color: Color(0xFF5B8A6B), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}