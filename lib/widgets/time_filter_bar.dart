import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/time_filter.dart';
import '../state/time_filter_controller.dart';

class TimeFilterBar extends ConsumerWidget {
  const TimeFilterBar({
    super.key,
    this.compact = false,
  });

  final bool compact;

  Future<void> _pickDate(BuildContext context, WidgetRef ref, TimeFilterState filter) async {
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2050);

    if (filter.mode == TimeFilterMode.year) {
      final picked = await showDialog<int>(
        context: context,
        builder: (ctx) {
          final currentYear = filter.anchorDate.year;
          return AlertDialog(
            title: const Text('Chọn năm'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: YearPicker(
                firstDate: firstDate,
                lastDate: lastDate,
                selectedDate: DateTime(currentYear),
                onChanged: (DateTime dateTime) {
                  Navigator.pop(ctx, dateTime.year);
                },
              ),
            ),
          );
        },
      );
      if (picked != null) {
        ref.read(timeFilterProvider.notifier).setDate(DateTime(picked, 1, 1));
      }
      return;
    }

    if (filter.mode == TimeFilterMode.month) {
      final picked = await showDatePicker(
        context: context,
        initialDate: filter.anchorDate,
        firstDate: firstDate,
        lastDate: lastDate,
        initialDatePickerMode: DatePickerMode.year,
        helpText: 'CHỌN THÁNG & NĂM',
      );
      if (picked != null) {
        ref.read(timeFilterProvider.notifier).setDate(picked);
      }
      return;
    }

    if (filter.mode == TimeFilterMode.day || filter.mode == TimeFilterMode.week) {
      final picked = await showDatePicker(
        context: context,
        initialDate: filter.anchorDate,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: filter.mode == TimeFilterMode.day ? 'CHỌN NGÀY' : 'CHỌN TUẦN',
      );
      if (picked != null) {
        ref.read(timeFilterProvider.notifier).setDate(picked);
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(timeFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: TimeFilterMode.values.map((mode) {
              final isSelected = filter.mode == mode;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text(mode.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(timeFilterProvider.notifier).setMode(mode);
                    }
                  },
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                    color: isSelected
                        ? (isDark ? AppPalette.ink : Colors.white)
                        : (isDark ? const Color(0xFFC0CADB) : AppPalette.ink),
                  ),
                  selectedColor: AppPalette.coral,
                  backgroundColor: isDark
                      ? const Color(0xFF263750)
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? AppPalette.coral
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              );
            }).toList(),
          ),
        ),

        // Navigation row (only if not 'all')
        if (filter.mode != TimeFilterMode.all) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2D44) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  tooltip: 'Kỳ trước',
                  onPressed: () =>
                      ref.read(timeFilterProvider.notifier).previous(),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _pickDate(context, ref, filter),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_month_outlined,
                              size: 16, color: AppPalette.forest),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              filter.displayTitle,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down,
                              size: 18, color: AppPalette.forest),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 24),
                  tooltip: 'Kỳ sau',
                  onPressed: () =>
                      ref.read(timeFilterProvider.notifier).next(),
                ),
                if (!filter.isCurrent)
                  IconButton(
                    icon: const Icon(Icons.restore_rounded,
                        size: 20, color: AppPalette.coral),
                    tooltip: 'Về hiện tại',
                    onPressed: () =>
                        ref.read(timeFilterProvider.notifier).resetToToday(),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
