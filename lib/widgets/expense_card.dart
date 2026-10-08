import 'dart:io';

import 'package:flutter/material.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
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
                      errorBuilder: (_, __, ___) => _categoryIcon(colors),
                    ),
                  ),
                )
              else
                _categoryIcon(colors),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.merchant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                        '${expense.category.label} · ${formatDate(expense.date)}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(formatDong(expense.amount),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: colors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryIcon(ColorScheme colors) => CircleAvatar(
        radius: 23,
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        child: Icon(iconFor(expense.category)),
      );
}
