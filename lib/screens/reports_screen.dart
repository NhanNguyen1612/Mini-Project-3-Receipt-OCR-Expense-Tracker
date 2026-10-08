import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../state/expenses_controller.dart';
import '../core/formatters.dart';

const categoryColors = <ExpenseCategory, Color>{
  ExpenseCategory.food: Color(0xFF4D7CA9),
  ExpenseCategory.study: Color(0xFF9E74B8),
  ExpenseCategory.travel: Color(0xFF49A889),
  ExpenseCategory.gear: Color(0xFFE0A64B),
  ExpenseCategory.entertainment: Color(0xFFDC7777),
};

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ExpenseCategory? _selectedCategory;
  int? _selectedDay;

  void _selectCategory(Offset point, Map<ExpenseCategory, int> totals) {
    const center = Offset(105, 105);
    final distance = (point - center).distance;
    if (distance < 70 || distance > 106) return;
    final total = totals.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    var angle =
        math.atan2(point.dy - center.dy, point.dx - center.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    var end = 0.0;
    for (final category in ExpenseCategory.values) {
      end += (totals[category] ?? 0) / total * 2 * math.pi;
      if (angle <= end) {
        setState(() => _selectedCategory = category);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expensesProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Không thể tải báo cáo: $error')),
      data: (expenses) => _content(context, expenses),
    );
  }

  Widget _content(BuildContext context, List<Expense> expenses) {
    if (expenses.isEmpty) {
      return const Center(child: Text('Thêm khoản chi để xem biểu đồ.'));
    }
    final now = DateTime.now();
    final month = expenses.where(
      (e) => e.date.year == now.year && e.date.month == now.month,
    );
    final categoryTotals = <ExpenseCategory, int>{
      for (final category in ExpenseCategory.values) category: 0,
    };
    for (final expense in month) {
      categoryTotals[expense.category] =
          categoryTotals[expense.category]! + expense.amount;
    }
    final total =
        categoryTotals.values.fold<int>(0, (sum, value) => sum + value);
    final today = DateTime(now.year, now.month, now.day);
    final days =
        List.generate(7, (index) => today.subtract(Duration(days: 6 - index)));
    final weeklyTotals = List<int>.filled(7, 0);
    for (final expense in expenses) {
      final day =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      final index = day.difference(days.first).inDays;
      if (index >= 0 && index < 7) weeklyTotals[index] += expense.amount;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Theo danh mục · tháng ${now.month}/${now.year}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, progress, __) => GestureDetector(
                  onTapDown: (details) =>
                      _selectCategory(details.localPosition, categoryTotals),
                  child: SizedBox(
                    width: 210,
                    height: 210,
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
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_selectedCategory?.label ?? 'Tổng chi',
                              style: Theme.of(context).textTheme.bodySmall),
                          Text(
                              formatDong(_selectedCategory == null
                                  ? total
                                  : categoryTotals[_selectedCategory] ?? 0),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...ExpenseCategory.values
                  .where((c) => categoryTotals[c]! > 0)
                  .map(
                    (category) => InkWell(
                      onTap: () => setState(() => _selectedCategory =
                          _selectedCategory == category ? null : category),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(children: [
                          Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: categoryColors[category],
                                borderRadius: BorderRadius.circular(3),
                              )),
                          const SizedBox(width: 8),
                          Expanded(child: Text(category.label)),
                          Text(formatDong(categoryTotals[category]!)),
                        ]),
                      ),
                    ),
                  ),
              if (total == 0) const Text('Chưa có chi tiêu trong tháng này.'),
            ]),
          ),
        ),
        const SizedBox(height: 22),
        Text('Chi tiêu 7 ngày gần đây',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, progress, __) => LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    onTapDown: (details) {
                      final index =
                          (details.localPosition.dx / constraints.maxWidth * 7)
                              .floor()
                              .clamp(0, 6);
                      setState(() => _selectedDay = index);
                    },
                    child: SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: WeeklyBarsPainter(
                          values: weeklyTotals,
                          progress: progress,
                          selectedIndex: _selectedDay,
                          barColor: Theme.of(context).colorScheme.primary,
                          gridColor:
                              Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: days
                    .map((day) => Expanded(
                          child: Text('${day.day}/${day.month}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(_selectedDay == null
                  ? 'Tổng tuần: ${formatDong(weeklyTotals.fold<int>(0, (a, b) => a + b))}'
                  : 'Ngày ${days[_selectedDay!].day}/${days[_selectedDay!].month}: ${formatDong(weeklyTotals[_selectedDay!])}'),
            ]),
          ),
        ),
      ],
    );
  }
}

class DonutPainter extends CustomPainter {
  const DonutPainter(
      {required this.totals,
      required this.progress,
      required this.track,
      required this.selected});
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

class WeeklyBarsPainter extends CustomPainter {
  const WeeklyBarsPainter({
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
    final baseline = size.height - 4;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var line = 0; line <= 3; line++) {
      final y = baseline - line * baseline / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final maxValue = values.fold<int>(0, (a, b) => math.max(a, b));
    final step = size.width / 7;
    final width = math.min(step * 0.56, 36.0);
    for (var i = 0; i < values.length; i++) {
      final ratio = maxValue == 0 ? 0.0 : values[i] / maxValue;
      final height = ratio * (baseline - 12) * progress;
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
                : barColor.withValues(alpha: 0.35));
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyBarsPainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.barColor != barColor ||
      old.gridColor != gridColor ||
      old.selectedIndex != selectedIndex;
}
