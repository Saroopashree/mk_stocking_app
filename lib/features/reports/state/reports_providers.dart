import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_entry_app/core/providers.dart';
import 'package:stock_entry_app/domain/models/barcode_total.dart';
import 'package:stock_entry_app/domain/models/stock_entry.dart';

@immutable
class ReportsQuery {
  const ReportsQuery({required this.startDate, required this.endDate});

  final String startDate;
  final String endDate;

  bool get isSingleDate => startDate == endDate;

  @override
  bool operator ==(Object other) {
    return other is ReportsQuery &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate);
}

final reportsSummaryProvider = FutureProvider.autoDispose
    .family<List<BarcodeTotal>, ReportsQuery>((ref, query) async {
      final repo = ref.read(stockRepositoryProvider);
      return repo.fetchBarcodeTotalsForRange(
        startDate: query.startDate,
        endDate: query.endDate,
      );
    });

final entriesForReportsProvider = FutureProvider.autoDispose
    .family<List<StockEntry>, ReportsQuery>((ref, query) async {
      final repo = ref.read(stockRepositoryProvider);
      return repo.fetchEntriesByDateRange(
        startDate: query.startDate,
        endDate: query.endDate,
      );
    });
