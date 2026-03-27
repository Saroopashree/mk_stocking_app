import 'package:stock_entry_app/domain/models/barcode_total.dart';
import 'package:stock_entry_app/domain/models/date_barcode_total.dart';
import 'package:stock_entry_app/domain/models/stock_entry.dart';

abstract class StockRepository {
  Future<int> insertEntry(StockEntry entry);

  Future<void> updateEntry(StockEntry entry);

  Future<void> deleteEntry(int id);

  /// Fetch raw entries for management/editing
  Future<List<StockEntry>> fetchEntriesByDateRange({
    required String startDate,
    required String endDate,
  });

  /// Fetch aggregated totals by barcode across a date range.
  Future<List<BarcodeTotal>> fetchBarcodeTotalsForRange({
    required String startDate,
    required String endDate,
  });

  /// Fetch per-day totals gropued by date+barcode (useful for CSV export for ranges).
  Future<List<DateBarcodeTotal>> fetchDateBarcodeTotalForRange({
    required String startDate,
    required String endDate,
  });
}
