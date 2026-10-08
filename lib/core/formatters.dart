import 'package:intl/intl.dart';

String formatDong(num amount) =>
    '${NumberFormat.decimalPattern('vi_VN').format(amount)} đ';

String formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
