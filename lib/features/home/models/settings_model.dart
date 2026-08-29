class SettingsModel {
  final int fontSizeLevel; // 1 ~ 5
  final bool isDarkMode;
  final bool isHighContrast;

  const SettingsModel({
    this.fontSizeLevel = 2, // 預設 2 為標準 100%
    this.isDarkMode = false,
    this.isHighContrast = false,
  });

  // 取得字體縮放倍率
  double get fontScaleFactor {
    switch (fontSizeLevel) {
      case 1:
        return 0.85;
      case 2:
        return 1.0;
      case 3:
        return 1.15;
      case 4:
        return 1.30;
      case 5:
        return 1.45;
      default:
        return 1.0;
    }
  }

  // 取得字體中文標籤
  String get fontSizeLabel {
    switch (fontSizeLevel) {
      case 1:
        return '小（85%）';
      case 2:
        return '標準（100%）';
      case 3:
        return '大（115%）';
      case 4:
        return '特大（130%）';
      case 5:
        return '超大（145%）';
      default:
        return '標準（100%）';
    }
  }

  // 複製並修改部分欄位 (常用於狀態更新)
  SettingsModel copyWith({
    int? fontSizeLevel,
    bool? isDarkMode,
    bool? isHighContrast,
  }) {
    return SettingsModel(
      fontSizeLevel: fontSizeLevel ?? this.fontSizeLevel,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isHighContrast: isHighContrast ?? this.isHighContrast,
    );
  }

  // 未來串接 API 或本機儲存用 (JSON 序列化)
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      fontSizeLevel: json['font_size_level'] as int? ?? 2,
      isDarkMode: json['is_dark_mode'] as bool? ?? false,
      isHighContrast: json['is_high_contrast'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'font_size_level': fontSizeLevel,
      'is_dark_mode': isDarkMode,
      'is_high_contrast': isHighContrast,
    };
  }
}
