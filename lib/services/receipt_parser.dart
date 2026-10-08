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
  static final _totalLabel = RegExp(
    r'(?:tổng\s*(?:cộng|tiền|thanh\s*toán)?|tong\s*(?:cong|tien)?|thanh\s*toán|thanh\s*toan|grand\s*total|amount\s*due|total|phải\s*trả)',
    caseSensitive: false,
  );
  static final _ignoreMoneyLine = RegExp(
    r'(?:mã\s*số\s*thuế|mã\s*đơn|số\s*hóa\s*đơn|điện\s*thoại|hotline|mst|tax\s*id)',
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
      if (_totalLabel.hasMatch(line) || _ignoreMoneyLine.hasMatch(line)) {
        continue;
      }
      if (RegExp(r'^(?:hóa\s*đơn|hoa\s*don|receipt|bill|địa\s*chỉ)',
              caseSensitive: false)
          .hasMatch(line)) {
        continue;
      }
      return line;
    }
    return null;
  }

  int? _amount(List<String> lines) {
    final candidates = <({int value, int score})>[];
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (_ignoreMoneyLine.hasMatch(line)) continue;
      final labeled = _totalLabel.hasMatch(line);
      if (!labeled && (_date.hasMatch(line) || _isoDate.hasMatch(line))) {
        continue;
      }
      final searchLines =
          labeled && index + 1 < lines.length && _money.allMatches(line).isEmpty
              ? [line, lines[index + 1]]
              : [line];
      for (final candidateLine in searchLines) {
        for (final match in _money.allMatches(candidateLine)) {
          final value = _parseAmount(match.group(1)!);
          if (value == null || value < 100) continue;
          final score = (labeled ? 100000000 : 0) +
              (RegExp(r'(?:đ|₫|vnd|vnđ)', caseSensitive: false)
                      .hasMatch(candidateLine)
                  ? 10000000
                  : 0) +
              index * 10000 +
              (labeled ? match.start : (value < 9999 ? value : 9999));
          candidates.add((value: value, score: score));
        }
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.score.compareTo(a.score));
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
