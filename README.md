# VKU Expense OCR · Mini-Project 3

Ứng dụng Flutter quản lý chi tiêu từ ảnh hóa đơn, theo yêu cầu trong `Week-07-Flutter-Part1.pdf` (trang 41–43) và `Week-08-Flutter-Part2.pdf` (trang 41–43).

## Chức năng

- Camera trực tiếp với khung cắt, bật/tắt flash và chạm lấy nét; ảnh chụp được cắt theo khung trước khi Google ML Kit nhận dạng chữ trên thiết bị. Cũng có thể chọn ảnh từ thư viện.
- Bộ phân tích Dart tìm tên cửa hàng, ngày và tổng tiền; hỗ trợ nhãn có dấu/không dấu như “Tổng cộng”, “Tong tien”, “Thanh toán”, “Total”.
- Màn hình kiểm tra để sửa dữ liệu OCR, chọn ngày và danh mục; app gợi ý danh mục từ từ khóa trên hóa đơn. Có thể nhập khoản chi thủ công.
- Danh mục theo đề bài: Food, Study, Travel, Gear, Entertainment (giao diện hiển thị nhãn tiếng Việt).
- Lưu/sửa/xóa chi tiêu trong SQLite; sao chép ảnh hóa đơn và tạo thumbnail 240 px trong bộ nhớ ứng dụng để hiện trong danh sách.
- Danh sách chi tiêu có thumbnail, tổng tháng, biểu đồ donut theo danh mục và biểu đồ cột 7 ngày vẽ bằng `CustomPainter`; chạm vào cung/cột để xem số tiền.
- Material 3, giao diện sáng/tối và bố cục co giãn theo chiều rộng màn hình.

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
  core/             Định dạng tiền và ngày
  models/           Expense và danh mục
  services/         ML Kit, parser, SQLite, cắt/lưu ảnh
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
