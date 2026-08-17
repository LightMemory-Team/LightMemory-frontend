# 開發紀錄

## A（頂部列／問候區／動態牆）— 2026/08/17

### 新增檔案
- `lib/features/home/models/home_data.dart`：首頁假資料模型（HomeData、WallPost）
- `lib/features/home/widgets/top_bar.dart`：頂部列（齒輪、標題、通知鈴鐺含數字徽章）
- `lib/features/home/widgets/greeting_section.dart`：問候區（依時間動態顯示早安/午安/晚安＋日期副標）
- `lib/features/home/widgets/dynamic_wall_section.dart`：動態牆（貼文卡片／空狀態提示句）

### 修改檔案
- `lib/screens/home_screen.dart`：接上以上三個元件，取代原本的預留位置

### 目前狀態
- 全部使用假資料（`home_data.dart` 裡的 `mockHomeData`），尚未接上真實 API
- 已測試：正常顯示、動態牆空狀態、通知數為 0 時徽章隱藏

### 待後端確認（給後端組看）
- 需要欄位：`user_name`、`daily_tip`（依日期給不同句子）、`unread_notification_count`、`wall_posts[]`（只需最新1則）
- API 驗證方式尚未確定是 Token Authentication 還是 JWT
- 詳細欄位型別請看《首頁製作與API需求表》文件

### 給 C 整合的提醒
- 三個新元件已經是獨立檔案，直接 import 使用即可，不用改內部邏輯
- 如果要接真實 API，只需要修改 `home_data.dart`，把 `mockHomeData` 換成真正的網路請求，`home_screen.dart` 跟三個元件完全不用動