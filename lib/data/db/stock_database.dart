import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class StockDatabase {
  StockDatabase._();

  static final StockDatabase instance = StockDatabase._();

  Future<Database>? _db;

  Future<Database> get database async {
    _db ??= _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, 'stock_entries.db');

    return openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE IF NOT EXISTS stock_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  barcode TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  date TEXT NOT NULL
);
''');

        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_stock_entries_date ON stock_entries(date);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_stock_entries_barcode_date ON stock_entries(barcode, date);',
        );
      },
    );
  }

  // Note: we store dates as `yyyy-MM-dd` strings so lexicographic range queries work.
}
