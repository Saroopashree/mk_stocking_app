class BarcodeTotal {
  const BarcodeTotal({required this.barcode, required this.totalQuantity});

  final String barcode;
  final int totalQuantity;

  static BarcodeTotal fromMap(Map<String, Object?> map) {
    return BarcodeTotal(
      barcode: map['barcode'] as String,
      totalQuantity: (map['totalQuantity'] as num).toInt(),
    );
  }
}
