// 會員資料，對應後端 GET／PATCH /api/users/me/

/// 性別代碼對照，跟註冊頁一致
const Map<String, String> kGenderLabels = {'male': '男', 'female': '女'};

/// 地區代碼對照，跟註冊頁一致
const Map<String, String> kRegionLabels = {
  'north': '北部',
  'central': '中部',
  'south': '南部',
};

class UserProfile {
  final String username; // 帳號，不能修改
  final String nickname;
  final DateTime? birthDate;
  final String gender; // male／female，沒填是空字串
  final String? region; // north／central／south，沒填是 null
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const UserProfile({
    required this.username,
    required this.nickname,
    required this.birthDate,
    required this.gender,
    required this.region,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  /// 頭像區的大字：有暱稱用暱稱，沒有就用帳號
  String get displayName => nickname.isNotEmpty ? nickname : username;

  /// 後端目前沒擋其他值，不認得的代碼就當作沒填
  String? get genderLabel => kGenderLabels[gender];
  String? get regionLabel => kRegionLabels[region];

  int? get age {
    final birth = birthDate;
    if (birth == null) return null;
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final birth = json['birth_date'] as String?;
    return UserProfile(
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      birthDate: birth == null ? null : DateTime.tryParse(birth),
      gender: json['gender'] as String? ?? '',
      region: json['region'] as String?,
      emergencyContactName: _blankToNull(json['emergency_contact_name']),
      emergencyContactPhone: _blankToNull(json['emergency_contact_phone']),
    );
  }

  static String? _blankToNull(Object? value) {
    final text = value as String?;
    return (text == null || text.isEmpty) ? null : text;
  }
}

/// 生日送給後端的格式：yyyy-MM-dd
String formatApiDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
