"""Generate the technical report for Mini-Project 3."""

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    Flowable,
    Image,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "mini_project_3_technical_report.pdf"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

FONT_DIR = Path("C:/Windows/Fonts")
pdfmetrics.registerFont(TTFont("Arial", str(FONT_DIR / "arial.ttf")))
pdfmetrics.registerFont(TTFont("Arial-Bold", str(FONT_DIR / "arialbd.ttf")))

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(
    name="ReportTitle", fontName="Arial-Bold", fontSize=19, leading=24,
    textColor=colors.HexColor("#233D60"), alignment=TA_CENTER, spaceAfter=12,
))
styles.add(ParagraphStyle(
    name="ReportH1", fontName="Arial-Bold", fontSize=12.5, leading=17,
    textColor=colors.HexColor("#233D60"), spaceBefore=13, spaceAfter=6,
))
styles.add(ParagraphStyle(
    name="ReportBody", fontName="Arial", fontSize=9.5, leading=14,
    spaceAfter=6,
))
styles.add(ParagraphStyle(
    name="ReportSmall", fontName="Arial", fontSize=8.5, leading=12,
    spaceAfter=4,
))


def p(text, style="ReportBody"):
    return Paragraph(text, styles[style])


def bullet(text):
    return p("• " + text)


def section(title, paragraphs):
    return [p(title, "ReportH1"), *[p(item) for item in paragraphs]]


class ArchitectureDiagram(Flowable):
    def __init__(self):
        super().__init__()
        self.width = 174 * mm
        self.height = 65 * mm

    def draw(self):
        c = self.canv
        box_w, box_h, gap = 35 * mm, 19 * mm, 11 * mm
        top_y, bottom_y = 41 * mm, 2 * mm
        top = ["Ảnh hóa đơn", "ML Kit OCR", "ReceiptParser", "Review &amp; sửa"]
        bottom = ["Danh sách / chart", "Riverpod", "SQLite", "Xác nhận lưu"]
        positions = [i * (box_w + gap) for i in range(4)]
        for row, y in [(top, top_y), (bottom, bottom_y)]:
            for i, label in enumerate(row):
                x = positions[i]
                c.setFillColor(colors.HexColor("#E7EFF7" if y == top_y else "#E8F4EE"))
                c.setStrokeColor(colors.HexColor("#7492AE"))
                c.roundRect(x, y, box_w, box_h, 5, stroke=1, fill=1)
                c.setFillColor(colors.HexColor("#233D60"))
                c.setFont("Arial-Bold", 8.2)
                c.drawCentredString(x + box_w / 2, y + 8 * mm, label.replace("&amp;", "&"))
        c.setStrokeColor(colors.HexColor("#62809B"))
        c.setLineWidth(1.1)

        def arrow(x1, y1, x2, y2):
            c.line(x1, y1, x2, y2)
            if x2 > x1:
                c.line(x2 - 3 * mm, y2 + 1.5 * mm, x2, y2)
                c.line(x2 - 3 * mm, y2 - 1.5 * mm, x2, y2)
            elif x2 < x1:
                c.line(x2 + 3 * mm, y2 + 1.5 * mm, x2, y2)
                c.line(x2 + 3 * mm, y2 - 1.5 * mm, x2, y2)
            else:
                c.line(x2 - 1.5 * mm, y2 + 3 * mm, x2, y2)
                c.line(x2 + 1.5 * mm, y2 + 3 * mm, x2, y2)

        for i in range(3):
            arrow(positions[i] + box_w, top_y + box_h / 2,
                  positions[i + 1], top_y + box_h / 2)
            arrow(positions[i + 1], bottom_y + box_h / 2,
                  positions[i] + box_w, bottom_y + box_h / 2)
        arrow(positions[3] + box_w / 2, top_y, positions[3] + box_w / 2,
              bottom_y + box_h)


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor("#D5DEE8"))
    canvas.line(18 * mm, 18 * mm, 192 * mm, 18 * mm)
    canvas.setFont("Arial", 8)
    canvas.setFillColor(colors.HexColor("#607086"))
    canvas.drawString(18 * mm, 13 * mm, "VKU · Mini-Project 3 · Receipt OCR & Expense Tracker")
    canvas.drawRightString(192 * mm, 13 * mm, f"Trang {doc.page}")
    canvas.restoreState()


doc = BaseDocTemplate(
    str(OUTPUT), pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm,
    topMargin=19 * mm, bottomMargin=23 * mm,
)
frame = Frame(18 * mm, 23 * mm, 174 * mm, 255 * mm, leftPadding=0,
              rightPadding=0, topPadding=0, bottomPadding=0)
doc.addPageTemplates(PageTemplate(id="report", frames=frame, onPage=footer))

story = [
    p("BÁO CÁO KỸ THUẬT<br/>RECEIPT OCR & EXPENSE TRACKER", "ReportTitle"),
    p("Học phần: Phát triển ứng dụng di động đa nền tảng | Mini-Project 3"),
    p("<b>Phạm vi:</b> Mã nguồn Flutter trong dự án này; yêu cầu từ slide tuần 7 (trang 41–43) và tuần 8 (trang 41–43)."),
    *section("1. Mục tiêu và chức năng", [
        "Ứng dụng hỗ trợ ghi lại khoản chi từ hóa đơn giấy. Người dùng chụp ảnh hoặc chọn ảnh; Google ML Kit nhận dạng văn bản ngay trên thiết bị. Bộ phân tích Dart tìm cửa hàng, ngày và tổng tiền. Người dùng kiểm tra và sửa kết quả trước khi lưu.",
        "Dữ liệu được lưu bằng SQLite và ảnh được sao chép vào thư mục riêng của ứng dụng. Danh sách cho phép sửa, xóa và xem tổng tháng. Tab báo cáo thể hiện chi tiêu theo danh mục bằng biểu đồ donut và chi tiêu 7 ngày bằng biểu đồ cột; cả hai được vẽ bằng CustomPainter.",
    ]),
    p("2. Đối chiếu rubric", "ReportH1"),
]

rubric = [
    ["Tiêu chí", "Hiện thực", "Điểm"],
    ["OCR + parser", "Camera, ML Kit Latin, regex/heuristic", "3.5"],
    ["Biểu đồ canvas", "Donut và cột tuần có hoạt ảnh, chạm để xem số", "2.5"],
    ["State + DB", "Riverpod AsyncNotifier, SQLite CRUD, lưu ảnh", "2.0"],
    ["UI/UX", "Material 3, sáng/tối, duyệt và sửa OCR", "1.0"],
    ["Nộp bài", "Mã nguồn, báo cáo, APK; cần quay video trên máy thật", "1.0"],
]
table = Table(rubric, colWidths=[40 * mm, 119 * mm, 15 * mm], repeatRows=1)
table.setStyle(TableStyle([
    ("FONTNAME", (0, 0), (-1, 0), "Arial-Bold"),
    ("FONTNAME", (0, 1), (-1, -1), "Arial"),
    ("FONTSIZE", (0, 0), (-1, -1), 8.2),
    ("LEADING", (0, 0), (-1, -1), 12),
    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#DFEAF4")),
    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F7FAFC")]),
    ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#D5DEE8")),
    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ("LEFTPADDING", (0, 0), (-1, -1), 6),
    ("RIGHTPADDING", (0, 0), (-1, -1), 6),
    ("TOPPADDING", (0, 0), (-1, -1), 7),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
]))
story += [table, Spacer(1, 8 * mm), p(
    "<b>Lưu ý:</b> Điểm trong bảng là trọng số theo rubric, không phải điểm tự đánh giá. "
    "Ảnh chụp và dữ liệu lưu đã được kiểm tra trên Android emulator; OCR camera cần thử thêm trên máy thật."
), PageBreak()]

story += [
    p("THIẾT KẾ VÀ XỬ LÝ DỮ LIỆU", "ReportTitle"),
    p("3. Sơ đồ kiến trúc", "ReportH1"),
    ArchitectureDiagram(),
    *section("4. Các thành phần", [
        "Giao diện chia thành HomeScreen (danh sách), CameraScanScreen (xem trực tiếp, lấy nét, flash, cắt ảnh), ReviewScreen (kiểm tra/sửa), ReportsScreen (thống kê). Riverpod AsyncNotifier nối giao diện với ExpenseDatabase; ReceiptService quản lý ML Kit và ảnh đã lưu.",
        "Luồng dữ liệu: ảnh → TextRecognizer → ReceiptParser → ReviewScreen → ExpenseDatabase → màn hình danh sách/báo cáo. Toàn bộ nhận dạng và dữ liệu chi tiêu được xử lý cục bộ, không cần API hoặc tài khoản.",
    ]),
    *section("5. Dữ liệu và trạng thái", [
        "Bảng expenses gồm id, merchant, amount (INTEGER VND), date (ISO 8601), category, photo_path và raw_text. amount có ràng buộc lớn hơn 0. CRUD thực hiện qua sqflite; danh sách sắp xếp theo ngày và id giảm dần.",
        "Ảnh gốc từ image_picker có thể nằm trong cache; ứng dụng sao chép vào Application Documents/receipts khi lưu để dùng lâu dài. Khi xóa khoản chi, ảnh liên quan cũng được xóa. Controller trạng thái làm mới danh sách sau mỗi thay đổi.",
    ]),
    *section("6. Biểu đồ", [
        "DonutPainter vẽ cung theo tỷ trọng của từng danh mục trong tháng hiện tại. WeeklyBarsPainter tính tổng theo ngày từ hôm nay lùi 6 ngày, chuẩn hóa chiều cao cột theo ngày lớn nhất. TweenAnimationBuilder điều khiển hoạt ảnh; chạm vào cung/cột để xem giá trị.",
    ]),
    PageBreak(),
    p("BỘ PHÂN TÍCH OCR VÀ KIỂM THỬ", "ReportTitle"),
    p("7. Bảng regex và heuristic", "ReportH1"),
]

regex_rows = [
    ["Trường", "Mẫu / quy tắc", "Ví dụ"],
    ["Tổng tiền", "tổng|tong|thanh toán|thanh toan|total|amount due; ưu tiên dòng có nhãn, lấy số cuối nếu nhiều số", "Tổng tiền: 2 × 35.000 = 70.000"],
    ["Số tiền", "Nhóm 3 chữ số có dấu chấm/phẩy/khoảng trắng hoặc 4–9 chữ số liền; hỗ trợ đ, ₫, VND, VNĐ", "150.000 đ; 150,000; 150000"],
    ["Ngày", "dd/MM/yyyy, dd-MM-yyyy hoặc yyyy-MM-dd; kiểm tra ngày có tồn tại", "22/10/2026"],
    ["Cửa hàng", "Dòng có chữ trong 6 dòng đầu; bỏ tiêu đề, địa chỉ, ngày, mã số thuế", "HIGHLANDS COFFEE"],
]
regex_table = Table(
    [[p(cell, "ReportSmall") for cell in row] for row in regex_rows],
    colWidths=[25 * mm, 104 * mm, 45 * mm], repeatRows=1,
)
regex_table.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#DFEAF4")),
    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F7FAFC")]),
    ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#D5DEE8")),
    ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ("LEFTPADDING", (0, 0), (-1, -1), 6),
    ("RIGHTPADDING", (0, 0), (-1, -1), 6),
    ("TOPPADDING", (0, 0), (-1, -1), 7),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
]))
story += [
    regex_table,
    p("ReviewScreen hiển thị ảnh và văn bản OCR gốc để người dùng đối chiếu, sửa cửa hàng, số tiền, ngày và danh mục trước khi ghi vào SQLite."),
    *section("8. Kiểm thử đã thiết kế", [
        "flutter test chạy các ca parser (nhiều dòng tiền, nhãn tổng tiền, ngày ISO/không hợp lệ, chữ không dấu), cắt ảnh theo khung và gợi ý danh mục. flutter analyze không có lỗi sau khi hoàn thiện mã nguồn.",
        "Các ca cần kiểm tra thủ công trên Android/iOS: cấp quyền camera/thư viện, ảnh mờ hoặc xoay, nhận dạng không ra chữ, sửa kết quả OCR, đóng ứng dụng rồi mở lại, xóa khoản chi kèm ảnh, xoay màn hình và giao diện tối.",
    ]),
    PageBreak(),
    p("ẢNH CHỤP ỨNG DỤNG VÀ BÀN GIAO", "ReportTitle"),
    p("9. Màn hình chạy trên Android emulator", "ReportH1"),
    p("Bản debug được cài, mở và nhập một khoản chi 65.000 đ. SQLite vẫn giữ dữ liệu sau khi cài lại ứng dụng. Biểu đồ cột phản hồi khi chạm vào ngày 8/10."),
    Table([[
        Image(str(ROOT / "docs" / "screenshots" / "emulator_light.png"), width=62 * mm, height=137.8 * mm),
        Image(str(ROOT / "docs" / "screenshots" / "emulator_dark.png"), width=62 * mm, height=137.8 * mm),
    ]], colWidths=[87 * mm, 87 * mm], style=TableStyle([
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ])),
    p("<b>Trái:</b> danh sách ở giao diện sáng. <b>Phải:</b> báo cáo ở giao diện tối.", "ReportSmall"),
    p("10. Kết quả và giới hạn", "ReportH1"),
    p("Ứng dụng dùng Flutter 3.47.6, Dart 3.13.5. Đã chạy analyze, test và build APK. Camera, OCR trên hóa đơn giấy và video demo vẫn cần xác nhận trên điện thoại có camera thật. Parser và gợi ý danh mục dựa trên quy tắc, nên ảnh mờ hoặc bố cục lạ cần sửa tay.", "ReportSmall"),
    p("<b>Gói nộp:</b> APK release ký riêng, mã nguồn/README, PDF này; cần đưa repo lên GitHub công khai và quay video 2–3 phút quét hóa đơn thật trước khi nộp.", "ReportSmall"),
]

doc.build(story)
print(OUTPUT)
