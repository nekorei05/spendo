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

  // Check if a transaction already exists to prevent duplicates
  static Future<bool> checkDuplicate(Map<String, dynamic> txn) async {
    final db = await initDB();
    final result = await db.query(
      'expenses',
      where: 'amount = ? AND date = ? AND paidTo = ?',
      whereArgs: [txn['amount'], txn['date'], txn['paidTo']],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Insert a transaction safely
  static Future<void> insertExpense(Map<String, dynamic> data) async {
    final isDuplicate = await checkDuplicate(data);
    if (!isDuplicate) {
      final db = await initDB();
      await db.insert('expenses', data);
    }
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

  //delete expense
  static Future<void> deleteExpense(int id) async {
    final db = await initDB();
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  //get data for insights
  static Future<Map<String, double>> getCategoryWiseTotals() async {
    final db = await DBHelper.initDB(); // FIXED HERE
    final result = await db.rawQuery('''
    SELECT category, SUM(amount) as total
    FROM expenses
    WHERE type = 'expense'
    GROUP BY category
  ''');

    Map<String, double> categoryTotals = {};
    for (var row in result) {
      categoryTotals[row['category'] as String] = (row['total'] as num)
          .toDouble();
    }
    return categoryTotals;
  }

  static Future<Map<String, double>> getCategoryTotalsForMonth(
    DateTime month,
  ) async {
    final db = await initDB();
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final result = await db.rawQuery(
      '''
    SELECT category, SUM(amount) as total
    FROM expenses
    WHERE type = 'expense' AND date BETWEEN ? AND ?
    GROUP BY category
  ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    Map<String, double> map = {};
    for (var row in result) {
      map[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  static Future<Map<String, double>> getCategoryTotalsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await initDB();
    final result = await db.rawQuery(
      '''
    SELECT category, SUM(amount) as total
    FROM expenses
    WHERE type = 'expense' AND date BETWEEN ? AND ?
    GROUP BY category
  ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    Map<String, double> map = {};
    for (var row in result) {
      map[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }
}
