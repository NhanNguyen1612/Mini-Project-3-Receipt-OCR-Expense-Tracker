import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

class ExpenseDatabase {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    _database = await openDatabase(
      p.join(root, 'vku_expenses.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT NOT NULL,
            amount INTEGER NOT NULL CHECK(amount > 0),
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            photo_path TEXT,
            raw_text TEXT
          )
        ''');
      },
    );
    return _database!;
  }

  Future<List<Expense>> all() async {
    final rows =
        await (await database).query('expenses', orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> insert(Expense expense) async =>
      (await database).insert('expenses', expense.toMap()..remove('id'));

  Future<void> update(Expense expense) async {
    if (expense.id == null) throw ArgumentError('Expense id is required');
    await (await database).update(
      'expenses',
      expense.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> delete(int id) async {
    await (await database).delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
