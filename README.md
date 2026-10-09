# VKU Expense OCR · Mini-Project 3

Ứng dụng Flutter quản lý chi tiêu từ ảnh hóa đơn (On-device OCR với Google ML Kit, phân tích biểu đồ trực quan CustomPainter, bộ lọc thời gian linh hoạt Ngày / Tuần / Tháng / Năm).

---

## 🎥 Video Demo Trực Tiếp

> 🎬 **Video trình diễn quét hóa đơn OCR và theo dõi chi tiêu trên thiết bị thực tế:**

https://github.com/NhanNguyen1612/Mini-Project-3-Receipt-OCR-Expense-Tracker/raw/main/DemoProject3.mp4

👉 **Xem hoặc tải file video gốc trong kho lưu trữ:** [DemoProject3.mp4](./DemoProject3.mp4)

---

## Chức năng nổi bật

- **Quét hóa đơn bằng Camera & Thư viện:** Tích hợp Google ML Kit Text Recognition chạy offline 100% trên thiết bị, camera lấy nét và flash.
- **Bộ phân tích cú pháp thông minh (Receipt Parser):** Trích xuất chính xác tên cửa hàng, ngày hóa đơn và tổng tiền; lọc bỏ các dòng mã thẻ che (`******4381`), dòng khuyến mãi, số chứng từ và tiêu đề phiếu.
- **Bộ lọc thời gian linh hoạt:** Hỗ trợ xem và thống kê chi tiêu theo **Ngày, Tuần, Tháng, Năm và Tất cả** thời gian, tích hợp DatePicker trực quan.
- **Biểu đồ trực quan CustomPainter:**
  - Biểu đồ tròn (Donut Chart) phân bổ chi tiêu theo danh mục (Ăn uống, Học tập, Di chuyển, Đồ dùng, Giải trí) có hit-testing chạm để xem chi tiết.
  - Biểu đồ cột động (Dynamic Bar Chart) thích ứng theo kỳ xem (khung giờ theo ngày, 7 ngày trong tuần, các tuần trong tháng, 12 tháng trong năm).
- **Lưu trữ cục bộ SQLite:** Quản lý CRUD khoản chi tiêu hoàn toàn offline, lưu ảnh hóa đơn an toàn trong ứng dụng.
- **Giao diện hiện đại (Material 3):** Hỗ trợ Dark Mode / Light Mode, thiết kế chuẩn thẩm mỹ di động.

## Chạy ứng dụng

Cần cài Flutter SDK và Android SDK (hoặc Xcode trên macOS). Trong thư mục dự án:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Thư mục `android/` và `ios/` đã được sinh bằng Flutter 3.47.6. Android cần API tối thiểu 24 vì thư viện `camera` dùng CameraX.

Trong Android Studio, mở **thư mục gốc dự án** (không mở riêng `android/`), chọn `lib/main.dart` và thiết bị Android rồi nhấn **Run**. Lần build debug đầu có thể mất vài phút khi Gradle tạo cache. Nếu emulator chỉ hiện màn hình đen hoặc `adb devices` báo `offline`, mở **Tools → Device Manager → Medium Phone → Cold Boot Now**, đợi Android khởi động xong rồi Stop/Run lại trong Android Studio. Các dòng `restricted method in java.lang.System` của Gradle là cảnh báo Java, không phải lỗi biên dịch.

Các khóa quyền ảnh/camera đã có trong `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Chụp hóa đơn để nhận dạng chi tiêu.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Chọn ảnh hóa đơn để nhận dạng chi tiêu.</string>
```

OCR của ML Kit và dữ liệu chi tiêu được xử lý cục bộ, không gửi lên máy chủ. Chức năng quét cần thiết bị có camera; trình giả lập có thể dùng để thử giao diện và nhập thủ công.
Chưa đo độ trễ OCR dưới 100 ms trên điện thoại thật; đây là mục tiêu trong đề, không phải kết quả kiểm thử hiện tại.

## Luồng dùng thử

1. Nhấn **Thêm chi tiêu** → **Chụp hóa đơn**; đặt hóa đơn trong khung, chạm lấy nét, bật flash khi cần rồi nhấn **Chụp và quét**. Hoặc chọn ảnh từ thư viện.
2. Kiểm tra và sửa tên cửa hàng, số tiền, ngày và danh mục.
3. Lưu; mở khoản chi từ danh sách để sửa hoặc xóa.
4. Mở tab **Báo cáo** để xem thống kê tháng và 7 ngày gần đây.

Nếu OCR không thấy tổng tiền hoặc hóa đơn viết tay/nhòe, nhập lại ở màn hình kiểm tra. Có thể chọn **Nhập thủ công** để tạo dữ liệu thử.

## Cấu trúc

```text
lib/
  core/             Định dạng tiền/ngày (formatters.dart), đường dẫn ảnh (receipt_photo_paths.dart), giao diện (app_theme.dart)
  models/           Expense và danh mục
  services/         ML Kit, parser, SQLite, cắt/lưu ảnh, phân loại danh mục
  state/            Riverpod AsyncNotifier
  screens/          camera, danh sách, duyệt/sửa, báo cáo
  widgets/          thẻ chi tiêu tái sử dụng
test/               kiểm thử parser OCR, cắt ảnh, gợi ý danh mục
```

## Đóng gói nộp bài

Kiểm tra mã nguồn và tạo APK Android:

```powershell
flutter analyze
flutter test
flutter build apk --release
```

`android/app/build.gradle.kts` đọc cấu hình ký từ `android/key.properties`. Bản APK trong `output/apk/` được ký bằng khóa cục bộ `android/upload-key.jks`; hai tệp này bị Git bỏ qua. **Sao lưu riêng khóa và mật khẩu** nếu muốn phát hành bản cập nhật cùng application ID. Khi clone repo sang máy khác, tạo khóa ký và `android/key.properties` của riêng bạn trước khi build release. Không đưa khóa ký hay mật khẩu lên GitHub.

Ảnh chụp app chạy trên Android emulator có trong `docs/screenshots/`. Báo cáo 4 trang ở `output/pdf/mini_project_3_technical_report.pdf`.

Theo slide tuần 8, checklist nộp bài đầy đủ là:

- `app-release.apk` **đã ký**; thử thêm trên điện thoại Android thật và cung cấp link tải qua GitHub Releases hoặc Google Drive.
- Video **2–3 phút** quay camera quét hóa đơn thật, parser điền dữ liệu, màn hình duyệt/sửa và biểu đồ donut cập nhật. Có kịch bản trong `docs/demo_plan.md`.
- Repo GitHub **công khai** với cấu trúc `core/`, `models/`, `services/`, `state/`, `widgets/`, `screens/`, commit gọn và README này.
- Báo cáo PDF **2–4 trang** gồm sơ đồ kiến trúc, bảng regex, ảnh chụp app trên emulator ở chế độ sáng/tối và giới hạn.

Slide ghi hạn cuối là **Chủ nhật 23:59 của tuần 8** và trừ 1 điểm cho mỗi ngày nộp muộn. Hãy đối chiếu lịch môn học để xác nhận ngày cụ thể.
