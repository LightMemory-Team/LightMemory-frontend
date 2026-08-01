# LightMemory 憶智防線（前端）

延緩失智手機 App — Flutter 前端專案

## 專案簡介

以長者為主要使用對象，透過遊戲化認知訓練、聲影日記與健康追蹤，
協助預防及延緩失智，並讓家屬掌握長者認知變化。

## 技術架構

本專案為**前後端分離**架構：

| 層級 | 技術 |
|------|------|
| 前端 | Flutter (Dart) — 本專案 |
| 後端 | Python Django + REST API |
| 資料庫 | PostgreSQL |
| 檔案儲存 | Firebase Storage |

前端不直接接觸資料庫，所有資料皆透過 REST API 與後端溝通。

## 環境需求

- Flutter SDK 3.x 以上
- VS Code 或 Android Studio（需安裝 Flutter、Dart 擴充套件）

## 如何啟動

```bash
# 1. 下載專案
git clone https://github.com/你的帳號/lightmemory-frontend.git
cd lightmemory-frontend

# 2. 安裝套件
flutter pub get

# 3. 執行（目前用瀏覽器測試）
flutter run -d chrome
```

## 專案結構

```
lib/
├── main.dart              程式進入點
│
├── core/                  核心設定（全專案共用，很少改動）
│   ├── theme/             主題設定 — 顏色、字級、按鈕樣式
│   ├── constants/         常數 — API 網址、頁面名稱等固定值
│   ├── utils/             工具函式 — 日期格式化等小幫手
│   └── network/           連線設定 — 與後端溝通的底層設定
│
├── shared/                共用資源（跨模組使用）
│   ├── widgets/           共用元件 — 大按鈕、卡片等各頁通用零件
│   └── models/            共用資料模型 — 使用者資料等格式定義
│
└── features/              功能模組（六大功能，各自獨立）
    ├── auth/              會員管理 — 身分選擇、註冊登入、AD-8 測驗、新手教學
    ├── game/              遊戲系統 — 六大認知訓練、成就與點數
    ├── diary/             聲影日記 — 照片上傳、語音錄製、動態牆
    ├── dashboard/         健康儀表板 — 腦年齡、雷達圖、週月報表
    ├── info/              資訊加油站 — 活動、機構、衛教資訊
    └── assistant/         AI 小助手 — 對話陪伴介面

assets/                    素材資源
├── images/                圖片
├── icons/                 圖示
├── fonts/                 字型檔
└── audio/                 音訊 — 遊戲音效、語音提示
```

每個功能模組底下固定分三層：

| 資料夾 | 放什麼 |
|--------|--------|
| `pages` | 頁面 — 使用者看到的整個畫面 |
| `widgets` | 元件 — 該模組專用的小零件 |
| `services` | 資料服務 — 呼叫後端 API 的地方 |

## 開發規範

**1. 頁面不直接打 API**

畫面只跟 `services` 要資料，由 `services` 負責呼叫後端。
後端網址或 API 格式變動時，只需修改 `services`，畫面不受影響。

**2. 檔案命名一律小寫加底線**

```
✅ home_page.dart
❌ HomePage.dart
❌ home-page.dart
```

**3. 只改自己負責的模組**

各自在 `features/` 底下負責的資料夾內開發，減少 Git 衝突。

## 分支規則

| 分支 | 用途 |
|------|------|
| `main` | 穩定版本，僅透過 PR 合併 |
| `dev` | 開發主線 |
| `feature/xxx` | 個人功能分支 |

流程：從 `dev` 開 `feature/功能名稱` → 開發完成 push → 發 PR 回 `dev` → 組長 review

## 前端分工

| 模組 | 負責人 |
|------|--------|
| 會員管理 auth | |
| 遊戲系統 game | |
| 聲影日記 diary | |
| 健康儀表板 dashboard | |
| 資訊加油站 info | |
| AI 小助手 assistant | |

## 待補項目

- [ ] `core/theme` — 顏色與字級定義（待設計定案）
- [ ] `core/constants` — 後端 API 網址（待後端提供）
- [ ] 各模組頁面空殼