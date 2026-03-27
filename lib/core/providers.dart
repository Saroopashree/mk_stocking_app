import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_entry_app/data/db/stock_database.dart';
import 'package:stock_entry_app/data/repositories/stock_repository_impl.dart';
import 'package:stock_entry_app/domain/repositories/stock_repository.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepositoryImpl(StockDatabase.instance.database);
});
