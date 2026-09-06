
每個模組固定三層：`pages`（頁面）／`widgets`（該模組專用元件）／`services`（API 呼叫）。

---

## 模組說明

| 模組 | 說明 |
|------|------|
| `auth` | 身分選擇（長者／家屬模式）、註冊登入、AD-8 篩檢量表、新手教學 |
| `home` | 首頁：問候語、每日建議、大腦訓練遊戲入口、動態牆 |
| `game` | 六大認知類別小遊戲（注意力、執行功能、語言、工作記憶、數學、視覺空間），皆以「菜市場」為主題情境，依表現動態調整難度 |
| `diary` | 聲影日記：拍照 + 語音描述，AI 追問延伸，可選擇分享至動態牆 |
| `dashboard` | 健康儀表板：腦年齡估算、六大認知雷達圖、週/月報表；家屬端另提供趨勢折線圖與正確率分析 |
| `info` | 資訊加油站：活動、機構、衛教資訊，依興趣與地區個人化推薦 |
| `assistant` | AI 小助手：以對話介面貫穿全系統，語氣溫和、不主動提及疾病風險 |

---

## 環境需求

| 項目 | 版本 / 說明 |
|------|------------|
| Flutter SDK | 3.x 以上 |
| 編輯器 | VS Code（Flutter、Dart 擴充套件）或 Android Studio |
| Git | 版本控制 |

```bash
flutter --version
flutter doctor
```

> 目前開發環境尚未配置 Android SDK，暫以 Chrome 瀏覽器測試，`flutter doctor` 顯示 Android toolchain 相關錯誤屬預期狀況。

---

## 快速開始

```bash
git clone https://github.com/LightMemory-Team/LightMemory-frontend.git
cd LightMemory-frontend
flutter pub get
flutter run -d chrome
```

停止執行請在終端機按 `q`。

---

## 開發規範

1. **畫面不直接呼叫 API**，一律透過 `services`
2. **顏色與字級使用 `core/theme` 定義**，不寫死數值
3. **檔案命名小寫加底線**（`home_page.dart`），類別名稱用大駝峰（`HomePage`）
4. **只修改自己負責的模組**；要改 `core/` 或 `shared/` 請先在群組告知
5. **長者介面**：字級 18pt 以上、按鈕點擊區域加大、避免低對比灰色文字、避免「錯誤」「失敗」等負面字樣

---

## 分支規則

| 分支 | 用途 |
|------|------|
| `main` | 穩定版本，僅透過 PR 合併 |
| `dev` | 開發主線 |
| `feature/xxx` | 個人功能分支 |

```bash
git checkout dev
git pull
git checkout -b feature/xxx
# 開發完成後
git add .
git commit -m "新增 xxx 功能"
git push -u origin feature/xxx
# 到 GitHub 開 PR 回 dev，經 review approve 後合併
```

PR 需至少 1 人 review 通過才能合併進 `dev`。

---

## 目前開發進度

### 已完成

- [x] 專案架構建置（core / shared / features）
- [x] `core/theme`、`core/constants` 建立
- [x] 身分選擇、登入、註冊、歡迎頁面
- [x] 首頁（問候語、每日建議卡片、遊戲卡片、動態牆、底部導覽列）
- [x] 遊戲首頁介面（今日進度卡、六大認知領域卡片、任務按鈕）
- [x] 新手教學功能（引導頁、教學狀態判斷）
- [x] 登入註冊串接後端 API（已完整測試：註冊 → 登入 → 進入首頁流程可正常運作）

### 進行中

- [ ] 首頁資料串接（問候語姓名、動態牆貼文等改為真實資料，目前為假資料）
- [ ] 後端正式部署固定網域（目前用 Cloudflare Tunnel 臨時網址測試，網址會變動）

### 待進行

- [ ] 聲影日記、健康儀表板、資訊加油站、AI 小助手頁面
- [ ] Android SDK 環境配置、實機測試