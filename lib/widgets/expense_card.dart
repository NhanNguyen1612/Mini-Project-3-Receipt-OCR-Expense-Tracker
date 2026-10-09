import 'dart:io';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/receipt_photo_paths.dart';
import '../models/expense.dart';
import '../core/formatters.dart';

IconData iconFor(ExpenseCategory category) => switch (category) {
      ExpenseCategory.food => Icons.restaurant,
      ExpenseCategory.study => Icons.school,
      ExpenseCategory.travel => Icons.directions_bus,
      ExpenseCategory.gear => Icons.shopping_bag,
      ExpenseCategory.entertainment => Icons.movie,
    };

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({super.key, required this.expense, required this.onTap});
  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = switch (expense.category) {
      ExpenseCategory.food => AppPalette.forest,
      ExpenseCategory.study => const Color(0xFF7666AB),
      ExpenseCategory.travel => const Color(0xFF3C8D91),
      ExpenseCategory.gear => const Color(0xFFB77B3B),
      ExpenseCategory.entertainment => const Color(0xFFBD6B74),
    };
    final visibleAccent = Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(accent, Colors.white, 0.42)!
        : accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              if (expense.photoPath case final String photoPath)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(receiptThumbnailPath(photoPath)),
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.file(
                      File(photoPath),
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      cacheWidth: 240,
                      errorBuilder: (_, __, ___) =>
                          _categoryIcon(visibleAccent),
                    ),
                  ),
                )
              else
                _categoryIcon(visibleAccent),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.merchant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 5),
                    Text(
                        '${expense.category.label} · ${formatDate(expense.date)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Text(formatDong(expense.amount),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.primary)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _categoryIcon(Color accent) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(iconFor(expense.category), color: accent, size: 22),
      );
}
