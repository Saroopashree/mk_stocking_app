import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stock_entry_app/domain/models/stock_entry.dart';
import 'package:stock_entry_app/features/stock_entry/ui/barcode_scanner_page.dart';

Future<StockEntry?> showEditEntryDialog(
  BuildContext context,
  StockEntry entry,
) {
  return showDialog(
    context: context,
    builder: (context) => EditEntryDialog(entry: entry),
  );
}

class EditEntryDialog extends StatefulWidget {
  const EditEntryDialog({super.key, required this.entry});

  final StockEntry entry;

  @override
  State<EditEntryDialog> createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends State<EditEntryDialog> {
  late final TextEditingController _barcodeController;
  late final TextEditingController _quantityController;
  late DateTime _selectedDate;

  String? _error;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.entry.barcode);
    _quantityController = TextEditingController(
      text: widget.entry.quantity.toString(),
    );
    _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.entry.date);
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickScanResult() async {
    final cameraStatus = await Permission.camera.request();
    if (!mounted) return;

    if (!cameraStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera permission is required to scan barcodes'),
        ),
      );
    }

    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (scanned == null) return;
    setState(() => _barcodeController.text = scanned);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _error = null;
    });
  }

  void _onSave() {
    final barcode = _barcodeController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim());

    if (barcode.isEmpty) {
      setState(() => _error = 'Barcode is required');
      return;
    }

    if (quantity == null) {
      setState(() => _error = 'Quantity must be valid integer');
    }

    final updated = widget.entry.copyWith(
      barcode: barcode,
      quantity: quantity,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return AlertDialog(
      title: Text('Edit entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode',
                suffixIcon: IconButton(
                  tooltip: 'Scan barcode',
                  onPressed: _pickScanResult,
                  icon: Icon(Icons.qr_code_scanner),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: 'Quantity'),
            ),
            SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateLabel),
                    Icon(Icons.calendar_month_outlined),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel'),
        ),
        FilledButton(onPressed: () => _onSave(), child: Text('Save')),
      ],
    );
  }
}
