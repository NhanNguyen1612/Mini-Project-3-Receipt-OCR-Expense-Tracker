import 'package:flutter/material.dart';

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
              CircleAvatar(
                radius: 23,
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: Icon(iconFor(expense.category)),
              ),
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
}
