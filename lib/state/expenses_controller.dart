import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../services/expense_database.dart';
import '../services/receipt_service.dart';

final databaseProvider = Provider<ExpenseDatabase>((ref) => ExpenseDatabase());
final receiptServiceProvider =
    Provider<ReceiptService>((ref) => ReceiptService());

final expensesProvider =
    AsyncNotifierProvider<ExpensesController, List<Expense>>(
  ExpensesController.new,
);

class ExpensesController extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() => ref.read(databaseProvider).all();

  Future<void> add(Expense expense) async {
    await ref.read(databaseProvider).insert(expense);
    state = AsyncData(await ref.read(databaseProvider).all());
  }

  Future<void> edit(Expense expense) async {
    await ref.read(databaseProvider).update(expense);
    state = AsyncData(await ref.read(databaseProvider).all());
  }

  Future<void> remove(Expense expense) async {
    await ref.read(databaseProvider).delete(expense.id!);
    try {
      await ref.read(receiptServiceProvider).deletePhoto(expense.photoPath);
    } catch (_) {
      // The database record is already gone; a missing photo must not restore it.
    }
    state = AsyncData(await ref.read(databaseProvider).all());
  }
}
