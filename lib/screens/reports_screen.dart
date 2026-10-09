import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/expense.dart';
import '../models/time_filter.dart';
import '../state/expenses_controller.dart';
import '../state/time_filter_controller.dart';
import '../core/formatters.dart';
import '../widgets/time_filter_bar.dart';
import '../widgets/expense_card.dart';
import 'review_screen.dart';

const categoryColors = <ExpenseCategory, Color>{
  ExpenseCategory.food: AppPalette.coral,
  ExpenseCategory.study: AppPalette.violet,
  ExpenseCategory.travel: AppPalette.teal,
  ExpenseCategory.gear: AppPalette.amber,
  ExpenseCategory.entertainment: AppPalette.forest,
};

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ExpenseCategory? _selectedCategory;
  int? _selectedBarIndex;

  void _selectCategory(
    Offset point,
    Map<ExpenseCategory, int> totals,
    Size chartSize,
  ) {
    final center = Offset(chartSize.width / 2, chartSize.height / 2);
    final radius = math.min(chartSize.width, chartSize.height) / 2 - 12;
    const stroke = 22.0;
    final distance = (point - center).distance;
    if (distance < radius - stroke / 2 - 8 ||
        distance > radius + stroke / 2 + 8) {
      return;
    }
    final total = totals.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    var angle =
        math.atan2(point.dy - center.dy, point.dx - center.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    var end = 0.0;
    for (final category in ExpenseCategory.values) {
      end += (totals[category] ?? 0) / total * 2 * math.pi;
      if (angle <= end) {
        setState(() => _selectedCategory =
            _selectedCategory == category ? null : category);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expensesProvider);
    final filter = ref.watch(timeFilterProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Không thể tải báo cáo: $error')),
      data: (expenses) => _content(context, expenses, filter),
    );
  }

  Widget _content(
    BuildContext context,
    List<Expense> allExpenses,
    TimeFilterState filter,
  ) {
    if (allExpenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.donut_small_outlined,
                size: 56, color: AppPalette.violet),
            const SizedBox(height: 12),
            Text('Chưa có dữ liệu báo cáo',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Thêm một khoản chi để xem biểu đồ và phân tích.',
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    final filteredExpenses = filter.filter(allExpenses);
    final categoryTotals = <ExpenseCategory, int>{
      for (final category in ExpenseCategory.values) category: 0,
    };
    for (final expense in filteredExpenses) {
      categoryTotals[expense.category] =
          categoryTotals[expense.category]! + expense.amount;
    }
    final total =
        categoryTotals.values.fold<int>(0, (sum, value) => sum + value);

    // Prepare bar chart data based on filter mode
    final barData = _buildBarData(filter, allExpenses, filteredExpenses);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            // Filter Selector Bar
            const TimeFilterBar(),
            const SizedBox(height: 16),

            // Summary card
            Container(
              padding: const EdgeInsets.fromLTRB(23, 20, 23, 21),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppPalette.lime, AppPalette.amber],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(children: [
                const Positioned(
                  right: -9,
                  top: -18,
                  child: Icon(Icons.donut_large_rounded,
                      size: 112, color: Color(0x33FFFFFF)),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('BỨC TRANH CHI TIÊU',
                      style: TextStyle(
                          color: AppPalette.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 13),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(formatDong(total),
                        style: const TextStyle(
                            color: AppPalette.ink,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.4,
                            fontSize: 32)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${filter.displayTitle} · ${filteredExpenses.length} giao dịch',
                    style: const TextStyle(
                        color: AppPalette.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            // Category breakdown heading
            Text('Tiền đã đi đâu?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 3),
            Text('Phân bổ theo danh mục · chạm để xem chi tiết',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),

            // Donut card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, progress, __) => LayoutBuilder(
                      builder: (context, constraints) {
                        final chartSize = Size(
                          math.min(constraints.maxWidth, 210),
                          210,
                        );
                        return GestureDetector(
                          onTapDown: (details) => _selectCategory(
                            details.localPosition,
                            categoryTotals,
                            chartSize,
                          ),
                          child: SizedBox(
                            width: chartSize.width,
                            height: chartSize.height,
                            child: CustomPaint(
                              painter: DonutPainter(
                                totals: categoryTotals,
                                progress: progress,
                                selected: _selectedCategory,
                                track: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                              child: Center(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                          _selectedCategory?.label ??
                                              'Tổng chi',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                      Text(
                                          formatDong(_selectedCategory == null
                                              ? total
                                              : categoryTotals[
                                                      _selectedCategory] ??
                                                  0),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.bold)),
                                    ]),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...ExpenseCategory.values
                      .where((c) => categoryTotals[c]! > 0)
                      .map(
                        (category) => InkWell(
                          onTap: () => setState(() => _selectedCategory =
                              _selectedCategory == category ? null : category),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Row(children: [
                              Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: categoryColors[category],
                                    borderRadius: BorderRadius.circular(5),
                                  )),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(category.label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700))),
                              Text(
                                  '${total == 0 ? 0 : (categoryTotals[category]! / total * 100).round()}%',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 10),
                              Text(formatDong(categoryTotals[category]!),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                            ]),
                          ),
                        ),
                      ),
                  if (total == 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Chưa có chi tiêu trong khoảng thời gian này.'),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // Bar chart / Timeline section
            if (barData != null) ...[
              Text(barData.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 3),
              Text(barData.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, progress, __) => LayoutBuilder(
                        builder: (context, constraints) => GestureDetector(
                          onTapDown: (details) {
                            if (barData.values.isEmpty) return;
                            final index = (details.localPosition.dx /
                                    constraints.maxWidth *
                                    barData.values.length)
                                .floor()
                                .clamp(0, barData.values.length - 1);
                            setState(() => _selectedBarIndex =
                                _selectedBarIndex == index ? null : index);
                          },
                          child: SizedBox(
                            height: 190,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: DynamicBarsPainter(
                                values: barData.values,
                                progress: progress,
                                selectedIndex: _selectedBarIndex,
                                barColor: AppPalette.coral,
                                gridColor: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: barData.labels
                          .map((label) => Expanded(
                                child: Text(label,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(fontSize: 10.5)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedBarIndex == null
                          ? 'Tổng: ${formatDong(barData.values.fold<int>(0, (a, b) => a + b))}'
                          : '${barData.labels[_selectedBarIndex!]}: ${formatDong(barData.values[_selectedBarIndex!])}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // List of transactions in this period
            Text('Khoản chi trong kỳ (${filteredExpenses.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            if (filteredExpenses.isEmpty)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Không có giao dịch nào trong ${filter.displayTitle.toLowerCase()}.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              ...filteredExpenses.map((expense) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExpenseCard(
                      expense: expense,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ReviewScreen(expense: expense),
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  _BarChartData? _buildBarData(
    TimeFilterState filter,
    List<Expense> allExpenses,
    List<Expense> filteredExpenses,
  ) {
    switch (filter.mode) {
      case TimeFilterMode.day:
        // 4 slots: Sáng (0-11h), Trưa (11-14h), Chiều (14-18h), Tối (18-24h)
        final values = List<int>.filled(4, 0);
        for (final expense in filteredExpenses) {
          final hour = expense.date.hour;
          if (hour < 11) {
            values[0] += expense.amount;
          } else if (hour < 14) {
            values[1] += expense.amount;
          } else if (hour < 18) {
            values[2] += expense.amount;
          } else {
            values[3] += expense.amount;
          }
        }
        return _BarChartData(
          title: 'Chi tiêu theo khung giờ trong ngày',
          subtitle: 'Chạm vào cột để xem số tiền từng buổi',
          labels: const ['Sáng', 'Trưa', 'Chiều', 'Tối'],
          values: values,
        );

      case TimeFilterMode.week:
        // 7 days of that week
        final start = TimeFilterState.startOfWeek(filter.anchorDate);
        final values = List<int>.filled(7, 0);
        final labels = <String>[];
        final days = List.generate(7, (i) => start.add(Duration(days: i)));
        for (final expense in filteredExpenses) {
          final expDay =
              DateTime(expense.date.year, expense.date.month, expense.date.day);
          final diff = expDay.difference(start).inDays;
          if (diff >= 0 && diff < 7) {
            values[diff] += expense.amount;
          }
        }
        final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
        for (var i = 0; i < 7; i++) {
          labels.add('${dayNames[i]}\n${days[i].day}/${days[i].month}');
        }
        return _BarChartData(
          title: 'Chi tiêu 7 ngày trong tuần',
          subtitle: 'Chạm vào cột để xem số tiền từng ngày',
          labels: labels,
          values: values,
        );

      case TimeFilterMode.month:
        // 4-5 weeks of that month
        final lastDay =
            DateTime(filter.anchorDate.year, filter.anchorDate.month + 1, 0)
                .day;
        final weekCount = (lastDay / 7).ceil();
        final values = List<int>.filled(weekCount, 0);
        final labels = <String>[];
        for (var w = 0; w < weekCount; w++) {
          final startDay = w * 7 + 1;
          final endDay = math.min((w + 1) * 7, lastDay);
          labels.add('T.${w + 1}\n$startDay-$endDay');
        }
        for (final expense in filteredExpenses) {
          final d = expense.date.day;
          final w = ((d - 1) / 7).floor().clamp(0, weekCount - 1);
          values[w] += expense.amount;
        }
        return _BarChartData(
          title: 'Chi tiêu các tuần trong tháng',
          subtitle: 'Chạm vào cột để xem số tiền từng tuần',
          labels: labels,
          values: values,
        );

      case TimeFilterMode.year:
        // 12 months
        final values = List<int>.filled(12, 0);
        final labels = List.generate(12, (i) => 'T${i + 1}');
        for (final expense in filteredExpenses) {
          final m = expense.date.month - 1;
          if (m >= 0 && m < 12) {
            values[m] += expense.amount;
          }
        }
        return _BarChartData(
          title: 'Chi tiêu 12 tháng năm ${filter.anchorDate.year}',
          subtitle: 'Chạm vào cột để xem số tiền từng tháng',
          labels: labels,
          values: values,
        );

      case TimeFilterMode.all:
        if (allExpenses.isEmpty) return null;
        // Group by recent years
        final years = allExpenses.map((e) => e.date.year).toSet().toList()
          ..sort();
        if (years.length < 2) {
          // If only 1 year, show that year
          final year = years.first;
          final values = List<int>.filled(12, 0);
          for (final expense in allExpenses) {
            values[expense.date.month - 1] += expense.amount;
          }
          return _BarChartData(
            title: 'Chi tiêu các tháng năm $year',
            subtitle: 'Chạm vào cột để xem chi tiết',
            labels: List.generate(12, (i) => 'T${i + 1}'),
            values: values,
          );
        }
        final values = List<int>.filled(years.length, 0);
        final labels = years.map((y) => '$y').toList();
        for (final expense in allExpenses) {
          final idx = years.indexOf(expense.date.year);
          if (idx >= 0) values[idx] += expense.amount;
        }
        return _BarChartData(
          title: 'Chi tiêu theo từng năm',
          subtitle: 'Chạm vào cột để xem chi tiết',
          labels: labels,
          values: values,
        );
    }
  }
}

class _BarChartData {
  const _BarChartData({
    required this.title,
    required this.subtitle,
    required this.labels,
    required this.values,
  });

  final String title;
  final String subtitle;
  final List<String> labels;
  final List<int> values;
}

class DonutPainter extends CustomPainter {
  const DonutPainter({
    required this.totals,
    required this.progress,
    required this.track,
    required this.selected,
  });

  final Map<ExpenseCategory, int> totals;
  final double progress;
  final Color track;
  final ExpenseCategory? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    const stroke = 22.0;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    final total = totals.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    var angle = -math.pi / 2;
    for (final category in ExpenseCategory.values) {
      final value = totals[category] ?? 0;
      if (value == 0) continue;
      final sweep = value / total * math.pi * 2 * progress;
      final paint = Paint()
        ..color = selected == null || selected == category
            ? categoryColors[category]!
            : categoryColors[category]!.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected == category ? stroke + 5 : stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(bounds, angle, sweep, false, paint);
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter old) =>
      old.progress != progress ||
      old.totals != totals ||
      old.track != track ||
      old.selected != selected;
}

class DynamicBarsPainter extends CustomPainter {
  const DynamicBarsPainter({
    required this.values,
    required this.progress,
    required this.barColor,
    required this.gridColor,
    required this.selectedIndex,
  });

  final List<int> values;
  final double progress;
  final Color barColor;
  final Color gridColor;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final baseline = size.height - 4;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var line = 0; line <= 3; line++) {
      final y = baseline - line * baseline / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final maxValue = values.fold<int>(0, (a, b) => math.max(a, b));
    final count = values.length;
    final step = size.width / count;
    final width = math.min(step * 0.58, 36.0);

    for (var i = 0; i < count; i++) {
      final ratio = maxValue == 0 ? 0.0 : values[i] / maxValue;
      final height = ratio * (baseline - 14) * progress;
      final x = step * (i + 0.5) - width / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, baseline - height, width, height),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = selectedIndex == null || selectedIndex == i
              ? barColor
              : barColor.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DynamicBarsPainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.barColor != barColor ||
      old.gridColor != gridColor ||
      old.selectedIndex != selectedIndex;
}
