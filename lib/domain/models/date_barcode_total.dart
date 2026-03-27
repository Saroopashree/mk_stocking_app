class DateBarcodeTotal {
  const DateBarcodeTotal({
    required this.date,
    required this.barcode,
    required this.totalQuantity,
  });

  final String date;
  final String barcode;
  final int totalQuantity;

  static DateBarcodeTotal fromMap(Map<String, Object?> map) {
    return DateBarcodeTotal(
      date: map['date'] as String,
      barcode: map['barcode'] as String,
      totalQuantity: (map['totalQuantity'] as num).toInt(),
    );
  }
}
