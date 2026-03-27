import 'package:sqflite/sqflite.dart';
import 'package:stock_entry_app/domain/models/barcode_total.dart';
import 'package:stock_entry_app/domain/models/date_barcode_total.dart';
import 'package:stock_entry_app/domain/models/stock_entry.dart';
import 'package:stock_entry_app/domain/repositories/stock_repository.dart';

class StockRepositoryImpl extends StockRepository {
  StockRepositoryImpl(this._dbFuture);

  final Future<Database> _dbFuture;

  @override
  Future<int> insertEntry(StockEntry entry) async {
    final db = await _dbFuture;
    return db.insert(
      'stock_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateEntry(StockEntry entry) async {
    final db = await _dbFuture;
    await db.update(
      'stock_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  @override
  Future<void> deleteEntry(int id) async {
    final db = await _dbFuture;
    await db.delete('stock_entries', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<StockEntry>> fetchEntriesByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _dbFuture;

    final rows = await db.query(
      'stock_entries',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, id DESC',
    );

    return rows.map(StockEntry.fromMap).toList();
  }

  @override
  Future<List<BarcodeTotal>> fetchBarcodeTotalsForRange({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _dbFuture;

    final rows = await db.rawQuery(
      '''
SELECT
  barcode,
  SUM(quantity) AS totalQuantity
FROM stock_entries
WHERE date BETWEEN ? AND ?
GROUP BY barcode
ORDER BY barcode
''',
      [startDate, endDate],
    );

    return rows.map(BarcodeTotal.fromMap).toList();
  }

  @override
  Future<List<DateBarcodeTotal>> fetchDateBarcodeTotalForRange({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _dbFuture;

    final rows = await db.rawQuery(
      '''
SELECT
  date,
  barcode,
  SUM(quantity) AS totalQuantity
FROM stock_entries
WHERE date BETWEEN ? AND ?
GROUP BY date, barcode
ORDER BY date, barcode
''',
      [startDate, endDate],
    );

    return rows.map(DateBarcodeTotal.fromMap).toList();
  }
}
