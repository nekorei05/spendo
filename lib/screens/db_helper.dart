import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'expenses.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL,
            date TEXT,
            paidTo TEXT,
            mode TEXT,
            category TEXT,
            note TEXT,
            type TEXT -- 'income' or 'expense'
          )
        ''');
      },
    );
  }

  static Future<void> insertExpense(Map<String, dynamic> data) async {
    final db = await initDB();
    await db.insert('expenses', data);
  }

  static Future<double> getTotalExpenses() async {
    final db = await initDB();
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE type = "expense"',
    );
    return result.first['total'] != null
        ? result.first['total'] as double
        : 0.0;
  }

  static Future<double> getMonthlyTotalExpenses() async {
    final db = await initDB();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total
      FROM expenses
      WHERE type = "expense" AND date BETWEEN ? AND ?
    ''',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );

    return result.first['total'] != null
        ? result.first['total'] as double
        : 0.0;
  }

  static Future<List<Map<String, dynamic>>> getRecentExpenses() async {
    final db = await initDB();
    return await db.query('expenses', orderBy: 'date DESC', limit: 10);
  }
}
