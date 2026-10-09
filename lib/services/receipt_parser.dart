import 'dart:math' as math;

class ParsedReceipt {
  const ParsedReceipt(
      {this.merchant, this.amount, this.date, required this.rawText});

  final String? merchant;
  final int? amount;
  final DateTime? date;
  final String rawText;
}

class ReceiptParser {
  static final _money = RegExp(
    r'(?<!\d)(\d{1,3}(?:[.,\s]\d{3})+|\d{4,9})(?:\s*(?:đ|₫|vnd|vnđ))?(?!\d)',
    caseSensitive: false,
  );
  static final _date = RegExp(
    r'(?<!\d)(\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})(?!\d)',
  );
  static final _isoDate = RegExp(r'(?<!\d)(\d{4})-(\d{1,2})-(\d{1,2})(?!\d)');

  // Receipt headers/titles that must NEVER be treated as a total label or raw merchant:
  static final _receiptTitle = RegExp(
    r'^(?:phiếu|phieu|phiêu|hóa\s*đơn|hoa\s*don|giấy|giay|bảng\s*kê|receipt|bill)\s*(?:thanh\s*toán|thanh\s*toan|bán\s*hàng|bán\s*lẻ|gtgt|vat)?',
    caseSensitive: false,
  );

  static final _exactTotalLabel = RegExp(
    r'(?:tổng\s*(?:cộng|tiền|thanh\s*toán)|tong\s*(?:cong|tien)|thanh\s*toán|thanh\s*toan|tiền\s*thanh\s*toán|grand\s*total|amount\s*due|cần\s*thanh\s*toán|phải\s*trả)',
    caseSensitive: false,
  );

  static final _genericTotalLabel = RegExp(
    r'(?:tổng|tong|total|tiền\s*mặt|chuyển\s*khoản)',
    caseSensitive: false,
  );

  // Lines whose numbers must NEVER be treated as a payment total:
  static final _ignoreMoneyLine = RegExp(
    r'(?:mã\s*số\s*thuế|mã\s*đơn|số\s*hóa\s*đơn|số\s*ct\b|số\s*chứng\s*từ|\bct\s*:'
    r'|điện\s*thoại|hotline|mst|tax\s*id|\*{2,}|\bgpp\b|sau\s*\d+\s*h\b'
    r'|tiện\s*(?:điện|ích)|hóa\s*đơn\s*tiện|internet|wifi|account\s*no|acct\s*no'
    r'|tròn\s*xuống|làm\s*tròn|tiết\s*kiệm|điểm\s*(?:sử\s*dụng|tích|thưởng)'
    r'|khách\s*mua\s*tại|góp\s*ý|zalo|facebook|website|www\.|\.com\b|\.vn\b'
    r'|chính\s*sách|đổi\s*trả)',
    caseSensitive: false,
  );

  ParsedReceipt parse(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return ParsedReceipt(
      merchant: _merchant(lines),
      amount: _amount(lines),
      date: _findDate(lines),
      rawText: text,
    );
  }

  String? _merchant(List<String> lines) {
    for (final line in lines.take(6)) {
      if (line.length < 3 || line.length > 60) continue;
      if (!RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(line)) continue;
      if (_date.hasMatch(line) || _isoDate.hasMatch(line)) continue;
      if (_ignoreMoneyLine.hasMatch(line)) continue;

      // If line is a receipt title like "PHIẾU THANH TOÁN BÁCH HÓA XANH",
      // strip the prefix to extract the merchant brand name!
      if (_receiptTitle.hasMatch(line)) {
        final stripped = line.replaceFirst(_receiptTitle, '').replaceAll(RegExp(r'^[\s\-:]+'), '').trim();
        if (stripped.length >= 3 && RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(stripped)) {
          return stripped;
        }
        continue;
      }

      if (_exactTotalLabel.hasMatch(line)) continue;
      if (RegExp(r'^(?:địa\s*chỉ|address|tel|phone)', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      return line;
    }
    return null;
  }

  int? _amount(List<String> lines) {
    final candidates = <({int value, int score, bool hasSeparators})>[];
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (_ignoreMoneyLine.hasMatch(line)) continue;

      // A receipt title header (e.g. "PHIẾU THANH TOÁN BÁCH HÓA XANH") is NEVER a total line!
      final isTitle = _receiptTitle.hasMatch(line);
      final isExactTotal = !isTitle && _exactTotalLabel.hasMatch(line);
      final isGenericTotal = !isTitle && !isExactTotal && _genericTotalLabel.hasMatch(line);
      final labeled = isExactTotal || isGenericTotal;

      if (!labeled && (_date.hasMatch(line) || _isoDate.hasMatch(line))) {
        continue;
      }

      final searchLines =
          labeled && index + 1 < lines.length && _money.allMatches(line).isEmpty
              ? [line, lines[index + 1]]
              : [line];

      for (final candidateLine in searchLines) {
        if (_ignoreMoneyLine.hasMatch(candidateLine)) continue;
        for (final match in _money.allMatches(candidateLine)) {
          final raw = match.group(1)!;
          final value = _parseAmount(raw);
          if (value == null || value < 100) continue;

          final hasSeparators =
              RegExp(r'^\d{1,3}(?:[.,]\d{3})+$').hasMatch(raw.replaceAll(' ', ''));
          final hasCurrency =
              RegExp(r'(?:đ|₫|vnd|vnđ)', caseSensitive: false).hasMatch(candidateLine);

          // Discard bare 6-9 digit numbers that look like dates or order IDs
          // (e.g. 4012026 ending in 2026, or 16092026) without separators or currency
          if (!hasSeparators && !hasCurrency && !isExactTotal) {
            if (raw.length >= 6 && RegExp(r'20[2-3]\d$').hasMatch(raw)) {
              continue;
            }
            if (raw.length >= 7) {
              continue;
            }
          }

          var score = 0;
          if (isExactTotal) {
            score += 200000000;
          } else if (isGenericTotal) {
            score += 100000000;
          }

          if (hasSeparators) score += 20000000;
          if (hasCurrency) score += 10000000;

          score += index * 10000;
          score += (labeled ? match.start : math.min(value, 9999));

          candidates.add((
            value: value,
            score: score,
            hasSeparators: hasSeparators,
          ));
        }
      }
    }
    if (candidates.isEmpty) return null;

    final hasLabeled = candidates.any((c) => c.score >= 100000000);
    if (hasLabeled) {
      candidates.sort((a, b) => b.score.compareTo(a.score));
      return candidates.first.value;
    }

    // Unlabeled fallback: prioritize properly formatted currency (with dots/commas)
    // then pick the largest value among formatted ones.
    final formatted = candidates.where((c) => c.hasSeparators).toList();
    if (formatted.isNotEmpty) {
      formatted.sort((a, b) => b.value.compareTo(a.value));
      return formatted.first.value;
    }

    candidates.sort((a, b) => b.value.compareTo(a.value));
    return candidates.first.value;
  }

  int? _parseAmount(String raw) {
    final compact = raw.replaceAll(' ', '');
    if (RegExp(r'^\d{1,3}(?:[.,]\d{3})+$').hasMatch(compact)) {
      return int.tryParse(compact.replaceAll(RegExp(r'[.,]'), ''));
    }
    return int.tryParse(compact);
  }

  DateTime? _findDate(List<String> lines) {
    for (final line in lines) {
      final iso = _isoDate.firstMatch(line);
      if (iso != null) {
        final value = _validDate(
            int.parse(iso[1]!), int.parse(iso[2]!), int.parse(iso[3]!));
        if (value != null) return value;
      }
      final match = _date.firstMatch(line);
      if (match != null) {
        var year = int.parse(match[3]!);
        if (year < 100) year += 2000;
        final value =
            _validDate(year, int.parse(match[2]!), int.parse(match[1]!));
        if (value != null) return value;
      }
    }
    return null;
  }

  DateTime? _validDate(int year, int month, int day) {
    if (year < 2000 || year > 2100) return null;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }
}
