class StockEntry {
  const StockEntry({
    required this.id,
    required this.barcode,
    required this.quantity,
    required this.date,
  });

  final int id;
  final String barcode;
  final int quantity;
  final String date;

  StockEntry copyWith({int? id, String? barcode, int? quantity, String? date}) {
    return StockEntry(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    final map = <String, Object?>{
      'barcode': barcode,
      'quantity': quantity,
      'date': date,
    };

    if (includeId) {
      map['id'] = id;
    }
    return map;
  }

  static StockEntry fromMap(Map<String, Object?> map) {
    return StockEntry(
      id: (map['id'] as num).toInt(),
      barcode: map['barcode'] as String,
      quantity: (map['quantity'] as num).toInt(),
      date: map['date'] as String,
    );
  }
}
